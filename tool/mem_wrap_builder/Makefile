.PHONY: spram dpram clean verilator_test comp

# Test spram generation
spram:
	@mkdir -p work
	python mem_wrap_builder.py -t spram -d 1024 -w 32 -o work
	python mem_wrap_builder.py -t spram -d 2048 -w 64 -o work -p test
	@echo "SPRAM generation completed. Check work/ directory."

# Test dpram generation
dpram:
	@mkdir -p work
	python mem_wrap_builder.py -t dpram -d 512 -w 32 -o work
	python mem_wrap_builder.py -t dpram -d 1024 -w 64 -o work -p test
	@echo "DPRAM generation completed. Check work/ directory."

# Verilator syntax check
verilator_test: spram dpram
	@echo "Running Verilator syntax check for SPRAM..."
	@mkdir -p work/verilator_obj
	verilator --lint-only --timing -sv \
		-I../../ip/mem_model \
		work/spram_1024x32.sv \
		../../ip/mem_model/fcip_spram_model.sv \
		--top-module spram_1024x32 \
		-Wno-DECLFILENAME \
		-Wno-UNUSED +define+USE_CUST_MEM_MACRO
	@echo "SPRAM Verilator check passed!"
	@echo "Running Verilator syntax check for DPRAM..."
	verilator --lint-only --timing -sv \
		-I../../ip/mem_model \
		work/dpram_512x32.sv \
		../../ip/mem_model/fcip_dpram_model.sv \
		--top-module dpram_512x32 \
		-Wno-DECLFILENAME \
		-Wno-UNUSED
	@echo "DPRAM Verilator check passed!"

# Compile memory models with Verilator
comp:
	@echo "Compiling memory models with Verilator..."
	@mkdir -p work/verilator_obj
	verilator --lint-only --timing -sv \
		../../ip/mem_model/fcip_spram_model.sv \
		--top-module fcip_spram_model \
		-Wno-DECLFILENAME \
		-Wno-UNUSED \
		-Wno-UNOPTFLAT
	verilator --lint-only --timing -sv \
		../../ip/mem_model/fcip_dpram_model.sv \
		--top-module fcip_dpram_model \
		-Wno-DECLFILENAME \
		-Wno-UNUSED \
		-Wno-UNOPTFLAT
	@echo "Memory models compilation passed!"

# Clean generated files
clean:
	rm -rf work
	@echo "Cleaned work directory."
