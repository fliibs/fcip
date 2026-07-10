.PHONY: comp clean test_spram test_dpram

# Compiler settings - can be overridden via environment variables
# Example: make test_spram CXX=/usr/bin/g++-12 CC=/usr/bin/gcc-12
# Or export globally: export CC=/usr/bin/gcc-12; export CXX=/usr/bin/g++-12
CXX ?= $(shell which g++)
CC ?= $(shell which gcc)

# Verilator environment variables
VERILATOR_CXX ?= $(CXX)
VERILATOR_CC ?= $(CC)

# C++ standard flags
CXXFLAGS ?= -std=c++20

comp:
	@echo "Compiling memory models with Verilator..."
	@echo "Using CXX=$(CXX), CC=$(CC)"
	@mkdir -p work
	verilator --lint-only --timing -sv fcip_spram_model.sv --top-module fcip_spram_model -Wno-DECLFILENAME -Wno-UNUSED -Wno-UNOPTFLAT
	verilator --lint-only --timing -sv fcip_dpram_model.sv --top-module fcip_dpram_model -Wno-DECLFILENAME -Wno-UNUSED -Wno-UNOPTFLAT
	@echo "Memory models compilation passed!"

test_spram:
	@echo "Running simple SPRAM test with Verilator..."
	@echo "Using VERILATOR_CXX=$(VERILATOR_CXX), VERILATOR_CC=$(VERILATOR_CC)"
	@mkdir -p work/test_spram
	cd test && VERILATOR_CXX=$(VERILATOR_CXX) VERILATOR_CC=$(VERILATOR_CC) verilator -cc --exe --timing \
		-Wno-DECLFILENAME -Wno-WIDTHTRUNC -Wno-UNUSED \
		fcip_spram_simple_tb.sv \
		../fcip_spram_model.sv \
		--top-module fcip_spram_simple_tb \
		--Mdir ../work/test_spram \
		verilator_main_spram.cpp \
		-CFLAGS "$(CXXFLAGS)" && \
	cd ../work/test_spram && \
	make -f Vfcip_spram_simple_tb.mk CXX=$(CXX) CC=$(CC) && \
	./Vfcip_spram_simple_tb +SPRAM_HEX=$(CURDIR)/test/spram_init.hex

test_dpram:
	@echo "Running simple DPRAM test with Verilator..."
	@echo "Using VERILATOR_CXX=$(VERILATOR_CXX), VERILATOR_CC=$(VERILATOR_CC)"
	@mkdir -p work/test_dpram
	cd test && VERILATOR_CXX=$(VERILATOR_CXX) VERILATOR_CC=$(VERILATOR_CC) verilator -cc --exe --timing \
		-Wno-DECLFILENAME -Wno-WIDTHTRUNC -Wno-UNUSED \
		fcip_dpram_simple_tb.sv \
		../fcip_dpram_model.sv \
		--top-module fcip_dpram_simple_tb \
		--Mdir ../work/test_dpram \
		verilator_main_dpram.cpp \
		-CFLAGS "$(CXXFLAGS)" && \
	cd ../work/test_dpram && \
	make -f Vfcip_dpram_simple_tb.mk CXX=$(CXX) CC=$(CC) && \
	./Vfcip_dpram_simple_tb +DPRAM_HEX=$(CURDIR)/test/dpram_init.hex

clean:
	rm -rf work
	cd test && rm -rf simv* *.log DVEfiles
	@echo "Cleaned work directory."

