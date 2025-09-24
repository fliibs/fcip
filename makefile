RTL_COMPILE_OUTPUT 			= $(FCIP_DIR)/work/rtl_compile
CMN_FILELIST 				= $(FCIP_DIR)/vc/fcip.f
#VCS_INC 			= /tools/software/synopsys/vcs/T-2022.06/linux64/include
VCS_INC 			= /home/liuyunqi/software/vcs_2016/linux64/include

.PHONY: compile lint

compile:
	mkdir -p $(RTL_COMPILE_OUTPUT)
	cd $(RTL_COMPILE_OUTPUT) ;vcs -kdb -full64 -cpp g++-4.8 -cc gcc-4.8 -LDFLAGS -Wl,--no-as-needed -debug_access -sverilog -f $(CMN_FILELIST) -CFLAGS -DVCS +lint=PCWM +lint=TFIPC-L -l cmp.log -lca -timescale=1ns/1ps
