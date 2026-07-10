FILELIST = \
-f ${FCIP_DIR}/ip/async_fifo/vc/filelist.f 		\
-f ${FCIP_DIR}/ip/basic/vc/filelist.f 			\
-f ${FCIP_DIR}/ip/stdcell_wrap/vc/filelist.f	\
-f ${FCIP_DIR}/ip/arbiter/vc/filelist.f 		\
-f ${FCIP_DIR}/ip/regslice/vc/filelist.f 

comp:
	vcs -full64 -sverilog +v2k -timescale=1ns/1ps -debug_access+all +define+VCS $(FILELIST)

clean:
	rm -rf csrc simv* *.log DVEfiles
.PHONY: comp clean
