FILELIST = \
-f ${FCIP_DIR}/ip/memory/vc/filelist.f 				\
-f ${FCIP_DIR}/ip/stdcell_wrap/vc/filelist.f		\
-f ${FCIP_DIR}/ip/basic/vc/filelist.f				\
${FCIP_DIR}/ip/sync_fifo/rtl/fcip_sync_fifo_reg.sv

comp:
	vcs -full64 -sverilog +v2k -timescale=1ns/1ps -debug_access+all +define+VCS $(FILELIST)

clean:
	rm -rf csrc simv* *.log DVEfiles
.PHONY: comp clean
