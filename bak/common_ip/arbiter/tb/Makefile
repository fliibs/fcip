FILELIST  = ../vc/my_design.f
FSDB_FILE = tb_top.fsdb


vcs		:
		vcs 	\
		-f ${FILELIST} \
		-cpp g++-4.8 -cc gcc-4.8 -LDFLAGS -Wl,--no-as-needed \
		-fsdb -full64 -R +vc +v2k -sverilog -debug_all \
		| tee vcs.log
verdi 	:
		verdi -sv -f ${FILELIST} -ssf ${FSDB_FILE} -sswr novas.rc &
clean	:
		rm -rf *.log simv *.daidir csrc *.key DVEfiles *.vpd *.conf *.rc *.fsdb verdiLog


# initial begin 
#     $fsdbDumpfile("tb_top.fsdb");
#     $fsdbDumpvars(0,tb_top);
# end
