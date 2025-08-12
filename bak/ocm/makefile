RTL_COMPILE_OUTPUT 				= $(OCM_PATH)/work/rtl_compile
RTL_LINT_OUTPUT 				= $(OCM_PATH)/work/lint
SIM_FILELIST 					= $(OCM_PATH)/ocm_filelist.f

.PHONY: compile

compile:
	mkdir -p $(RTL_COMPILE_OUTPUT)
	cd $(RTL_COMPILE_OUTPUT) ;vcs -full64 -cpp g++-4.8 -cc gcc-4.8 -LDFLAGS -Wl,--no-as-needed -lca -kdb -debug_access -sverilog -f $(SIM_FILELIST) +lint=PCWM +lint=TFIPC-L +define+TOY_SIM -l compile.log  -timescale=1ns/1ps -fsdb
sim:
	cd $(RTL_COMPILE_OUTPUT) ;./simv -l sim.log
lint: 
	mkdir -p $(RTL_LINT_OUTPUT)
	cd $(RTL_LINT_OUTPUT) ;spyglass -tcl ../../setup.tcl 
verdi:
	cd $(RTL_COMPILE_OUTPUT) ;verdi -ssf top.fsdb -dbdir simv.daidir/
all:compile sim