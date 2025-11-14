import argparse
import math
import os
from jinja2 import Template

def generate_mem_verilog(mem_type, depth, width, output_dir, prefix):
    """
    Generates a SystemVerilog file for a memory based on a template.

    Args:
        mem_type (str): The type of memory ('spram' or 'dpram').
        depth (int): The depth of the memory.
        width (int): The width of the memory.
        output_dir (str): The directory to save the generated file.
        prefix (str): The prefix for the module and output filename.
    """
    if mem_type not in ['spram', 'dpram']:
        print(f"Error: Invalid memory type '{mem_type}'. Must be 'spram' or 'dpram'.")
        return

    script_dir = os.path.dirname(os.path.abspath(__file__))
    template_path = os.path.join(script_dir, f"{mem_type}_template.sv.tpl")
    if not os.path.exists(template_path):
        print(f"Error: Template file not found at '{template_path}'")
        return

    addr_width = math.ceil(math.log2(depth))
    if prefix:
        module_name = f"{prefix}_{mem_type}_{depth}x{width}"
        type_upper = f"{prefix.upper()}_{mem_type.upper()}_{depth}X{width}"
    else:
        module_name = f"{mem_type}_{depth}x{width}"
        type_upper = f"{mem_type.upper()}_{depth}X{width}"
    addr_range = f"[{addr_width - 1}:0]"
    data_range = f"[{width - 1}:0]"

    addr_range = f"[{addr_width - 1}:0]"
    data_range = f"[{width - 1}:0]"

    # Correct padding calculation based on template structure
    # Base lengths of the type part in the template, without padding variables
    len_logic_base = len("logic")
    len_addr_base = len("logic ") + len(addr_range) # "logic " has a space
    len_data_base = len("logic ") + len(data_range) # "logic " has a space

    # Find the max length among all type declarations
    max_len = max(len_logic_base, len_addr_base, len_data_base)

    # Calculate the padding required for each type to reach the max length
    paddings = {
        "logic": ' ' * (max_len - len_logic_base),
        "addr": ' ' * (max_len - len_addr_base),
        "data": ' ' * (max_len - len_data_base)
    }

    with open(template_path, 'r') as f:
        template_content = f.read()

    template = Template(template_content)
    
    # Generate argparse_key based on module_name
    argparse_key = f'"{module_name.upper()}"'
    
    render_context = {
        "prefix": prefix,
        "module_name": module_name,
        "addr_range": addr_range,
        "data_range": data_range,
        "addr_width": addr_width,
        "sram_width": width, # for compatibility with spram template
        "type_upper": type_upper,
        "argparse_key": argparse_key,
        "paddings": paddings
    }

    rendered_template = template.render(**render_context)

    file_name = f"{module_name}.sv"
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    file_path = os.path.join(output_dir, file_name)

    with open(file_path, "w") as f:
        f.write(rendered_template)

    print(f"Generated {file_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate Memory Wrap file.")
    parser.add_argument('-v', '--version', action='version', version='%(prog)s 1.0')
    parser.add_argument("-t", "--mem_type", type=str, required=True, choices=['spram', 'dpram'], help="Memory type")
    parser.add_argument("-d", "--depth", type=int, required=True, help="Memory depth")
    parser.add_argument("-w", "--width", type=int, required=True, help="Memory width")
    parser.add_argument("-o", "--output_dir", type=str, default=".", help="Output directory for the generated file")
    parser.add_argument("-p", "--prefix", type=str, default="", help="Prefix for the module and output filename, default is null")
    args = parser.parse_args()

    generate_mem_verilog(args.mem_type, args.depth, args.width, args.output_dir, args.prefix)
