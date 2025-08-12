module ocm_top
    import ocm_package::*;

(
    input  logic                     clk        ,
    input  logic                     clk_2x     ,
    input  logic                     rst_n      ,
    //axi channel signals
    input  logic                     awvld      ,
    output logic                     awrdy      ,
    input  pack_ocm_aw_pld           awpld      ,
    input  logic                     arvld      ,
    output logic                     arrdy      ,
    input  pack_ocm_ar_pld           arpld      ,
    output logic                     bvld       ,
    input  logic                     brdy       , 
    output pack_ocm_b_pld            bpld       ,
    input  logic                     wvld       ,
    output logic                     wrdy       ,
    input  pack_ocm_w_pld            wpld       ,
    output logic                     rvld       ,
    input  logic                     rrdy       ,
    output pack_ocm_r_pld            rpld       ,
    //ecc flag;
    output                           cor_err    ,//indicated one bit error is detected and corrected
    output                           uncor_err   //indicated two bits error is detected
);

//=================================
//============internal signals
//=================================
logic                                    axen                             ;
pack_ocm_ax_pld                          axpld                            ;
logic [OCM_ROB_ENTRY_WIDTH-1:0]          v_hzd_id [OCM_ROB_ENTRY_NUM-1:0] ;
logic [OCM_L_DATA_RAM_DATA_WIDTH-1:0]    v_hzd_addr[OCM_ROB_ENTRY_NUM-1:0];
logic [OCM_DATA_RAM_DEPTH-1:0]           v_hzd_num[OCM_ROB_ENTRY_NUM-1:0] ;
logic [OCM_ROB_ENTRY_NUM-1:0]            v_hzd_en                         ;
logic                                    hzd_id_en                        ;
logic                                    hzd_addr_en                      ;
logic                                    rob_id_rdy                       ;
logic                                    rob_id_vld                       ;
logic [OCM_ROB_ENTRY_WIDTH-1:0]          rob_id                           ;
logic                                    read_data_buf_en                 ;
pack_ocm_arb_ack_pld                     read_data_buf_pld                ;
logic                                    read_data_ram_en                 ;
pack_ocm_arb_ack_pld                     read_data_ram_pld                ;
logic                                    wr_data_buf_done                 ;
logic [OCM_ROB_ENTRY_WIDTH-1:0]          wr_data_buf_done_id              ;
logic                                    wr_data_ram_done                 ;
logic [OCM_ROB_ENTRY_WIDTH-1:0]          wr_data_ram_done_id              ;
logic                                    rd_data_ram_done                 ;
logic [OCM_ROB_ENTRY_WIDTH-1:0]          rd_data_ram_done_id              ;
logic                                    credit                           ;  
logic [OCM_ROB_ENTRY_WIDTH-1:0]          w_rob_id                         ;
logic [OCM_AXI_ADDR_WIDTH-1:0]           init_rgn                         ;
logic                                    init_start                       ;
//=================================
//============ocm_req_arb
//=================================
ocm_req_arb u_ocm_req_arb(   
    .clk        (clk       ),
    .rst_n      (rst_n     ),
    .arvld      (arvld     ),
    .arrdy      (arrdy     ),
    .arpld      (arpld     ),
    .awvld      (awvld     ),
    .awrdy      (awrdy     ),
    .awpld      (awpld     ),
    .rob_id     (rob_id    ),
    .rob_id_vld (rob_id_vld),
    .rob_id_rdy (rob_id_rdy),
    .wvld       (wvld      ),
    .wlast      (wpld.wlast),
    .wrdy       (wrdy      ),
    .w_rob_id   (w_rob_id  ),
    .axpld      (axpld     ),
    .axvld      (axen      ),
    .init_rgn   (init_rgn  )   
);

//=================================
//============ocm_hzd
//=================================
ocm_hzd u_ocm_hzd(
    .v_hzd_id               (v_hzd_id       ),
    .v_hzd_addr             (v_hzd_addr     ),
    .v_hzd_data_ram_num     (v_hzd_num      ),
    .v_hzd_en               (v_hzd_en       ),
    .req_arb_id             (axpld.axid     ),
    .req_arb_addr           (axpld.axaddr   ),
    .id_hzd                 (hzd_id_en      ),
    .addr_hzd               (hzd_addr_en    )                                  
);
//=================================
//============ocm_rob
//=================================
ocm_rob u_ocm_rob(
    .clk                 (clk                ),
    .rst_n               (rst_n              ),
    .axen                (axen               ),
    .axpld               (axpld              ),
    .v_hzd_id            (v_hzd_id           ),
    .v_hzd_addr          (v_hzd_addr         ),
    .v_hzd_num           (v_hzd_num          ),
    .v_hzd_en            (v_hzd_en           ),
    .hzd_id_en           (hzd_id_en          ),
    .hzd_addr_en         (hzd_addr_en        ),
    .rob_id_rdy          (rob_id_rdy         ),
    .rob_id_vld          (rob_id_vld         ),
    .rob_id              (rob_id             ),
    .read_data_buf_en    (read_data_buf_en   ),
    .read_data_buf_pld   (read_data_buf_pld  ),
    .read_data_ram_en    (read_data_ram_en   ),
    .read_data_ram_pld   (read_data_ram_pld  ),
    .wr_data_buf_done    (wr_data_buf_done   ),
    .wr_data_buf_done_id (wr_data_buf_done_id),
    .wr_data_ram_done    (wr_data_ram_done   ),
    .wr_data_ram_done_id (wr_data_ram_done_id),
    .rd_data_ram_done    (rd_data_ram_done   ),
    .rd_data_ram_done_id (rd_data_ram_done_id),
    .bvld                (bvld               ),
    .brdy                (brdy               ),
    .bpld                (bpld               ),
    .credit              (credit             )             
);
//=================================
//============ocm_data_pipe
//=================================
ocm_data_pipe u_ocm_data_pipe(
    .clk                  (clk                    ),
    .clk_x2               (clk_x2                 ),
    .rst_n                (rst_n                  ),
    .wvld                 (wvld                   ),
    .wpld                 (wpld                   ),
    .wrdy                 (wrdy                   ),
    .w_rob_id             (w_rob_id               ),
    .init_start           (init_start             ),
    .init_rgn             (init_rgn               ),
    .read_data_buf_en     (read_data_buf_en       ),
    .read_data_buf_pld    (read_data_buf_pld      ),
    .read_data_ram_en     (read_data_ram_en       ),
    .read_data_ram_pld    (read_data_ram_pld      ),
    .rvld                 (rvld                   ),
    .rpld                 (rpld                   ),
    .rrdy                 (rrdy                   ),
    .wr_data_buf_done     (wr_data_buf_done       ),
    .wr_data_buf_id       (wr_data_buf_done_id    ),
    .wr_data_ram_done     (wr_data_ram_done       ),
    .wr_data_ram_id       (wr_data_ram_done_id    ),  
    .rd_data_ram_done     (rd_data_ram_done       ),
    .rd_data_ram_id       (rd_data_ram_done_id    ),
    .uncor_ecc            (uncor_err              ),
    .cor_ecc              (cor_err                ),
    .credit               (credit                 ) 
);
endmodule