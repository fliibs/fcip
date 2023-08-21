# first source set_prj_dir_temp.sh in prj directory for environment variable
# then make run for simv
FL  = ../vc/axi_sramc_dv_top.f
FSDB = tb_top.fsdb


run:
	vcs -f ${FL} -cpp g++-4.8 -cc gcc-4.8 -LDFLAGS -Wl,--no-as-needed -fsdb -full64 -R +vc +v2k -sverilog -timescale=1ns/1ps -debug_all -l vcs.log
verdi:
	verdi -sv -f ${FL} -ssf ${FSDB} &
clean:
	rm -rf *.log simv *.daidir csrc *.key DVEfiles *.vpd *.conf *.rc *.fsdb verdiLog