FILELIST = ../vc/fcip_reg_slice.f

comp:
	vcs -full64 -sverilog +v2k -timescale=1ns/1ps -debug_access+all +define+VCS -f $(FILELIST) -LDFLAGS "-fno-lto -no-pie"

clean:
	rm -rf csrc simv* *.log DVEfiles
.PHONY: comp clean
