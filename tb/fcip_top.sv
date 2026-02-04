//================================================================
// File: fcip_top.sv
// Description: Top level module instantiating all modules from:
//              - arbiter
//              - async_fifo  
//              - basic
//================================================================

module fcip_top #(
    parameter integer unsigned DOUBLE_DATA_WIRE = 1
)(
    input logic clk,
    input logic rst_n,
    
    // ============================================================
    // fcip_arb_matrix ports
    // ============================================================
    input  logic [3:0]   fcip_arb_matrix_vv_matrix [3:0],
    input  logic [3:0]   fcip_arb_matrix_v_vld,
    output logic [3:0]   fcip_arb_matrix_v_grant,
    
    // ============================================================
    // fcip_arb_vrp ports
    // ============================================================
    input  logic [3:0]   fcip_arb_vrp_v_vld_s,
    output logic [3:0]   fcip_arb_vrp_v_rdy_s,
    input  logic [31:0]  fcip_arb_vrp_v_pld_s [3:0],
    output logic         fcip_arb_vrp_vld_m,
    input  logic         fcip_arb_vrp_rdy_m,
    output logic [31:0]  fcip_arb_vrp_pld_m,
    
    // ============================================================
    // fcip_fix_arb ports
    // ============================================================
    input  logic         fcip_fix_arb_s_vld_priority,
    output logic         fcip_fix_arb_s_rdy_priority,
    input  logic [31:0]  fcip_fix_arb_s_pld_priority,
    input  logic         fcip_fix_arb_s_vld,
    output logic         fcip_fix_arb_s_rdy,
    input  logic [31:0]  fcip_fix_arb_s_pld,
    output logic         fcip_fix_arb_m_vld,
    input  logic         fcip_fix_arb_m_rdy,
    output logic [31:0]  fcip_fix_arb_m_pld,
    
    // ============================================================
    // fcip_grant_gen_fp ports
    // ============================================================
    input  logic [3:0]   fcip_grant_gen_fp_v_vld,
    input  logic [3:0]   fcip_grant_gen_fp_v_priority,
    output logic [3:0]   fcip_grant_gen_fp_v_grant,
    
    // ============================================================
    // fcip_grant_gen_rr ports
    // ============================================================
    input  logic [3:0]   fcip_grant_gen_rr_v_vld,
    output logic [3:0]   fcip_grant_gen_rr_v_grant,
    
    // ============================================================
    // fcip_mtx_gen_age ports
    // ============================================================
    input  logic         fcip_mtx_gen_age_alloc_en,
    input  logic [3:0]   fcip_mtx_gen_age_v_alloc,
    output logic [3:0]   fcip_mtx_gen_age_vv_matrix [3:0],
    
    // ============================================================
    // fcip_mtx_gen_plru_tree ports
    // ============================================================
    input  logic         fcip_mtx_gen_plru_tree_alloc_en,
    input  logic [3:0]   fcip_mtx_gen_plru_tree_v_alloc,
    output logic [3:0]   fcip_mtx_gen_plru_tree_vv_matrix [3:0],
    
    // ============================================================
    // fcip_afifo ports
    // ============================================================
    input  logic         fcip_afifo_wclk,
    input  logic         fcip_afifo_rclk,
    input  logic         fcip_afifo_wrst_n,
    input  logic         fcip_afifo_rrst_n,
    input  logic         fcip_afifo_read_stall,
    input  logic         fcip_afifo_write_stall,
    input  logic         fcip_afifo_read_clear,
    input  logic         fcip_afifo_write_clear,
    output logic         fcip_afifo_read_full_zero,
    output logic         fcip_afifo_write_full_zero,
    output logic         fcip_afifo_read_idle,
    input  logic         fcip_afifo_s_vld,
    input  logic [15:0]  fcip_afifo_s_pld,
    output logic         fcip_afifo_s_rdy,
    output logic         fcip_afifo_m_vld,
    output logic [15:0]  fcip_afifo_m_pld,
    input  logic         fcip_afifo_m_rdy,
    
    // ============================================================
    // fcip_afifo_mst ports
    // ============================================================
    input  logic         fcip_afifo_mst_stall,
    input  logic         fcip_afifo_mst_clear,
    output logic         fcip_afifo_mst_full_zero,
    output logic         fcip_afifo_mst_idle,
    output logic         fcip_afifo_mst_m_vld,
    output logic [15:0]  fcip_afifo_mst_m_pld,
    input  logic         fcip_afifo_mst_m_rdy,
    input  logic [15:0]  fcip_afifo_mst_wptr_async,
    output logic [15:0]  fcip_afifo_mst_rptr_async,
    output logic [15:0]  fcip_afifo_mst_rptr_sync,
    input  logic [16:0]  fcip_afifo_mst_pld_sync,
    
    // ============================================================
    // fcip_afifo_slv ports
    // ============================================================
    input  logic         fcip_afifo_slv_stall,
    input  logic         fcip_afifo_slv_clear,
    output logic         fcip_afifo_slv_full_zero,
    input  logic         fcip_afifo_slv_s_vld,
    input  logic [15:0]  fcip_afifo_slv_s_pld,
    output logic         fcip_afifo_slv_s_rdy,
    output logic [15:0]  fcip_afifo_slv_wptr_async,
    input  logic [15:0]  fcip_afifo_slv_rptr_async,
    input  logic [15:0]  fcip_afifo_slv_rptr_sync,
    output logic [16:0]  fcip_afifo_slv_pld_sync,
    
    // ============================================================
    // fcip_req_rsp_afifo ports
    // ============================================================
    input  logic         fcip_req_rsp_afifo_slv_req_s_vld,
    output logic         fcip_req_rsp_afifo_slv_req_s_rdy,
    input  logic [31:0]  fcip_req_rsp_afifo_slv_req_s_pld,
    input  logic         fcip_req_rsp_afifo_slv_req_s_last,
    output logic         fcip_req_rsp_afifo_slv_rsp_m_vld,
    input  logic         fcip_req_rsp_afifo_slv_rsp_m_rdy,
    output logic [31:0]  fcip_req_rsp_afifo_slv_rsp_m_pld,
    output logic         fcip_req_rsp_afifo_slv_rsp_m_last,
    output logic         fcip_req_rsp_afifo_mst_req_s_vld,
    input  logic         fcip_req_rsp_afifo_mst_req_s_rdy,
    output logic [31:0]  fcip_req_rsp_afifo_mst_req_s_pld,
    output logic         fcip_req_rsp_afifo_mst_req_s_last,
    input  logic         fcip_req_rsp_afifo_mst_rsp_m_vld,
    output logic         fcip_req_rsp_afifo_mst_rsp_m_rdy,
    input  logic [31:0]  fcip_req_rsp_afifo_mst_rsp_m_pld,
    input  logic         fcip_req_rsp_afifo_mst_rsp_m_last,
    
    // ============================================================
    // fcip_req_rsp_afifo_mst ports
    // ============================================================
    output logic         fcip_req_rsp_afifo_mst_req_s_vld_2,
    input  logic         fcip_req_rsp_afifo_mst_req_s_rdy_2,
    output logic [31:0]  fcip_req_rsp_afifo_mst_req_s_pld_2,
    output logic         fcip_req_rsp_afifo_mst_req_s_last_2,
    input  logic         fcip_req_rsp_afifo_mst_rsp_m_vld_2,
    output logic         fcip_req_rsp_afifo_mst_rsp_m_rdy_2,
    input  logic [31:0]  fcip_req_rsp_afifo_mst_rsp_m_pld_2,
    input  logic         fcip_req_rsp_afifo_mst_rsp_m_last_2,
    input  logic [15:0]  fcip_req_rsp_afifo_mst_req_wptr_async,
    output logic [15:0]  fcip_req_rsp_afifo_mst_req_rptr_async,
    output logic [15:0]  fcip_req_rsp_afifo_mst_req_rptr_sync,
    input  logic [33:0]  fcip_req_rsp_afifo_mst_req_pld_sync,
    output logic [15:0]  fcip_req_rsp_afifo_mst_rsp_wptr_async,
    input  logic [15:0]  fcip_req_rsp_afifo_mst_rsp_rptr_async,
    input  logic [15:0]  fcip_req_rsp_afifo_mst_rsp_rptr_sync,
    output logic [33:0]  fcip_req_rsp_afifo_mst_rsp_pld_sync,
    
    // ============================================================
    // fcip_req_rsp_afifo_slv ports
    // ============================================================
    input  logic         fcip_req_rsp_afifo_slv_req_s_vld_2,
    output logic         fcip_req_rsp_afifo_slv_req_s_rdy_2,
    input  logic [31:0]  fcip_req_rsp_afifo_slv_req_s_pld_2,
    input  logic         fcip_req_rsp_afifo_slv_req_s_last_2,
    output logic         fcip_req_rsp_afifo_slv_rsp_m_vld_2,
    input  logic         fcip_req_rsp_afifo_slv_rsp_m_rdy_2,
    output logic [31:0]  fcip_req_rsp_afifo_slv_rsp_m_pld_2,
    output logic         fcip_req_rsp_afifo_slv_rsp_m_last_2,
    output logic [15:0]  fcip_req_rsp_afifo_slv_req_wptr_async,
    input  logic [15:0]  fcip_req_rsp_afifo_slv_req_rptr_async,
    input  logic [15:0]  fcip_req_rsp_afifo_slv_req_rptr_sync,
    output logic [33:0]  fcip_req_rsp_afifo_slv_req_pld_sync,
    input  logic [15:0]  fcip_req_rsp_afifo_slv_rsp_wptr_async,
    output logic [15:0]  fcip_req_rsp_afifo_slv_rsp_rptr_async,
    output logic [15:0]  fcip_req_rsp_afifo_slv_rsp_rptr_sync,
    input  logic [33:0]  fcip_req_rsp_afifo_slv_rsp_pld_sync,
    
    // ============================================================
    // fcip_axi_afifo ports (complete AXI interface)
    // ============================================================
    input  logic         fcip_axi_afifo_clk_s,
    input  logic         fcip_axi_afifo_rst_s_n,
    input  logic         fcip_axi_afifo_clk_m,
    input  logic         fcip_axi_afifo_rst_m_n,
    input  logic         fcip_axi_afifo_axi_fifo_slv_stall,
    input  logic         fcip_axi_afifo_axi_fifo_slv_clear,
    output logic         fcip_axi_afifo_axi_fifo_slv_full_zero,
    // AW channel slave
    input  logic         fcip_axi_afifo_awvalid_s,
    output logic         fcip_axi_afifo_awready_s,
    input  logic [0:0]   fcip_axi_afifo_awuser_s,
    input  logic [7:0]   fcip_axi_afifo_awid_s,
    input  logic [31:0]  fcip_axi_afifo_awaddr_s,
    input  logic [3:0]   fcip_axi_afifo_awregion_s,
    input  logic [7:0]   fcip_axi_afifo_awlen_s,
    input  logic [2:0]   fcip_axi_afifo_awsize_s,
    input  logic [1:0]   fcip_axi_afifo_awburst_s,
    input  logic         fcip_axi_afifo_awlock_s,
    input  logic [3:0]   fcip_axi_afifo_awcache_s,
    input  logic [2:0]   fcip_axi_afifo_awprot_s,
    input  logic [3:0]   fcip_axi_afifo_awqos_s,
    // W channel slave
    input  logic         fcip_axi_afifo_wvalid_s,
    output logic         fcip_axi_afifo_wready_s,
    input  logic [0:0]   fcip_axi_afifo_wuser_s,
    input  logic [127:0] fcip_axi_afifo_wdata_s,
    input  logic [15:0]  fcip_axi_afifo_wstrb_s,
    input  logic         fcip_axi_afifo_wlast_s,
    // B channel slave
    output logic         fcip_axi_afifo_bvalid_s,
    input  logic         fcip_axi_afifo_bready_s,
    output logic [0:0]   fcip_axi_afifo_buser_s,
    output logic [7:0]   fcip_axi_afifo_bid_s,
    output logic [1:0]   fcip_axi_afifo_bresp_s,
    // AR channel slave
    input  logic         fcip_axi_afifo_arvalid_s,
    output logic         fcip_axi_afifo_arready_s,
    input  logic [0:0]   fcip_axi_afifo_aruser_s,
    input  logic [7:0]   fcip_axi_afifo_arid_s,
    input  logic [31:0]  fcip_axi_afifo_araddr_s,
    input  logic [3:0]   fcip_axi_afifo_arregion_s,
    input  logic [7:0]   fcip_axi_afifo_arlen_s,
    input  logic [2:0]   fcip_axi_afifo_arsize_s,
    input  logic [1:0]   fcip_axi_afifo_arburst_s,
    input  logic         fcip_axi_afifo_arlock_s,
    input  logic [3:0]   fcip_axi_afifo_arcache_s,
    input  logic [2:0]   fcip_axi_afifo_arprot_s,
    input  logic [3:0]   fcip_axi_afifo_arqos_s,
    // R channel slave
    output logic         fcip_axi_afifo_rvalid_s,
    input  logic         fcip_axi_afifo_rready_s,
    output logic [0:0]   fcip_axi_afifo_ruser_s,
    output logic [7:0]   fcip_axi_afifo_rid_s,
    output logic [127:0] fcip_axi_afifo_rdata_s,
    output logic [1:0]   fcip_axi_afifo_rresp_s,
    output logic         fcip_axi_afifo_rlast_s,
    // Master side
    input  logic         fcip_axi_afifo_axi_fifo_mst_stall,
    input  logic         fcip_axi_afifo_axi_fifo_mst_clear,
    output logic         fcip_axi_afifo_axi_fifo_mst_full_zero,
    // AW channel master
    output logic         fcip_axi_afifo_awvalid_m,
    input  logic         fcip_axi_afifo_awready_m,
    output logic [0:0]   fcip_axi_afifo_awuser_m,
    output logic [7:0]   fcip_axi_afifo_awid_m,
    output logic [31:0]  fcip_axi_afifo_awaddr_m,
    output logic [3:0]   fcip_axi_afifo_awregion_m,
    output logic [7:0]   fcip_axi_afifo_awlen_m,
    output logic [2:0]   fcip_axi_afifo_awsize_m,
    output logic [1:0]   fcip_axi_afifo_awburst_m,
    output logic         fcip_axi_afifo_awlock_m,
    output logic [3:0]   fcip_axi_afifo_awcache_m,
    output logic [2:0]   fcip_axi_afifo_awprot_m,
    output logic [3:0]   fcip_axi_afifo_awqos_m,
    // W channel master
    output logic         fcip_axi_afifo_wvalid_m,
    input  logic         fcip_axi_afifo_wready_m,
    output logic [0:0]   fcip_axi_afifo_wuser_m,
    output logic [127:0] fcip_axi_afifo_wdata_m,
    output logic [15:0]  fcip_axi_afifo_wstrb_m,
    output logic         fcip_axi_afifo_wlast_m,
    // B channel master
    input  logic         fcip_axi_afifo_bvalid_m,
    output logic         fcip_axi_afifo_bready_m,
    input  logic [0:0]   fcip_axi_afifo_buser_m,
    input  logic [7:0]   fcip_axi_afifo_bid_m,
    input  logic [1:0]   fcip_axi_afifo_bresp_m,
    // AR channel master
    output logic         fcip_axi_afifo_arvalid_m,
    input  logic         fcip_axi_afifo_arready_m,
    output logic [0:0]   fcip_axi_afifo_aruser_m,
    output logic [7:0]   fcip_axi_afifo_arid_m,
    output logic [31:0]  fcip_axi_afifo_araddr_m,
    output logic [3:0]   fcip_axi_afifo_arregion_m,
    output logic [7:0]   fcip_axi_afifo_arlen_m,
    output logic [2:0]   fcip_axi_afifo_arsize_m,
    output logic [1:0]   fcip_axi_afifo_arburst_m,
    output logic         fcip_axi_afifo_arlock_m,
    output logic [3:0]   fcip_axi_afifo_arcache_m,
    output logic [2:0]   fcip_axi_afifo_arprot_m,
    output logic [3:0]   fcip_axi_afifo_arqos_m,
    // R channel master
    input  logic         fcip_axi_afifo_rvalid_m,
    output logic         fcip_axi_afifo_rready_m,
    input  logic [0:0]   fcip_axi_afifo_ruser_m,
    input  logic [7:0]   fcip_axi_afifo_rid_m,
    input  logic [127:0] fcip_axi_afifo_rdata_m,
    input  logic [1:0]   fcip_axi_afifo_rresp_m,
    input  logic         fcip_axi_afifo_rlast_m,
    
    // ============================================================
    // fcip_bin2onehot ports
    // ============================================================
    input  logic [4:0]   fcip_bin2onehot_bin_in,
    output logic [31:0]  fcip_bin2onehot_onehot_out,
    
    // ============================================================
    // fcip_lead_one ports
    // ============================================================
    input  logic [15:0]  fcip_lead_one_v_entry_vld,
    output logic [15:0]  fcip_lead_one_v_free_idx_oh,
    output logic [3:0]   fcip_lead_one_v_free_idx_bin,
    output logic         fcip_lead_one_v_free_vld,
    
    // ============================================================
    // fcip_lead_one_msb ports
    // ============================================================
    input  logic [15:0]  fcip_lead_one_msb_v_entry_vld,
    output logic [15:0]  fcip_lead_one_msb_v_free_idx_oh,
    output logic [3:0]   fcip_lead_one_msb_v_free_idx_bin,
    output logic         fcip_lead_one_msb_v_free_vld,
    
    // ============================================================
    // fcip_lead_one_rev ports
    // ============================================================
    input  logic [15:0]  fcip_lead_one_rev_v_entry_vld,
    output logic [15:0]  fcip_lead_one_rev_v_free_idx_oh,
    output logic [3:0]   fcip_lead_one_rev_v_free_idx_bin,
    output logic         fcip_lead_one_rev_v_free_vld,
    
    // ============================================================
    // fcip_lfsr4 ports
    // ============================================================
    output logic [3:0]   fcip_lfsr4_out,
    
    // ============================================================
    // fcip_list_lead_one ports
    // ============================================================
    input  logic [15:0]  fcip_list_lead_one_v_entry_vld,
    output logic [15:0]  fcip_list_lead_one_v_free_idx_oh [3:0],
    output logic [3:0]   fcip_list_lead_one_v_free_idx_bin [3:0],
    output logic [3:0]   fcip_list_lead_one_v_free_vld,
    
    // ============================================================
    // fcip_list_lead_one_rev ports
    // ============================================================
    input  logic [15:0]  fcip_list_lead_one_rev_v_entry_vld,
    output logic [15:0]  fcip_list_lead_one_rev_v_free_idx_oh [3:0],
    output logic [3:0]   fcip_list_lead_one_rev_v_free_idx_bin [3:0],
    output logic [3:0]   fcip_list_lead_one_rev_v_free_vld,
    
    // ============================================================
    // fcip_onehot2bin ports
    // ============================================================
    input  logic [3:0]   fcip_onehot2bin_onehot_in,
    output logic [1:0]   fcip_onehot2bin_bin_out,
    
    // ============================================================
    // fcip_real_mux_onehot ports
    // ============================================================
    input  logic [3:0]   fcip_real_mux_onehot_select_onehot,
    input  logic [31:0]  fcip_real_mux_onehot_v_pld [3:0],
    output logic [31:0]  fcip_real_mux_onehot_select_pld,
    
    // ============================================================
    // fcip_rob_id_dec ports
    // ============================================================
    input  logic         fcip_rob_id_dec_in_en,
    input  logic [3:0]   fcip_rob_id_dec_in_index,
    output logic [15:0]  fcip_rob_id_dec_v_out_en,
    
    // ============================================================
    // fcip_rob_prealloc ports
    // ============================================================
    input  logic [31:0]  fcip_rob_prealloc_v_in_vld,
    output logic [31:0]  fcip_rob_prealloc_v_in_rdy,
    output logic         fcip_rob_prealloc_out_vld,
    input  logic         fcip_rob_prealloc_out_rdy,
    output logic [4:0]   fcip_rob_prealloc_out_pld,
    output logic [31:0]  fcip_rob_prealloc_out_pld_oh,
    // ============================================================
    // fcip_onehot_demux ports
    // ============================================================
    input  logic         fcip_onehot_demux_s_vld,
    output logic         fcip_onehot_demux_s_rdy,
    input  logic [31:0]  fcip_onehot_demux_s_pld,
    input  logic [3:0]   fcip_onehot_demux_sel_onehot,
    output logic [3:0]   fcip_onehot_demux_v_m_vld,
    input  logic [3:0]   fcip_onehot_demux_v_m_rdy,
    output logic [31:0]  fcip_onehot_demux_v_m_pld [3:0],
    // ============================================================
    // fcip_ip_mimo_queue ports
    // ============================================================
    output logic [3:0]   fcip_ip_mimo_queue_v_req_rdy,
    input  logic [3:0]   fcip_ip_mimo_queue_v_req_vld,
    input  logic [31:0]  fcip_ip_mimo_queue_v_req_pld [3:0],
    output logic [3:0]   fcip_ip_mimo_queue_v_ack_vld,
    input  logic [3:0]   fcip_ip_mimo_queue_v_ack_rdy,
    output logic [31:0]  fcip_ip_mimo_queue_v_ack_pld [3:0],
    
    // ============================================================
    // fcip_reg_slice ports
    // ============================================================
    input  logic         fcip_reg_slice_s_vld,
    output logic         fcip_reg_slice_s_rdy,
    input  logic [31:0]  fcip_reg_slice_s_pld,
    output logic         fcip_reg_slice_m_vld,
    input  logic         fcip_reg_slice_m_rdy,
    output logic [31:0]  fcip_reg_slice_m_pld,
    
    // ============================================================
    // fcip_marker ports
    // ============================================================
    input  logic [31:0]  fcip_marker_I,
    output logic [31:0]  fcip_marker_Z,
    
    // ============================================================
    // fcip_clk_marker ports
    // ============================================================
    input  logic         fcip_clk_marker_I,
    output logic         fcip_clk_marker_Z,
    
    // ============================================================
    // fcip_data_pipe ports
    // ============================================================
    input  logic [31:0]  fcip_data_pipe_d,
    output logic [31:0]  fcip_data_pipe_q,
    
    // ============================================================
    // fcip_sync_arst ports
    // ============================================================
    input  logic         fcip_sync_arst_D,
    input  logic         fcip_sync_arst_SI,
    input  logic         fcip_sync_arst_SE,
    input  logic         fcip_sync_arst_CP,
    input  logic         fcip_sync_arst_CDN,
    output logic         fcip_sync_arst_Q,
    
    // ============================================================
    // fcip_sync_aset ports
    // ============================================================
    input  logic         fcip_sync_aset_D,
    input  logic         fcip_sync_aset_SI,
    input  logic         fcip_sync_aset_SE,
    input  logic         fcip_sync_aset_CP,
    input  logic         fcip_sync_aset_SDN,
    output logic         fcip_sync_aset_Q,
    
    // ============================================================
    // fcip_sync_cell ports
    // ============================================================
    input  logic [31:0]  fcip_sync_cell_d,
    output logic [31:0]  fcip_sync_cell_q,
    
    // ============================================================
    // fcip_mem_ctrl_wrap ports
    // ============================================================
    input  logic         fcip_mem_ctrl_wrap_mem_req_vld,
    output logic         fcip_mem_ctrl_wrap_mem_req_rdy,
    input  logic         fcip_mem_ctrl_wrap_mem_req_opcode,
    input  logic [9:0]   fcip_mem_ctrl_wrap_mem_req_addr,
    input  logic [31:0]  fcip_mem_ctrl_wrap_mem_req_data,
    input  logic [31:0]  fcip_mem_ctrl_wrap_mem_req_bit_en,
    input  logic [0:0]   fcip_mem_ctrl_wrap_mem_req_sideband,
    output logic         fcip_mem_ctrl_wrap_mem_rsp_en,
    output logic [0:0]   fcip_mem_ctrl_wrap_mem_rsp_sideband,
    output logic [31:0]  fcip_mem_ctrl_wrap_mem_rsp_data,
    output logic [9:0]   fcip_mem_ctrl_wrap_spram_addr,
    output logic [31:0]  fcip_mem_ctrl_wrap_spram_din,
    input  logic [31:0]  fcip_mem_ctrl_wrap_spram_dout,
    output logic [31:0]  fcip_mem_ctrl_wrap_spram_bit_en,
    output logic         fcip_mem_ctrl_wrap_spram_en,
    output logic         fcip_mem_ctrl_wrap_spram_wren,
    
    // ============================================================
    // fcip_mem_fake_find_new_bit ports
    // ============================================================
    input  logic         fcip_mem_fake_find_new_bit_cmp_vld,
    input  logic [7:0]   fcip_mem_fake_find_new_bit_cmp_addr,
    input  logic [127:0] fcip_mem_fake_find_new_bit_cmp_array_data [15:0],
    input  logic [7:0]   fcip_mem_fake_find_new_bit_cmp_array_addr [15:0],
    input  logic [127:0] fcip_mem_fake_find_new_bit_cmp_array_bit_en [15:0],
    input  logic [15:0]  fcip_mem_fake_find_new_bit_array_vld,
    input  logic [5:0]   fcip_mem_fake_find_new_bit_wr_ptr,
    output logic         fcip_mem_fake_find_new_bit_cmp_hit,
    output logic [127:0] fcip_mem_fake_find_new_bit_cmp_hit_data,
    output logic [127:0] fcip_mem_fake_find_new_bit_cmp_hit_bit_en,
    
    // ============================================================
    // fcip_mem_fake_write_buffer ports
    // ============================================================
    input  logic         fcip_mem_fake_write_buffer_write_req_vld,
    input  logic [127:0] fcip_mem_fake_write_buffer_write_req_data,
    input  logic [7:0]   fcip_mem_fake_write_buffer_write_req_addr,
    output logic         fcip_mem_fake_write_buffer_write_req_rdy,
    input  logic [127:0] fcip_mem_fake_write_buffer_write_req_bit_en,
    output logic         fcip_mem_fake_write_buffer_buffer_full,
    output logic         fcip_mem_fake_write_buffer_buffer_empty,
    output logic         fcip_mem_fake_write_buffer_write_buffer_vld,
    input  logic         fcip_mem_fake_write_buffer_write_buffer_rdy,
    output logic [127:0] fcip_mem_fake_write_buffer_write_buffer_data,
    output logic [7:0]   fcip_mem_fake_write_buffer_write_buffer_addr,
    output logic [127:0] fcip_mem_fake_write_buffer_write_buffer_bit_en,
    input  logic         fcip_mem_fake_write_buffer_clear,
    input  logic         fcip_mem_fake_write_buffer_stall,
    input  logic         fcip_mem_fake_write_buffer_read_cmp_vld,
    input  logic [7:0]   fcip_mem_fake_write_buffer_read_cmp_addr,
    output logic         fcip_mem_fake_write_buffer_read_cmp_hit_delay,
    output logic [127:0] fcip_mem_fake_write_buffer_read_hit_data_delay,
    output logic [127:0] fcip_mem_fake_write_buffer_read_hit_data_bit_en_delay,
    
    // ============================================================
    // fcip_mem_fake_2p_mem ports
    // ============================================================
    input  logic         fcip_mem_fake_2p_mem_write_req_vld,
    input  logic [127:0] fcip_mem_fake_2p_mem_write_req_data,
    input  logic [9:0]   fcip_mem_fake_2p_mem_write_req_addr,
    output logic         fcip_mem_fake_2p_mem_write_req_rdy,
    input  logic [127:0] fcip_mem_fake_2p_mem_write_req_bit_en,
    input  logic         fcip_mem_fake_2p_mem_read_req_vld,
    input  logic [9:0]   fcip_mem_fake_2p_mem_read_req_addr,
    input  logic [0:0]   fcip_mem_fake_2p_mem_read_req_sideband,
    output logic         fcip_mem_fake_2p_mem_read_req_rdy,
    output logic         fcip_mem_fake_2p_mem_read_resp_vld,
    output logic [127:0] fcip_mem_fake_2p_mem_read_resp_data,
    output logic [0:0]   fcip_mem_fake_2p_mem_read_resp_sideband,
    input  logic         fcip_mem_fake_2p_mem_read_resp_rdy,
    output logic [9:0]   fcip_mem_fake_2p_mem_spram_addr,
    input  logic [127:0] fcip_mem_fake_2p_mem_spram_dout,
    output logic [127:0] fcip_mem_fake_2p_mem_spram_din,
    output logic         fcip_mem_fake_2p_mem_spram_en,
    output logic         fcip_mem_fake_2p_mem_spram_wren,
    output logic [127:0] fcip_mem_fake_2p_mem_spram_bit_en,
    input  logic         fcip_mem_fake_2p_mem_stall,
    input  logic         fcip_mem_fake_2p_mem_clear,
    output logic         fcip_mem_fake_2p_mem_idle,
    
    // ============================================================
    // fcip_sync_fifo_reg_mimo ports
    // ============================================================
    output logic [3:0]   fcip_sync_fifo_reg_mimo_v_s_rdy,
    input  logic [3:0]   fcip_sync_fifo_reg_mimo_v_s_vld,
    input  logic [31:0]  fcip_sync_fifo_reg_mimo_v_s_pld [3:0],
    output logic [3:0]   fcip_sync_fifo_reg_mimo_v_m_vld,
    input  logic [3:0]   fcip_sync_fifo_reg_mimo_v_m_rdy,
    output logic [31:0]  fcip_sync_fifo_reg_mimo_v_m_pld [3:0],
    
    // ============================================================
    // fcip_sfifo_spram_ctrl ports
    // ============================================================
    input  logic         fcip_sfifo_spram_ctrl_write_vld,
    input  logic [63:0]  fcip_sfifo_spram_ctrl_write_pld,
    output logic         fcip_sfifo_spram_ctrl_write_rdy,
    output logic         fcip_sfifo_spram_ctrl_sram_read_en,
    output logic [1:0]   fcip_sfifo_spram_ctrl_sram_read_sel,
    input  logic [0:0]   fcip_sfifo_spram_ctrl_sram_pre_alloc_id,
    output logic         fcip_sfifo_spram_ctrl_spram_ctrl_empty,
    output logic         fcip_sfifo_spram_ctrl_spram_ctrl_full,
    output logic         fcip_sfifo_spram_ctrl_spram_ctrl_almost_full,
    output logic         fcip_sfifo_spram_ctrl_spram_ctrl_almost_empty,
    input  logic         fcip_sfifo_spram_ctrl_rob_almost_empty,
    input  logic         fcip_sfifo_spram_ctrl_rob_almost_full,
    output logic [1:0]   fcip_sfifo_spram_ctrl_mem_req_vld,
    input  logic [1:0]   fcip_sfifo_spram_ctrl_mem_req_rdy,
    output logic [1:0]   fcip_sfifo_spram_ctrl_mem_req_opcode,
    output logic [5:0]   fcip_sfifo_spram_ctrl_mem_req_addr [1:0],
    output logic [63:0]  fcip_sfifo_spram_ctrl_mem_req_data [1:0],
    output logic [63:0]  fcip_sfifo_spram_ctrl_mem_req_bit_en [1:0],
    output logic [0:0]   fcip_sfifo_spram_ctrl_mem_req_sideband [1:0],
    
    // ============================================================
    // fcip_sfifo_spram_rob ports
    // ============================================================
    input  logic         fcip_sfifo_spram_rob_rob_req_vld,
    input  logic [63:0]  fcip_sfifo_spram_rob_rob_req_pld,
    output logic         fcip_sfifo_spram_rob_rob_req_rdy,
    input  logic         fcip_sfifo_spram_rob_ram_req_vld,
    input  logic [63:0]  fcip_sfifo_spram_rob_ram_req_pld,
    input  logic [4:0]   fcip_sfifo_spram_rob_ram_req_id,
    output logic         fcip_sfifo_spram_rob_ram_req_rdy,
    output logic         fcip_sfifo_spram_rob_read_vld,
    output logic [63:0]  fcip_sfifo_spram_rob_read_pld,
    input  logic         fcip_sfifo_spram_rob_read_rdy,
    output logic         fcip_sfifo_spram_rob_rob_empty,
    output logic         fcip_sfifo_spram_rob_rob_full,
    output logic         fcip_sfifo_spram_rob_rob_almost_empty,
    output logic         fcip_sfifo_spram_rob_rob_almost_full,
    input  logic         fcip_sfifo_spram_rob_sram_pre_winc,
    output logic [4:0]   fcip_sfifo_spram_rob_rob_prealloc_id,
    
    // ============================================================
    // fcip_sfifo_spram_ptr_ctrl ports
    // ============================================================
    input  logic         fcip_sfifo_spram_ptr_ctrl_write_vld,
    input  logic [63:0]  fcip_sfifo_spram_ptr_ctrl_write_pld,
    output logic         fcip_sfifo_spram_ptr_ctrl_write_rdy,
    input  logic         fcip_sfifo_spram_ptr_ctrl_read_vld,
    output logic         fcip_sfifo_spram_ptr_ctrl_read_rdy,
    input  logic [63:0]  fcip_sfifo_spram_ptr_ctrl_read_sideband,
    output logic         fcip_sfifo_spram_ptr_ctrl_ram_ctrl_empty,
    output logic         fcip_sfifo_spram_ptr_ctrl_ram_ctrl_full,
    output logic         fcip_sfifo_spram_ptr_ctrl_mem_req_vld,
    input  logic         fcip_sfifo_spram_ptr_ctrl_mem_req_rdy,
    output logic         fcip_sfifo_spram_ptr_ctrl_mem_req_opcode,
    output logic [5:0]   fcip_sfifo_spram_ptr_ctrl_mem_req_addr,
    output logic [63:0]  fcip_sfifo_spram_ptr_ctrl_mem_req_data,
    output logic [63:0]  fcip_sfifo_spram_ptr_ctrl_mem_req_bit_en,
    output logic [63:0]  fcip_sfifo_spram_ptr_ctrl_mem_req_sideband,
    
    // ============================================================
    // fcip_sync_fifo_spram ports
    // ============================================================
    input  logic         fcip_sync_fifo_spram_stall,
    input  logic         fcip_sync_fifo_spram_clear,
    output logic         fcip_sync_fifo_spram_idle,
    input  logic         fcip_sync_fifo_spram_write_req_vld,
    input  logic [15:0]  fcip_sync_fifo_spram_write_req_pld,
    output logic         fcip_sync_fifo_spram_write_req_rdy,
    output logic         fcip_sync_fifo_spram_read_resp_vld,
    output logic [15:0]  fcip_sync_fifo_spram_read_resp_pld,
    input  logic         fcip_sync_fifo_spram_read_resp_rdy,
    output logic         fcip_sync_fifo_spram_almost_full,
    output logic         fcip_sync_fifo_spram_almost_empty,
    output logic         fcip_sync_fifo_spram_empty,
    output logic         fcip_sync_fifo_spram_full,
    output logic [5:0]   fcip_sync_fifo_spram_spram_addr [1:0],
    output logic [15:0]  fcip_sync_fifo_spram_spram_din [1:0],
    input  logic [15:0]  fcip_sync_fifo_spram_spram_dout [1:0],
    output logic [1:0]   fcip_sync_fifo_spram_spram_en,
    output logic [1:0]   fcip_sync_fifo_spram_spram_wren,
    output logic [15:0]  fcip_sync_fifo_spram_spram_bit_en [1:0],

    // ============================================================
    // fcip_afifo_doub ports
    // ============================================================
    input  logic         fcip_afifo_doub_wclk,
    input  logic         fcip_afifo_doub_rclk,
    input  logic         fcip_afifo_doub_wrst_n,
    input  logic         fcip_afifo_doub_rrst_n,
    input  logic         fcip_afifo_doub_read_stall,
    input  logic         fcip_afifo_doub_write_stall,
    input  logic         fcip_afifo_doub_read_clear,
    input  logic         fcip_afifo_doub_write_clear,
    output logic         fcip_afifo_doub_read_full_zero,
    output logic         fcip_afifo_doub_write_full_zero,
    output logic         fcip_afifo_doub_read_idle,
    input  logic         fcip_afifo_doub_s_vld,
    input  logic [15:0]  fcip_afifo_doub_s_pld,
    output logic         fcip_afifo_doub_s_rdy,
    output logic         fcip_afifo_doub_m_vld,
    output logic [15:0]  fcip_afifo_doub_m_pld,
    input  logic         fcip_afifo_doub_m_rdy,
    
    // ============================================================
    // fcip_afifo_mst_doub ports
    // ============================================================
    input  logic         fcip_afifo_mst_doub_stall,
    input  logic         fcip_afifo_mst_doub_clear,
    output logic         fcip_afifo_mst_doub_full_zero,
    output logic         fcip_afifo_mst_doub_idle,
    output logic         fcip_afifo_mst_doub_m_vld,
    output logic [15:0]  fcip_afifo_mst_doub_m_pld,
    input  logic         fcip_afifo_mst_doub_m_rdy,
    input  logic [15:0]  fcip_afifo_mst_doub_wptr_async,
    output logic [15:0]  fcip_afifo_mst_doub_rptr_async,
    output logic [15:0]  fcip_afifo_mst_doub_rptr_sync,
    input  logic [(DOUBLE_DATA_WIRE? (16*2+1) : 16):0]  fcip_afifo_mst_doub_pld_sync,
    
    // ============================================================
    // fcip_afifo_slv_doub ports
    // ============================================================
    input  logic         fcip_afifo_slv_doub_stall,
    input  logic         fcip_afifo_slv_doub_clear,
    output logic         fcip_afifo_slv_doub_full_zero,
    input  logic         fcip_afifo_slv_doub_s_vld,
    input  logic [15:0]  fcip_afifo_slv_doub_s_pld,
    output logic         fcip_afifo_slv_doub_s_rdy,
    output logic [15:0]  fcip_afifo_slv_doub_wptr_async,
    input  logic [15:0]  fcip_afifo_slv_doub_rptr_async,
    input  logic [15:0]  fcip_afifo_slv_doub_rptr_sync,
    output logic [(DOUBLE_DATA_WIRE? (16*2+1) : 16):0]  fcip_afifo_slv_doub_pld_sync
);

// ============================================================
// Module Instantiations
// ============================================================

// fcip_arb_matrix instance
fcip_arb_matrix #(
    .WIDTH(4)
) u_fcip_arb_matrix (
    .vv_matrix  (fcip_arb_matrix_vv_matrix),
    .v_vld      (fcip_arb_matrix_v_vld),
    .v_grant    (fcip_arb_matrix_v_grant)
);

// fcip_arb_vrp instance
fcip_arb_vrp #(
    .MODE      (3),
    .HSK_MODE  (1),
    .WIDTH     (4),
    .PRIORITY  (4'b0000),
    .PLD_WIDTH (32)
) u_fcip_arb_vrp (
    .clk       (clk),
    .rst_n     (rst_n),
    .v_vld_s   (fcip_arb_vrp_v_vld_s),
    .v_rdy_s   (fcip_arb_vrp_v_rdy_s),
    .v_pld_s   (fcip_arb_vrp_v_pld_s),
    .vld_m     (fcip_arb_vrp_vld_m),
    .rdy_m     (fcip_arb_vrp_rdy_m),
    .pld_m     (fcip_arb_vrp_pld_m)
);

// fcip_fix_arb instance
fcip_fix_arb #(
    .PLD_TYPE(logic [31:0])
) u_fcip_fix_arb (
    .clk            (clk),
    .rst_n          (rst_n),
    .s_vld_priority (fcip_fix_arb_s_vld_priority),
    .s_rdy_priority (fcip_fix_arb_s_rdy_priority),
    .s_pld_priority (fcip_fix_arb_s_pld_priority),
    .s_vld          (fcip_fix_arb_s_vld),
    .s_rdy          (fcip_fix_arb_s_rdy),
    .s_pld          (fcip_fix_arb_s_pld),
    .m_vld          (fcip_fix_arb_m_vld),
    .m_rdy          (fcip_fix_arb_m_rdy),
    .m_pld          (fcip_fix_arb_m_pld)
);

// fcip_grant_gen_fp instance
fcip_grant_gen_fp #(
    .WIDTH(4)
) u_fcip_grant_gen_fp (
    .v_vld      (fcip_grant_gen_fp_v_vld),
    .v_priority (fcip_grant_gen_fp_v_priority),
    .v_grant    (fcip_grant_gen_fp_v_grant)
);

// fcip_grant_gen_rr instance
fcip_grant_gen_rr #(
    .WIDTH(4)
) u_fcip_grant_gen_rr (
    .clk     (clk),
    .rst_n   (rst_n),
    .v_vld   (fcip_grant_gen_rr_v_vld),
    .v_grant (fcip_grant_gen_rr_v_grant)
);

// fcip_mtx_gen_age instance
fcip_mtx_gen_age #(
    .WIDTH(4)
) u_fcip_mtx_gen_age (
    .clk       (clk),
    .rst_n     (rst_n),
    .alloc_en  (fcip_mtx_gen_age_alloc_en),
    .v_alloc   (fcip_mtx_gen_age_v_alloc),
    .vv_matrix (fcip_mtx_gen_age_vv_matrix)
);

// fcip_mtx_gen_plru_tree instance
fcip_mtx_gen_plru_tree #(
    .WIDTH(4)
) u_fcip_mtx_gen_plru_tree (
    .clk       (clk),
    .rst_n     (rst_n),
    .alloc_en  (fcip_mtx_gen_plru_tree_alloc_en),
    .v_alloc   (fcip_mtx_gen_plru_tree_v_alloc),
    .vv_matrix (fcip_mtx_gen_plru_tree_vv_matrix)
);

// fcip_afifo instance
fcip_afifo #(
    .FIFO_DEPTH             (16),
    .DATA_WIDTH             (16),
    .AUTO_CLEAR_EN          (0),
    .THRESHOLD_EN           (1),
    .ALMOST_EMPTY_THRESHOLD (4),
    .ALMOST_FULL_THRESHOLD  (12),
    .SYNC_STAGE             (2)
) u_fcip_afifo (
    .wclk           (fcip_afifo_wclk),
    .rclk           (fcip_afifo_rclk),
    .wrst_n         (fcip_afifo_wrst_n),
    .rrst_n         (fcip_afifo_rrst_n),
    .read_stall     (fcip_afifo_read_stall),
    .write_stall    (fcip_afifo_write_stall),
    .read_clear     (fcip_afifo_read_clear),
    .write_clear    (fcip_afifo_write_clear),
    .read_full_zero (fcip_afifo_read_full_zero),
    .write_full_zero(fcip_afifo_write_full_zero),
    .read_idle      (fcip_afifo_read_idle),
    .almost_empty   (),
    .almost_full    (),
    .s_vld          (fcip_afifo_s_vld),
    .s_pld          (fcip_afifo_s_pld),
    .s_rdy          (fcip_afifo_s_rdy),
    .m_vld          (fcip_afifo_m_vld),
    .m_pld          (fcip_afifo_m_pld),
    .m_rdy          (fcip_afifo_m_rdy)
);

// fcip_afifo_mst instance
fcip_afifo_mst #(
    .FIFO_DEPTH             (16),
    .DATA_WIDTH             (16),
    .AUTO_CLEAR_EN          (0),
    .THRESHOLD_EN           (1),
    .ALMOST_EMPTY_THRESHOLD (4),
    .SYNC_STAGE             (2)
) u_fcip_afifo_mst (
    .clk         (clk),
    .rst_n       (rst_n),
    .stall       (fcip_afifo_mst_stall),
    .clear       (fcip_afifo_mst_clear),
    .full_zero   (fcip_afifo_mst_full_zero),
    .idle        (fcip_afifo_mst_idle),
    .m_vld       (fcip_afifo_mst_m_vld),
    .m_pld       (fcip_afifo_mst_m_pld),
    .m_rdy       (fcip_afifo_mst_m_rdy),
    .almost_empty(),
    .wptr_async  (fcip_afifo_mst_wptr_async),
    .rptr_async  (fcip_afifo_mst_rptr_async),
    .rptr_sync   (fcip_afifo_mst_rptr_sync),
    .pld_sync    (fcip_afifo_mst_pld_sync)
);

// fcip_afifo_slv instance
fcip_afifo_slv #(
    .FIFO_DEPTH             (16),
    .DATA_WIDTH             (16),
    .AUTO_CLEAR_EN          (0),
    .THRESHOLD_EN           (1),
    .ALMOST_FULL_THRESHOLD  (12),
    .SYNC_STAGE             (2)
) u_fcip_afifo_slv (
    .clk        (clk),
    .rst_n      (rst_n),
    .stall      (fcip_afifo_slv_stall),
    .clear      (fcip_afifo_slv_clear),
    .full_zero  (fcip_afifo_slv_full_zero),
    .s_vld      (fcip_afifo_slv_s_vld),
    .s_pld      (fcip_afifo_slv_s_pld),
    .s_rdy      (fcip_afifo_slv_s_rdy),
    .almost_full(),
    .wptr_async (fcip_afifo_slv_wptr_async),
    .rptr_async (fcip_afifo_slv_rptr_async),
    .rptr_sync  (fcip_afifo_slv_rptr_sync),
    .pld_sync   (fcip_afifo_slv_pld_sync)
);

// fcip_req_rsp_afifo instance
fcip_req_rsp_afifo #(
    .SYNC_STAGE    (3),
    .FIFO_DEPTH    (16),
    .AUTO_CLEAR_EN (1),
    .REQ_WIDTH     (32),
    .RSP_WIDTH     (32)
) u_fcip_req_rsp_afifo (
    .clk                (clk),
    .rst_n              (rst_n),
    .slv_req_s_vld      (fcip_req_rsp_afifo_slv_req_s_vld),
    .slv_req_s_rdy      (fcip_req_rsp_afifo_slv_req_s_rdy),
    .slv_req_s_pld      (fcip_req_rsp_afifo_slv_req_s_pld),
    .slv_req_s_last     (fcip_req_rsp_afifo_slv_req_s_last),
    .slv_rsp_m_vld      (fcip_req_rsp_afifo_slv_rsp_m_vld),
    .slv_rsp_m_rdy      (fcip_req_rsp_afifo_slv_rsp_m_rdy),
    .slv_rsp_m_pld      (fcip_req_rsp_afifo_slv_rsp_m_pld),
    .slv_rsp_m_last     (fcip_req_rsp_afifo_slv_rsp_m_last),
    .mst_req_s_vld      (fcip_req_rsp_afifo_mst_req_s_vld),
    .mst_req_s_rdy      (fcip_req_rsp_afifo_mst_req_s_rdy),
    .mst_req_s_pld      (fcip_req_rsp_afifo_mst_req_s_pld),
    .mst_req_s_last     (fcip_req_rsp_afifo_mst_req_s_last),
    .mst_rsp_m_vld      (fcip_req_rsp_afifo_mst_rsp_m_vld),
    .mst_rsp_m_rdy      (fcip_req_rsp_afifo_mst_rsp_m_rdy),
    .mst_rsp_m_pld      (fcip_req_rsp_afifo_mst_rsp_m_pld),
    .mst_rsp_m_last     (fcip_req_rsp_afifo_mst_rsp_m_last)
);

// fcip_req_rsp_afifo_mst instance
fcip_req_rsp_afifo_mst #(
    .SYNC_STAGE    (3),
    .FIFO_DEPTH    (16),
    .AUTO_CLEAR_EN (1),
    .REQ_WIDTH     (32),
    .RSP_WIDTH     (32)
) u_fcip_req_rsp_afifo_mst (
    .clk            (clk),
    .rst_n          (rst_n),
    .req_s_vld      (fcip_req_rsp_afifo_mst_req_s_vld_2),
    .req_s_rdy      (fcip_req_rsp_afifo_mst_req_s_rdy_2),
    .req_s_pld      (fcip_req_rsp_afifo_mst_req_s_pld_2),
    .req_s_last     (fcip_req_rsp_afifo_mst_req_s_last_2),
    .rsp_m_vld      (fcip_req_rsp_afifo_mst_rsp_m_vld_2),
    .rsp_m_rdy      (fcip_req_rsp_afifo_mst_rsp_m_rdy_2),
    .rsp_m_pld      (fcip_req_rsp_afifo_mst_rsp_m_pld_2),
    .rsp_m_last     (fcip_req_rsp_afifo_mst_rsp_m_last_2),
    .req_wptr_async (fcip_req_rsp_afifo_mst_req_wptr_async),
    .req_rptr_async (fcip_req_rsp_afifo_mst_req_rptr_async),
    .req_rptr_sync  (fcip_req_rsp_afifo_mst_req_rptr_sync),
    .req_pld_sync   (fcip_req_rsp_afifo_mst_req_pld_sync),
    .rsp_wptr_async (fcip_req_rsp_afifo_mst_rsp_wptr_async),
    .rsp_rptr_async (fcip_req_rsp_afifo_mst_rsp_rptr_async),
    .rsp_rptr_sync  (fcip_req_rsp_afifo_mst_rsp_rptr_sync),
    .rsp_pld_sync   (fcip_req_rsp_afifo_mst_rsp_pld_sync)
);

// fcip_req_rsp_afifo_slv instance
fcip_req_rsp_afifo_slv #(
    .SYNC_STAGE    (3),
    .FIFO_DEPTH    (16),
    .AUTO_CLEAR_EN (1),
    .REQ_WIDTH     (32),
    .RSP_WIDTH     (32)
) u_fcip_req_rsp_afifo_slv (
    .clk            (clk),
    .rst_n          (rst_n),
    .req_s_vld      (fcip_req_rsp_afifo_slv_req_s_vld_2),
    .req_s_rdy      (fcip_req_rsp_afifo_slv_req_s_rdy_2),
    .req_s_pld      (fcip_req_rsp_afifo_slv_req_s_pld_2),
    .req_s_last     (fcip_req_rsp_afifo_slv_req_s_last_2),
    .rsp_m_vld      (fcip_req_rsp_afifo_slv_rsp_m_vld_2),
    .rsp_m_rdy      (fcip_req_rsp_afifo_slv_rsp_m_rdy_2),
    .rsp_m_pld      (fcip_req_rsp_afifo_slv_rsp_m_pld_2),
    .rsp_m_last     (fcip_req_rsp_afifo_slv_rsp_m_last_2),
    .req_wptr_async (fcip_req_rsp_afifo_slv_req_wptr_async),
    .req_rptr_async (fcip_req_rsp_afifo_slv_req_rptr_async),
    .req_rptr_sync  (fcip_req_rsp_afifo_slv_req_rptr_sync),
    .req_pld_sync   (fcip_req_rsp_afifo_slv_req_pld_sync),
    .rsp_wptr_async (fcip_req_rsp_afifo_slv_rsp_wptr_async),
    .rsp_rptr_async (fcip_req_rsp_afifo_slv_rsp_rptr_async),
    .rsp_rptr_sync  (fcip_req_rsp_afifo_slv_rsp_rptr_sync),
    .rsp_pld_sync   (fcip_req_rsp_afifo_slv_rsp_pld_sync)
);

// fcip_axi_afifo instance (simplified with default parameters)
fcip_axi_afifo #(
    .ADDR_WIDTH    (32),
    .DATA_WIDTH    (128),
    .AWID_WIDTH    (8),
    .ARID_WIDTH    (8),
    .AWLEN_WIDTH   (8),
    .ARLEN_WIDTH   (8),
    .AWUSER_WIDTH  (1),
    .WUSER_WIDTH   (1),
    .BUSER_WIDTH   (1),
    .ARUSER_WIDTH  (1),
    .RUSER_WIDTH   (1),
    .AW_FIFO_DEPTH (8),
    .W_FIFO_DEPTH  (8),
    .B_FIFO_DEPTH  (8),
    .AR_FIFO_DEPTH (8),
    .R_FIFO_DEPTH  (8),
    .SYNC_STAGE    (2),
    .AUTO_CLEAR_EN (1)
) u_fcip_axi_afifo (
    .clk_s                      (fcip_axi_afifo_clk_s),
    .rst_s_n                    (fcip_axi_afifo_rst_s_n),
    .clk_m                      (fcip_axi_afifo_clk_m),
    .rst_m_n                    (fcip_axi_afifo_rst_m_n),
    .axi_fifo_slv_stall         (fcip_axi_afifo_axi_fifo_slv_stall),
    .axi_fifo_slv_clear         (fcip_axi_afifo_axi_fifo_slv_clear),
    .axi_fifo_slv_full_zero     (fcip_axi_afifo_axi_fifo_slv_full_zero),
    .awvalid_s                  (fcip_axi_afifo_awvalid_s),
    .awready_s                  (fcip_axi_afifo_awready_s),
    .awuser_s                   (fcip_axi_afifo_awuser_s),
    .awid_s                     (fcip_axi_afifo_awid_s),
    .awaddr_s                   (fcip_axi_afifo_awaddr_s),
    .awregion_s                 (fcip_axi_afifo_awregion_s),
    .awlen_s                    (fcip_axi_afifo_awlen_s),
    .awsize_s                   (fcip_axi_afifo_awsize_s),
    .awburst_s                  (fcip_axi_afifo_awburst_s),
    .awlock_s                   (fcip_axi_afifo_awlock_s),
    .awcache_s                  (fcip_axi_afifo_awcache_s),
    .awprot_s                   (fcip_axi_afifo_awprot_s),
    .awqos_s                    (fcip_axi_afifo_awqos_s),
    .wvalid_s                   (fcip_axi_afifo_wvalid_s),
    .wready_s                   (fcip_axi_afifo_wready_s),
    .wuser_s                    (fcip_axi_afifo_wuser_s),
    .wdata_s                    (fcip_axi_afifo_wdata_s),
    .wstrb_s                    (fcip_axi_afifo_wstrb_s),
    .wlast_s                    (fcip_axi_afifo_wlast_s),
    .bvalid_s                   (fcip_axi_afifo_bvalid_s),
    .bready_s                   (fcip_axi_afifo_bready_s),
    .buser_s                    (fcip_axi_afifo_buser_s),
    .bid_s                      (fcip_axi_afifo_bid_s),
    .bresp_s                    (fcip_axi_afifo_bresp_s),
    .arvalid_s                  (fcip_axi_afifo_arvalid_s),
    .arready_s                  (fcip_axi_afifo_arready_s),
    .aruser_s                   (fcip_axi_afifo_aruser_s),
    .arid_s                     (fcip_axi_afifo_arid_s),
    .araddr_s                   (fcip_axi_afifo_araddr_s),
    .arregion_s                 (fcip_axi_afifo_arregion_s),
    .arlen_s                    (fcip_axi_afifo_arlen_s),
    .arsize_s                   (fcip_axi_afifo_arsize_s),
    .arburst_s                  (fcip_axi_afifo_arburst_s),
    .arlock_s                   (fcip_axi_afifo_arlock_s),
    .arcache_s                  (fcip_axi_afifo_arcache_s),
    .arprot_s                   (fcip_axi_afifo_arprot_s),
    .arqos_s                    (fcip_axi_afifo_arqos_s),
    .rvalid_s                   (fcip_axi_afifo_rvalid_s),
    .rready_s                   (fcip_axi_afifo_rready_s),
    .ruser_s                    (fcip_axi_afifo_ruser_s),
    .rid_s                      (fcip_axi_afifo_rid_s),
    .rdata_s                    (fcip_axi_afifo_rdata_s),
    .rresp_s                    (fcip_axi_afifo_rresp_s),
    .rlast_s                    (fcip_axi_afifo_rlast_s),
    .axi_fifo_mst_stall         (fcip_axi_afifo_axi_fifo_mst_stall),
    .axi_fifo_mst_clear         (fcip_axi_afifo_axi_fifo_mst_clear),
    .axi_fifo_mst_full_zero     (fcip_axi_afifo_axi_fifo_mst_full_zero),
    .awvalid_m                  (fcip_axi_afifo_awvalid_m),
    .awready_m                  (fcip_axi_afifo_awready_m),
    .awuser_m                   (fcip_axi_afifo_awuser_m),
    .awid_m                     (fcip_axi_afifo_awid_m),
    .awaddr_m                   (fcip_axi_afifo_awaddr_m),
    .awregion_m                 (fcip_axi_afifo_awregion_m),
    .awlen_m                    (fcip_axi_afifo_awlen_m),
    .awsize_m                   (fcip_axi_afifo_awsize_m),
    .awburst_m                  (fcip_axi_afifo_awburst_m),
    .awlock_m                   (fcip_axi_afifo_awlock_m),
    .awcache_m                  (fcip_axi_afifo_awcache_m),
    .awprot_m                   (fcip_axi_afifo_awprot_m),
    .awqos_m                    (fcip_axi_afifo_awqos_m),
    .wvalid_m                   (fcip_axi_afifo_wvalid_m),
    .wready_m                   (fcip_axi_afifo_wready_m),
    .wuser_m                    (fcip_axi_afifo_wuser_m),
    .wdata_m                    (fcip_axi_afifo_wdata_m),
    .wstrb_m                    (fcip_axi_afifo_wstrb_m),
    .wlast_m                    (fcip_axi_afifo_wlast_m),
    .bvalid_m                   (fcip_axi_afifo_bvalid_m),
    .bready_m                   (fcip_axi_afifo_bready_m),
    .buser_m                    (fcip_axi_afifo_buser_m),
    .bid_m                      (fcip_axi_afifo_bid_m),
    .bresp_m                    (fcip_axi_afifo_bresp_m),
    .arvalid_m                  (fcip_axi_afifo_arvalid_m),
    .arready_m                  (fcip_axi_afifo_arready_m),
    .aruser_m                   (fcip_axi_afifo_aruser_m),
    .arid_m                     (fcip_axi_afifo_arid_m),
    .araddr_m                   (fcip_axi_afifo_araddr_m),
    .arregion_m                 (fcip_axi_afifo_arregion_m),
    .arlen_m                    (fcip_axi_afifo_arlen_m),
    .arsize_m                   (fcip_axi_afifo_arsize_m),
    .arburst_m                  (fcip_axi_afifo_arburst_m),
    .arlock_m                   (fcip_axi_afifo_arlock_m),
    .arcache_m                  (fcip_axi_afifo_arcache_m),
    .arprot_m                   (fcip_axi_afifo_arprot_m),
    .arqos_m                    (fcip_axi_afifo_arqos_m),
    .rvalid_m                   (fcip_axi_afifo_rvalid_m),
    .rready_m                   (fcip_axi_afifo_rready_m),
    .ruser_m                    (fcip_axi_afifo_ruser_m),
    .rid_m                      (fcip_axi_afifo_rid_m),
    .rdata_m                    (fcip_axi_afifo_rdata_m),
    .rresp_m                    (fcip_axi_afifo_rresp_m),
    .rlast_m                    (fcip_axi_afifo_rlast_m)
);

// fcip_bin2onehot instance
fcip_bin2onehot #(
    .BIN_WIDTH(5)
) u_fcip_bin2onehot (
    .bin_in     (fcip_bin2onehot_bin_in),
    .onehot_out (fcip_bin2onehot_onehot_out)
);

// fcip_lead_one instance
fcip_lead_one #(
    .ENTRY_NUM(16)
) u_fcip_lead_one (
    .v_entry_vld    (fcip_lead_one_v_entry_vld),
    .v_free_idx_oh  (fcip_lead_one_v_free_idx_oh),
    .v_free_idx_bin (fcip_lead_one_v_free_idx_bin),
    .v_free_vld     (fcip_lead_one_v_free_vld)
);

// fcip_lead_one_msb instance
fcip_lead_one_msb #(
    .ENTRY_NUM(16)
) u_fcip_lead_one_msb (
    .v_entry_vld    (fcip_lead_one_msb_v_entry_vld),
    .v_free_idx_oh  (fcip_lead_one_msb_v_free_idx_oh),
    .v_free_idx_bin (fcip_lead_one_msb_v_free_idx_bin),
    .v_free_vld     (fcip_lead_one_msb_v_free_vld)
);

// fcip_lead_one_rev instance
fcip_lead_one_rev #(
    .ENTRY_NUM(16)
) u_fcip_lead_one_rev (
    .v_entry_vld    (fcip_lead_one_rev_v_entry_vld),
    .v_free_idx_oh  (fcip_lead_one_rev_v_free_idx_oh),
    .v_free_idx_bin (fcip_lead_one_rev_v_free_idx_bin),
    .v_free_vld     (fcip_lead_one_rev_v_free_vld)
);

// fcip_lfsr4 instance
fcip_lfsr4 u_fcip_lfsr4 (
    .clk   (clk),
    .rst_n (rst_n),
    .out   (fcip_lfsr4_out)
);

// fcip_list_lead_one instance
fcip_list_lead_one #(
    .ENTRY_NUM(16),
    .REQ_NUM  (4)
) u_fcip_list_lead_one (
    .v_entry_vld    (fcip_list_lead_one_v_entry_vld),
    .v_free_idx_oh  (fcip_list_lead_one_v_free_idx_oh),
    .v_free_idx_bin (fcip_list_lead_one_v_free_idx_bin),
    .v_free_vld     (fcip_list_lead_one_v_free_vld)
);

// fcip_list_lead_one_rev instance
fcip_list_lead_one_rev #(
    .ENTRY_NUM(16),
    .REQ_NUM  (4)
) u_fcip_list_lead_one_rev (
    .v_entry_vld    (fcip_list_lead_one_rev_v_entry_vld),
    .v_free_idx_oh  (fcip_list_lead_one_rev_v_free_idx_oh),
    .v_free_idx_bin (fcip_list_lead_one_rev_v_free_idx_bin),
    .v_free_vld     (fcip_list_lead_one_rev_v_free_vld)
);

// fcip_onehot2bin instance
fcip_onehot2bin #(
    .ONEHOT_WIDTH(4)
) u_fcip_onehot2bin (
    .onehot_in (fcip_onehot2bin_onehot_in),
    .bin_out   (fcip_onehot2bin_bin_out)
);

// fcip_real_mux_onehot instance
fcip_real_mux_onehot #(
    .WIDTH     (4),
    .PLD_WIDTH (32)
) u_fcip_real_mux_onehot (
    .select_onehot (fcip_real_mux_onehot_select_onehot),
    .v_pld         (fcip_real_mux_onehot_v_pld),
    .select_pld    (fcip_real_mux_onehot_select_pld)
);

// fcip_rob_id_dec instance
fcip_rob_id_dec #(
    .BIN_WIDTH(4)
) u_fcip_rob_id_dec (
    .in_en    (fcip_rob_id_dec_in_en),
    .in_index (fcip_rob_id_dec_in_index),
    .v_out_en (fcip_rob_id_dec_v_out_en)
);

// fcip_rob_prealloc instance
fcip_rob_prealloc #(
    .ROB_ENTRY_NUM(32)
) u_fcip_rob_prealloc (
    .v_in_vld  (fcip_rob_prealloc_v_in_vld),
    .v_in_rdy  (fcip_rob_prealloc_v_in_rdy),
    .out_vld   (fcip_rob_prealloc_out_vld),
    .out_rdy   (fcip_rob_prealloc_out_rdy),
    .out_pld   (fcip_rob_prealloc_out_pld),
    .out_pld_oh(fcip_rob_prealloc_out_pld_oh)
);
    // fcip_onehot_demux instance
    fcip_onehot_demux #(
        .WIDTH    (4),
        .PLD_TYPE (logic [31:0])
    ) u_fcip_onehot_demux (
        .s_vld      (fcip_onehot_demux_s_vld),
        .s_rdy      (fcip_onehot_demux_s_rdy),
        .s_pld      (fcip_onehot_demux_s_pld),
        .sel_onehot (fcip_onehot_demux_sel_onehot),
        .v_m_vld    (fcip_onehot_demux_v_m_vld),
        .v_m_rdy    (fcip_onehot_demux_v_m_rdy),
        .v_m_pld    (fcip_onehot_demux_v_m_pld)
    );
// fcip_ip_mimo_queue instance
fcip_ip_mimo_queue #(
    .DEPTH    (128),
    .WR_WIDTH (4),
    .RD_WIDTH (4),
    .PLD_TYPE (logic [31:0])
) u_fcip_ip_mimo_queue (
    .clk       (clk),
    .rst_n     (rst_n),
    .v_req_rdy (fcip_ip_mimo_queue_v_req_rdy),
    .v_req_vld (fcip_ip_mimo_queue_v_req_vld),
    .v_req_pld (fcip_ip_mimo_queue_v_req_pld),
    .v_ack_vld (fcip_ip_mimo_queue_v_ack_vld),
    .v_ack_rdy (fcip_ip_mimo_queue_v_ack_rdy),
    .v_ack_pld (fcip_ip_mimo_queue_v_ack_pld)
);

// fcip_reg_slice instance
fcip_reg_slice #(
    .PLD_TYPE(logic [31:0]),
    .RS_TYPE (0)
) u_fcip_reg_slice (
    .clk   (clk),
    .rst_n (rst_n),
    .s_vld (fcip_reg_slice_s_vld),
    .s_rdy (fcip_reg_slice_s_rdy),
    .s_pld (fcip_reg_slice_s_pld),
    .m_vld (fcip_reg_slice_m_vld),
    .m_rdy (fcip_reg_slice_m_rdy),
    .m_pld (fcip_reg_slice_m_pld)
);

// fcip_marker instance
fcip_marker #(
    .DATA_WIDTH(32),
    .VT_TYPE   ("LVT")
) u_fcip_marker (
    .I (fcip_marker_I),
    .Z (fcip_marker_Z)
);

// fcip_clk_marker instance
fcip_clk_marker #(
    .VT_TYPE("LVT")
) u_fcip_clk_marker (
    .I (fcip_clk_marker_I),
    .Z (fcip_clk_marker_Z)
);

// fcip_data_pipe instance
fcip_data_pipe #(
    .DATA_WIDTH(32),
    .PIPE_STAGE(2),
    .VT_TYPE   (0)
) u_fcip_data_pipe (
    .clk   (clk),
    .rst_n (rst_n),
    .d     (fcip_data_pipe_d),
    .q     (fcip_data_pipe_q)
);

// fcip_sync_arst instance
fcip_sync_arst #(
    .SYN_NUM(2),
    .VT_TYPE(0)
) u_fcip_sync_arst (
    .D   (fcip_sync_arst_D),
    .SI  (fcip_sync_arst_SI),
    .SE  (fcip_sync_arst_SE),
    .CP  (fcip_sync_arst_CP),
    .CDN (fcip_sync_arst_CDN),
    .Q   (fcip_sync_arst_Q)
);

// fcip_sync_aset instance
fcip_sync_aset #(
    .SYN_NUM(2),
    .VT_TYPE(0)
) u_fcip_sync_aset (
    .D   (fcip_sync_aset_D),
    .SI  (fcip_sync_aset_SI),
    .SE  (fcip_sync_aset_SE),
    .CP  (fcip_sync_aset_CP),
    .SDN (fcip_sync_aset_SDN),
    .Q   (fcip_sync_aset_Q)
);

// fcip_sync_cell instance
fcip_sync_cell #(
    .DATA_WIDTH(32),
    .SYN_STAGE (2),
    .VT_TYPE   (0),
    .RST_VALUE (32'h0)
) u_fcip_sync_cell (
    .clk   (clk),
    .rst_n (rst_n),
    .d     (fcip_sync_cell_d),
    .q     (fcip_sync_cell_q)
);

// fcip_mem_ctrl_wrap instance
fcip_mem_ctrl_wrap #(
    .SRAM_ACCESS_LATENCY(1),
    .SRAM_REQ_PIPE_STAGE(0),
    .SRAM_RSP_PIPE_STAGE(0),
    .SIDEBAND_WIDTH     (1),
    .DATA_WIDTH         (32),
    .ADDR_WIDTH         (10),
    .MCP_CYCLE          (1)
) u_fcip_mem_ctrl_wrap (
    .clk            (clk),
    .rst_n          (rst_n),
    .mem_req_vld    (fcip_mem_ctrl_wrap_mem_req_vld),
    .mem_req_rdy    (fcip_mem_ctrl_wrap_mem_req_rdy),
    .mem_req_opcode (fcip_mem_ctrl_wrap_mem_req_opcode),
    .mem_req_addr   (fcip_mem_ctrl_wrap_mem_req_addr),
    .mem_req_data   (fcip_mem_ctrl_wrap_mem_req_data),
    .mem_req_bit_en (fcip_mem_ctrl_wrap_mem_req_bit_en),
    .mem_req_sideband(fcip_mem_ctrl_wrap_mem_req_sideband),
    .mem_rsp_en     (fcip_mem_ctrl_wrap_mem_rsp_en),
    .mem_rsp_sideband(fcip_mem_ctrl_wrap_mem_rsp_sideband),
    .mem_rsp_data   (fcip_mem_ctrl_wrap_mem_rsp_data),
    .spram_addr     (fcip_mem_ctrl_wrap_spram_addr),
    .spram_din      (fcip_mem_ctrl_wrap_spram_din),
    .spram_dout     (fcip_mem_ctrl_wrap_spram_dout),
    .spram_bit_en   (fcip_mem_ctrl_wrap_spram_bit_en),
    .spram_en       (fcip_mem_ctrl_wrap_spram_en),
    .spram_wren     (fcip_mem_ctrl_wrap_spram_wren)
);

// fcip_mem_fake_find_new_bit instance
fcip_mem_fake_find_new_bit #(
    .ADDR_WIDTH        (8),
    .DATA_WIDTH        (128),
    .WRITE_BUFFER_SIZE (16),
    .PTR_WIDTH         (6)
) u_fcip_mem_fake_find_new_bit (
    .cmp_vld          (fcip_mem_fake_find_new_bit_cmp_vld),
    .cmp_addr         (fcip_mem_fake_find_new_bit_cmp_addr),
    .cmp_array_data   (fcip_mem_fake_find_new_bit_cmp_array_data),
    .cmp_array_addr   (fcip_mem_fake_find_new_bit_cmp_array_addr),
    .cmp_array_bit_en (fcip_mem_fake_find_new_bit_cmp_array_bit_en),
    .array_vld        (fcip_mem_fake_find_new_bit_array_vld),
    .wr_ptr           (fcip_mem_fake_find_new_bit_wr_ptr),
    .cmp_hit          (fcip_mem_fake_find_new_bit_cmp_hit),
    .cmp_hit_data     (fcip_mem_fake_find_new_bit_cmp_hit_data),
    .cmp_hit_bit_en   (fcip_mem_fake_find_new_bit_cmp_hit_bit_en)
);

// fcip_mem_fake_write_buffer instance
fcip_mem_fake_write_buffer #(
    .ADDR_WIDTH        (8),
    .DATA_WIDTH        (128),
    .WRITE_BUFFER_SIZE (16),
    .MEM_LATENCY       (1),
    .WRITE_BIT_MASK_EN (1)
) u_fcip_mem_fake_write_buffer (
    .clk                          (clk),
    .rst_n                        (rst_n),
    .write_req_vld                (fcip_mem_fake_write_buffer_write_req_vld),
    .write_req_data               (fcip_mem_fake_write_buffer_write_req_data),
    .write_req_addr               (fcip_mem_fake_write_buffer_write_req_addr),
    .write_req_rdy                (fcip_mem_fake_write_buffer_write_req_rdy),
    .write_req_bit_en             (fcip_mem_fake_write_buffer_write_req_bit_en),
    .buffer_full                  (fcip_mem_fake_write_buffer_buffer_full),
    .buffer_empty                 (fcip_mem_fake_write_buffer_buffer_empty),
    .write_buffer_vld             (fcip_mem_fake_write_buffer_write_buffer_vld),
    .write_buffer_rdy             (fcip_mem_fake_write_buffer_write_buffer_rdy),
    .write_buffer_data            (fcip_mem_fake_write_buffer_write_buffer_data),
    .write_buffer_addr            (fcip_mem_fake_write_buffer_write_buffer_addr),
    .write_buffer_bit_en          (fcip_mem_fake_write_buffer_write_buffer_bit_en),
    .clear                        (fcip_mem_fake_write_buffer_clear),
    .stall                        (fcip_mem_fake_write_buffer_stall),
    .read_cmp_vld                 (fcip_mem_fake_write_buffer_read_cmp_vld),
    .read_cmp_addr                (fcip_mem_fake_write_buffer_read_cmp_addr),
    .read_cmp_hit_delay           (fcip_mem_fake_write_buffer_read_cmp_hit_delay),
    .read_hit_data_delay          (fcip_mem_fake_write_buffer_read_hit_data_delay),
    .read_hit_data_bit_en_delay   (fcip_mem_fake_write_buffer_read_hit_data_bit_en_delay)
);

// fcip_mem_fake_2p_mem instance
fcip_mem_fake_2p_mem #(
    .SRAM_ACCESS_LATENCY(1),
    .SRAM_REQ_PIPE_STAGE(0),
    .SRAM_RSP_PIPE_STAGE(0),
    .SIDEBAND_WIDTH     (1),
    .DATA_WIDTH         (128),
    .ADDR_WIDTH         (10),
    .MCP_CYCLE          (1),
    .WRITE_BUFFER_SIZE  (4),
    .RW_ARBITER_TYPE    (0),
    .READ_FORWARD_EN    (1),
    .READ_BUFFER_SIZE   (4),
    .WRITE_BIT_MASK_EN  (1)
) u_fcip_mem_fake_2p_mem (
    .clk                (clk),
    .rst_n              (rst_n),
    .write_req_vld      (fcip_mem_fake_2p_mem_write_req_vld),
    .write_req_data     (fcip_mem_fake_2p_mem_write_req_data),
    .write_req_addr     (fcip_mem_fake_2p_mem_write_req_addr),
    .write_req_rdy      (fcip_mem_fake_2p_mem_write_req_rdy),
    .write_req_bit_en   (fcip_mem_fake_2p_mem_write_req_bit_en),
    .read_req_vld       (fcip_mem_fake_2p_mem_read_req_vld),
    .read_req_addr      (fcip_mem_fake_2p_mem_read_req_addr),
    .read_req_sideband  (fcip_mem_fake_2p_mem_read_req_sideband),
    .read_req_rdy       (fcip_mem_fake_2p_mem_read_req_rdy),
    .read_resp_vld      (fcip_mem_fake_2p_mem_read_resp_vld),
    .read_resp_data     (fcip_mem_fake_2p_mem_read_resp_data),
    .read_resp_sideband (fcip_mem_fake_2p_mem_read_resp_sideband),
    .read_resp_rdy      (fcip_mem_fake_2p_mem_read_resp_rdy),
    .spram_addr         (fcip_mem_fake_2p_mem_spram_addr),
    .spram_dout         (fcip_mem_fake_2p_mem_spram_dout),
    .spram_din          (fcip_mem_fake_2p_mem_spram_din),
    .spram_en           (fcip_mem_fake_2p_mem_spram_en),
    .spram_wren         (fcip_mem_fake_2p_mem_spram_wren),
    .spram_bit_en       (fcip_mem_fake_2p_mem_spram_bit_en),
    .stall              (fcip_mem_fake_2p_mem_stall),
    .clear              (fcip_mem_fake_2p_mem_clear),
    .idle               (fcip_mem_fake_2p_mem_idle)
);

// ============================================================
// SYNC_FIFO Module Instantiations
// ============================================================

// fcip_sync_fifo_reg instance (already added in previous section, no duplication)

// fcip_sync_fifo_reg_mimo instance
fcip_sync_fifo_reg_mimo #(
    .DEPTH    (128),
    .WR_WIDTH (4),
    .RD_WIDTH (4),
    .PLD_TYPE (logic [31:0])
) u_fcip_sync_fifo_reg_mimo (
    .clk       (clk),
    .rst_n     (rst_n),
    .v_s_rdy   (fcip_sync_fifo_reg_mimo_v_s_rdy),
    .v_s_vld   (fcip_sync_fifo_reg_mimo_v_s_vld),
    .v_s_pld   (fcip_sync_fifo_reg_mimo_v_s_pld),
    .v_m_vld   (fcip_sync_fifo_reg_mimo_v_m_vld),
    .v_m_rdy   (fcip_sync_fifo_reg_mimo_v_m_rdy),
    .v_m_pld   (fcip_sync_fifo_reg_mimo_v_m_pld)
);

// fcip_sfifo_spram_ctrl instance
fcip_sfifo_spram_ctrl #(
    .FIFO_DEPTH_PER_GROUP  (64),
    .SRAM_GROUP_NUM        (2),
    .DATA_WIDTH            (64),
    .ALMOST_FULL_THRESHOLD (2),
    .ALMOST_EMPTY_THRESHOLD(2),
    .FORWARD_EN            (1),
    .SIDEBAND_WIDTH        (1)
) u_fcip_sfifo_spram_ctrl (
    .clk                    (clk),
    .rst_n                  (rst_n),
    .write_vld              (fcip_sfifo_spram_ctrl_write_vld),
    .write_pld              (fcip_sfifo_spram_ctrl_write_pld),
    .write_rdy              (fcip_sfifo_spram_ctrl_write_rdy),
    .sram_read_en           (fcip_sfifo_spram_ctrl_sram_read_en),
    .sram_read_sel          (fcip_sfifo_spram_ctrl_sram_read_sel),
    .sram_pre_alloc_id      (fcip_sfifo_spram_ctrl_sram_pre_alloc_id),
    .spram_ctrl_empty       (fcip_sfifo_spram_ctrl_spram_ctrl_empty),
    .spram_ctrl_full        (fcip_sfifo_spram_ctrl_spram_ctrl_full),
    .spram_ctrl_almost_full (fcip_sfifo_spram_ctrl_spram_ctrl_almost_full),
    .spram_ctrl_almost_empty(fcip_sfifo_spram_ctrl_spram_ctrl_almost_empty),
    .rob_almost_empty       (fcip_sfifo_spram_ctrl_rob_almost_empty),
    .rob_almost_full        (fcip_sfifo_spram_ctrl_rob_almost_full),
    .mem_req_vld            (fcip_sfifo_spram_ctrl_mem_req_vld),
    .mem_req_rdy            (fcip_sfifo_spram_ctrl_mem_req_rdy),
    .mem_req_opcode         (fcip_sfifo_spram_ctrl_mem_req_opcode),
    .mem_req_addr           (fcip_sfifo_spram_ctrl_mem_req_addr),
    .mem_req_data           (fcip_sfifo_spram_ctrl_mem_req_data),
    .mem_req_bit_en         (fcip_sfifo_spram_ctrl_mem_req_bit_en),
    .mem_req_sideband       (fcip_sfifo_spram_ctrl_mem_req_sideband)
);

// fcip_sfifo_spram_rob instance
fcip_sfifo_spram_rob #(
    .ROB_DEPTH             (32),
    .DATA_WIDTH            (64),
    .FORWARD_EN            (1),
    .ALMOST_FULL_THRESHOLD (2),
    .ALMOST_EMPTY_THRESHOLD(0)
) u_fcip_sfifo_spram_rob (
    .clk              (clk),
    .rst_n            (rst_n),
    .rob_req_vld      (fcip_sfifo_spram_rob_rob_req_vld),
    .rob_req_pld      (fcip_sfifo_spram_rob_rob_req_pld),
    .rob_req_rdy      (fcip_sfifo_spram_rob_rob_req_rdy),
    .ram_req_vld      (fcip_sfifo_spram_rob_ram_req_vld),
    .ram_req_pld      (fcip_sfifo_spram_rob_ram_req_pld),
    .ram_req_id       (fcip_sfifo_spram_rob_ram_req_id),
    .ram_req_rdy      (fcip_sfifo_spram_rob_ram_req_rdy),
    .read_vld         (fcip_sfifo_spram_rob_read_vld),
    .read_pld         (fcip_sfifo_spram_rob_read_pld),
    .read_rdy         (fcip_sfifo_spram_rob_read_rdy),
    .rob_empty        (fcip_sfifo_spram_rob_rob_empty),
    .rob_full         (fcip_sfifo_spram_rob_rob_full),
    .rob_almost_empty (fcip_sfifo_spram_rob_rob_almost_empty),
    .rob_almost_full  (fcip_sfifo_spram_rob_rob_almost_full),
    .sram_pre_winc    (fcip_sfifo_spram_rob_sram_pre_winc),
    .rob_prealloc_id  (fcip_sfifo_spram_rob_rob_prealloc_id)
);

// fcip_sfifo_spram_ptr_ctrl instance
fcip_sfifo_spram_ptr_ctrl #(
    .FIFO_DEPTH_PER_GROUP(64),
    .DATA_WIDTH          (64),
    .SIDEBAND_WIDTH      (64)
) u_fcip_sfifo_spram_ptr_ctrl (
    .clk             (clk),
    .rst_n           (rst_n),
    .write_vld       (fcip_sfifo_spram_ptr_ctrl_write_vld),
    .write_pld       (fcip_sfifo_spram_ptr_ctrl_write_pld),
    .write_rdy       (fcip_sfifo_spram_ptr_ctrl_write_rdy),
    .read_vld        (fcip_sfifo_spram_ptr_ctrl_read_vld),
    .read_rdy        (fcip_sfifo_spram_ptr_ctrl_read_rdy),
    .read_sideband   (fcip_sfifo_spram_ptr_ctrl_read_sideband),
    .ram_ctrl_empty  (fcip_sfifo_spram_ptr_ctrl_ram_ctrl_empty),
    .ram_ctrl_full   (fcip_sfifo_spram_ptr_ctrl_ram_ctrl_full),
    .mem_req_vld     (fcip_sfifo_spram_ptr_ctrl_mem_req_vld),
    .mem_req_rdy     (fcip_sfifo_spram_ptr_ctrl_mem_req_rdy),
    .mem_req_opcode  (fcip_sfifo_spram_ptr_ctrl_mem_req_opcode),
    .mem_req_addr    (fcip_sfifo_spram_ptr_ctrl_mem_req_addr),
    .mem_req_data    (fcip_sfifo_spram_ptr_ctrl_mem_req_data),
    .mem_req_bit_en  (fcip_sfifo_spram_ptr_ctrl_mem_req_bit_en),
    .mem_req_sideband(fcip_sfifo_spram_ptr_ctrl_mem_req_sideband)
);

// fcip_sync_fifo_spram instance
fcip_sync_fifo_spram #(
    .FIFO_DEPTH_PER_GROUP  (64),
    .SRAM_GROUP_NUM        (2),
    .DATA_WIDTH            (16),
    .ALMOST_FULL_THRESHOLD (2),
    .ALMOST_EMPTY_THRESHOLD(2),
    .FORWARD_EN            (1),
    .ROB_DEPTH             (16),
    .SRAM_ACCESS_LATENCY   (1),
    .SRAM_REQ_PIPE_STAGE   (0),
    .SRAM_RSP_PIPE_STAGE   (0),
    .MCP_CYCLE             (1)
) u_fcip_sync_fifo_spram (
    .clk            (clk),
    .rst_n          (rst_n),
    .stall          (fcip_sync_fifo_spram_stall),
    .clear          (fcip_sync_fifo_spram_clear),
    .idle           (fcip_sync_fifo_spram_idle),
    .write_req_vld  (fcip_sync_fifo_spram_write_req_vld),
    .write_req_pld  (fcip_sync_fifo_spram_write_req_pld),
    .write_req_rdy  (fcip_sync_fifo_spram_write_req_rdy),
    .read_resp_vld  (fcip_sync_fifo_spram_read_resp_vld),
    .read_resp_pld  (fcip_sync_fifo_spram_read_resp_pld),
    .read_resp_rdy  (fcip_sync_fifo_spram_read_resp_rdy),
    .almost_full    (fcip_sync_fifo_spram_almost_full),
    .almost_empty   (fcip_sync_fifo_spram_almost_empty),
    .empty          (fcip_sync_fifo_spram_empty),
    .full           (fcip_sync_fifo_spram_full),
    .spram_addr     (fcip_sync_fifo_spram_spram_addr),
    .spram_din      (fcip_sync_fifo_spram_spram_din),
    .spram_dout     (fcip_sync_fifo_spram_spram_dout),
    .spram_en       (fcip_sync_fifo_spram_spram_en),
    .spram_wren     (fcip_sync_fifo_spram_spram_wren),
    .spram_bit_en   (fcip_sync_fifo_spram_spram_bit_en)
);

// fcip_afifo instance
fcip_afifo_doub #(
    .FIFO_DEPTH             (16),
    .DATA_WIDTH             (16),
    .AUTO_CLEAR_EN          (0),
    .THRESHOLD_EN           (1),
    .ALMOST_EMPTY_THRESHOLD (4),
    .ALMOST_FULL_THRESHOLD  (12),
    .DOUBLE_DATA_WIRE       (DOUBLE_DATA_WIRE),
    .SYNC_STAGE             (2)
) u_fcip_afifo_doub (
    .wclk           (fcip_afifo_doub_wclk),
    .rclk           (fcip_afifo_doub_rclk),
    .wrst_n         (fcip_afifo_doub_wrst_n),
    .rrst_n         (fcip_afifo_doub_rrst_n),
    .read_stall     (fcip_afifo_doub_read_stall),
    .write_stall    (fcip_afifo_doub_write_stall),
    .read_clear     (fcip_afifo_doub_read_clear),
    .write_clear    (fcip_afifo_doub_write_clear),
    .read_full_zero (fcip_afifo_doub_read_full_zero),
    .write_full_zero(fcip_afifo_doub_write_full_zero),
    .read_idle      (fcip_afifo_doub_read_idle),
    .almost_empty   (),
    .almost_full    (),
    .s_vld          (fcip_afifo_doub_s_vld),
    .s_pld          (fcip_afifo_doub_s_pld),
    .s_rdy          (fcip_afifo_doub_s_rdy),
    .m_vld          (fcip_afifo_doub_m_vld),
    .m_pld          (fcip_afifo_doub_m_pld),
    .m_rdy          (fcip_afifo_doub_m_rdy)
);

// fcip_afifo_mst instance
fcip_afifo_mst_doub #(
    .FIFO_DEPTH             (16),
    .DATA_WIDTH             (16),
    .AUTO_CLEAR_EN          (0),
    .THRESHOLD_EN           (1),
    .ALMOST_EMPTY_THRESHOLD (4),
    .DOUBLE_DATA_WIRE       (DOUBLE_DATA_WIRE),
    .SYNC_STAGE             (2)
) u_fcip_afifo_mst_doub (
    .clk         (clk),
    .rst_n       (rst_n),
    .stall       (fcip_afifo_mst_doub_stall),
    .clear       (fcip_afifo_mst_doub_clear),
    .full_zero   (fcip_afifo_mst_doub_full_zero),
    .idle        (fcip_afifo_mst_doub_idle),
    .m_vld       (fcip_afifo_mst_doub_m_vld),
    .m_pld       (fcip_afifo_mst_doub_m_pld),
    .m_rdy       (fcip_afifo_mst_doub_m_rdy),
    .almost_empty(),
    .wptr_async  (fcip_afifo_mst_doub_wptr_async),
    .rptr_async  (fcip_afifo_mst_doub_rptr_async),
    .rptr_sync   (fcip_afifo_mst_doub_rptr_sync),
    .pld_sync    (fcip_afifo_mst_doub_pld_sync)
);

// fcip_afifo_slv instance
fcip_afifo_slv_doub #(
    .FIFO_DEPTH             (16),
    .DATA_WIDTH             (16),
    .AUTO_CLEAR_EN          (0),
    .THRESHOLD_EN           (1),
    .ALMOST_FULL_THRESHOLD  (12),
    .DOUBLE_DATA_WIRE       (DOUBLE_DATA_WIRE),
    .SYNC_STAGE             (2)
) u_fcip_afifo_slv_doub (
    .clk        (clk),
    .rst_n      (rst_n),
    .stall      (fcip_afifo_slv_doub_stall),
    .clear      (fcip_afifo_slv_doub_clear),
    .full_zero  (fcip_afifo_slv_doub_full_zero),
    .s_vld      (fcip_afifo_slv_doub_s_vld),
    .s_pld      (fcip_afifo_slv_doub_s_pld),
    .s_rdy      (fcip_afifo_slv_doub_s_rdy),
    .almost_full(),
    .wptr_async (fcip_afifo_slv_doub_wptr_async),
    .rptr_async (fcip_afifo_slv_doub_rptr_async),
    .rptr_sync  (fcip_afifo_slv_doub_rptr_sync),
    .pld_sync   (fcip_afifo_slv_doub_pld_sync)
);

endmodule
