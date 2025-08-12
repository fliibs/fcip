# Common IP

### Fifo

| name | function |
|------|----------|
|cmn_vrp_1p_fifo_reg      |FIFO constructed with registers          |
|cmn_vrp_xp_fifo_reg      |FIFO constructed with multi input multi output registers          |
|cmn_vrp_1p_fifo_2p_sram      |FIFO constructed with dual-port sram          |
|cmn_vrp_1p_fifo_1x_sp_sram      |FIFO constructed with one single-port sram          |
|cmn_vrp_1p_fifo_2x_sp_sram      |FIFO constructed with two single-port srams          |
|cmn_vrp_1p_fifo_reg_async      |Clock-domain-crossing FIFO constructed with registers          |


### Memory

| name | function |
|------|----------|
|cmn_vrp_1p_mem_reg      |single-port memory constructed with registers          |
|cmn_vrp_2p_mem_reg      |dual-port memory constructed with registers          |
|cmn_vrp_1p_mem_sp_sram      |single-port memory constructed with single-port sram          |
|cmn_vrp_2p_mem_2p_sram      |dual-port memory constructed with dual-port sram          |
|cmn_vrp_2p_mem_sp_sram      |dual-port memory constructed with two single-port srams          |
|cmn_vrp_2p_mem_sp_sram_hash      |dual-port memory constructed with two single-port srams hash         |

### Arbiter

| name | function |
|------|----------|
|cmn_arb_vrp      |instanced by parameter.0-fix,1-rr,2- |
|cmn_arb_vrp_fix      |fix Arbiter          |
<!-- |cmn_arb_vr_fix      |fix Arbiter |
|cmn_arb_vr_matrix      |matrix Arbiter          |
|cmn_arb_vr_ld1      |leading one Arbiter|
|cmn_arb_vr_rr      |round robin Arbiter|
|cmn_arb_vrp_matrix      |matrix Arbiter          |
|cmn_arb_vrp_ld1      |leading one Arbiter |
|cmn_arb_vrp_rr      |round robin Arbiter| -->

| name | function |
|------|----------|
|cmn_mtx_gen_plru_node      |plru update by input node         |
|cmn_mtx_gen_plru_tree      |plre tree update          |
|cmn_mtx_gen_plru_tree_comb      |plre tree update without register          |
|cmn_mtx_gen_age      |age matrix create          |
|cmn_mtx_gen_age_list      |age matrix update by vector alloc         |



### Others
| name | function |
|------|----------|
|cmn_bin2oh      |bin2onehot          |
|cmn_oh2bin      |onehot2bin         |
|cmn_onehot_mux      |onehot mux with pld          |
|cmn_reg_slice      |reg slice --parameter sel full/backward/forward          |
|cmn_lead_one      |leading one          |
|cmn_lead_x_list      |leading x          |
|cmn_rob_prealloc      |rob pre-alloc          |
|cmn_rob_id_dec      |rob decode          |
|cmn_cnt_ones      |calculate one count          |
|cmn_bin2thermal      |bin2thermal          |
|cmn_sign_ext      |sign extension          |
|cmn_xbar      |cross bar without arbitor         |
|cmn_fanout      |fan out          |
|cmn_merge      |merge          |