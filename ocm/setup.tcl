read_file -type sourcelist ../../ocm_filelist.f
set_option top ocm_top
current_goal Design_Read -top ocm_top
set_option enableSV09 yes
link_design -force