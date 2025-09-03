FILELIST = \
-f ${FCIP_DIR}/vc/fcip.f

comp:
	vcs -full64 -sverilog +v2k -timescale=1ns/1ps -debug_access+all +define+VCS $(FILELIST)

clean:
	rm -rf csrc simv* *.log DVEfiles
.PHONY: comp clean
