"""
APB5 Decoder Verilog Generator
Usage:
	python apb_decoder.py --range 128KB --slave 0KB-4KB --slave 4KB-8KB
Output:
	APB5 decoder verilog module, uncovered address returns deadbeef
"""

import argparse
import re

def parse_size(size_str):
	match = re.match(r'(\d+)(KB|MB)?', size_str.upper())
	if not match:
		raise ValueError(f"Invalid size: {size_str}")
	num = int(match.group(1))
	unit = match.group(2)
	if unit == 'KB':
		return num * 1024
	elif unit == 'MB':
		return num * 1024 * 1024
	else:
		return num

def parse_slave(slave_str):
	# e.g. s1-0KB-4KB
	parts = slave_str.split('-')
	if len(parts) < 3:
		raise ValueError(f"Invalid slave format: {slave_str}")
	prefix = parts[0]
	start = parts[1]
	end = parts[2]
	return prefix, parse_size(start), parse_size(end)

def gen_verilog(range_size, slaves, name_prefix, mod_decl=None, default_value='deadbeef'):
	module = []
	mod_name = mod_decl if mod_decl else (f"{name_prefix}_apb_decoder" if name_prefix else "apb_decoder")
	port_lines = []
	def addr_width(size):
		import math
		return max(1, (size-1).bit_length())
	in_addr_width = addr_width(range_size)
	# 主APB端口分组
	port_lines.append('    // Main APB interface')
	main_ports = [
		'input  logic         pclk',
		'input  logic         presetn',
		'input  logic         psel',
		'input  logic         penable',
		f'input  logic [{in_addr_width-1}:0]  paddr',
		'input  logic         pwrite',
		'input  logic [31:0]  pwdata',
		'output logic [31:0]  prdata',
		'output logic         pready',
		'output logic         pslverr'
	]
	for port in main_ports:
		port_lines.append(f'    {port},')
	# 每个slave APB端口分组
	for idx, (prefix, start, end) in enumerate(slaves):
		slave_width = addr_width(end-start)
		port_lines.append('')
		port_lines.append(f'    // Slave APB interface: {prefix}')
		slave_ports = [
			f'output logic         {prefix}_psel',
			f'output logic         {prefix}_penable',
			f'output logic [{slave_width-1}:0]  {prefix}_paddr',
			f'output logic         {prefix}_pwrite',
			f'output logic [31:0]  {prefix}_pwdata',
			f'input  logic [31:0]  {prefix}_prdata',
			f'input  logic         {prefix}_pready',
			f'input  logic         {prefix}_pslverr'
		]
		# 最后一个slave最后一个端口不加逗号
		for i, port in enumerate(slave_ports):
			if idx == len(slaves)-1 and i == len(slave_ports)-1:
				port_lines.append(f'    {port}')
			else:
				port_lines.append(f'    {port},')
	module.append(f'module {mod_name} (\n' + '\n'.join(port_lines) + '\n);\n')


	# Address decode分组
	module.append('    // Address decode for each slave')
	for idx, (prefix, start, end) in enumerate(slaves):
		slave_width = addr_width(end-start)
		module.append('')
		module.append(f'    // {prefix} address decode')
		eq_col = 28
		# 计算左侧长度用于对齐
		left_psel    = f'assign {prefix}_psel'
		left_penable = f'assign {prefix}_penable'
		left_paddr   = f'assign {prefix}_paddr'
		left_pwrite  = f'assign {prefix}_pwrite'
		left_pwdata  = f'assign {prefix}_pwdata'
		# 对齐格式
		module.append(f'    {left_psel.ljust(eq_col)} = psel && (paddr >= {in_addr_width}\'h{start:0{in_addr_width//4}x}) && (paddr < {in_addr_width}\'h{end:0{in_addr_width//4}x});')
		module.append(f'    {left_penable.ljust(eq_col)} = penable;')
		if start == 0:
			module.append(f'    {left_paddr.ljust(eq_col)} = paddr[{slave_width-1}:0];')
		else:
			module.append(f'    {left_paddr.ljust(eq_col)} = paddr - {in_addr_width}\'h{start:0{in_addr_width//4}x};')
		module.append(f'    {left_pwrite.ljust(eq_col)} = pwrite;')
		module.append(f'    {left_pwdata.ljust(eq_col)} = pwdata;')

	module.append('')
	module.append('    // APB response mux')
	module.append('    always @(*) begin')
	# 优先级判断，if-else链
	for idx, (prefix, start, end) in enumerate(slaves):
		if idx == 0:
			module.append(f'        if ({prefix}_psel) begin')
		else:
			module.append(f'        else if ({prefix}_psel) begin')
		module.append(f'            prdata  = {prefix}_prdata;')
		module.append(f'            pready  = {prefix}_pready;')
		module.append(f'            pslverr = {prefix}_pslverr;')
		module.append('        end')
	module.append('        else begin')
	module.append(f'            prdata  = 32\'h{default_value};')
	module.append('            pready  = 1;')
	module.append('            pslverr = 0;')
	module.append('        end')
	module.append('    end')

	module.append('endmodule')
	return '\n'.join(module)
def main():
	parser = argparse.ArgumentParser(description='APB5 Decoder Verilog Generator')
	parser.add_argument('-r', '--range', required=True, help='Total address range, e.g. 128KB')
	parser.add_argument('-s', '--slave', action='append', required=True, help='Slave address range, e.g. s1-0KB-4KB')
	parser.add_argument('-n', '--name', default='', help='Module name prefix')
	parser.add_argument('-p', '--prefix', action='store_true', help='Wrap module name with `_PREFIX_()` macro')
	parser.add_argument('-d', '--default-value', default='deadbeef', help='Default slave return value (hex, no 0x), default is deadbeef')
	args = parser.parse_args()

	range_size = parse_size(args.range)
	slaves = [parse_slave(s) for s in args.slave]

	# Check for overlap and out-of-range
	for i, (prefix, start, end) in enumerate(slaves):
		if start >= end or end > range_size:
			raise ValueError(f"Invalid slave range: {args.slave[i]}")
	# Overlap check
	sorted_slaves = sorted(slaves, key=lambda x: x[1])
	for i in range(1, len(sorted_slaves)):
		if sorted_slaves[i][1] < sorted_slaves[i-1][2]:
			raise ValueError("Slave address ranges overlap!")

	mod_name = f"{args.name}_apb_decoder" if args.name else "apb_decoder"
	if args.prefix:
		mod_decl = f'`_PREFIX_({mod_name})'
	else:
		mod_decl = mod_name
	verilog = gen_verilog(range_size, slaves, args.name, mod_decl, args.default_value)
	out_file = f"{mod_name}.v"
	with open(out_file, "w") as f:
		f.write(verilog)
	print(f"Verilog saved to {out_file}")

if __name__ == '__main__':
	main()
