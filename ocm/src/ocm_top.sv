module ocm_top
import ocm_package::*;
(
    input  logic                                clk              ,
    input  logic                                rst_n            ,
    input  logic                                arvld            ,
    output logic                                arrdy            ,
    input  pack_ocm_ax_pld                      arpld            ,
    input  logic                                awvld            ,
    output logic                                awrdy            ,
    output logic                                bvld             ,
    input  logic                                brdy             ,
    output pack_ocm_b_pld                       bpld             ,
    input  pack_ocm_ax_pld                      awpld            ,
    input  logic                                wvld             ,
    output logic                                wrdy             ,
    input  pack_ocm_w_pld                       wpld             ,
    output logic                                rvld             ,
    input  logic                                rrdy             ,
    output pack_ocm_r_pld                       rpld             ,
    input  logic                                init             ,
    output logic                                init_don         ,
    output logic                                sb_err           ,
    output logic                                db_err
);

logic [OCM_ROB_ENTRY_WIDTH-1:0]            rob_pre_alloc_aw_id                     ;
logic                                      rob_pre_alloc_aw_vld                    ;
logic                                      rob_pre_alloc_aw_rdy                    ;
logic                                      rob_pre_alloc_w_rdy                     ;
logic                                      rob_pre_alloc_xw_rdy                    ;
       
logic [OCM_ROB_ENTRY_WIDTH-1:0]            rob_pre_alloc_ar_id                     ;
logic                                      rob_pre_alloc_ar_vld                    ;
logic                                      rob_pre_alloc_ar_rdy                    ;
pack_ocm_rob_req_pld                       rob_req_pld                             ;
logic                                      rob_req_en                              ;
logic [OCM_ROB_ENTRY_WIDTH-1:0]            rob_req_id                              ;
logic [OCM_ROB_ENTRY_WIDTH-1:0]            v_hzd_id [OCM_ROB_ENTRY_DEPTH-1:0]      ;
logic [OCM_DATA_RAM_ADDR_WIDTH-1:0]        v_hzd_addr[OCM_ROB_ENTRY_DEPTH-1:0]     ;
logic [OCM_DATA_RAM_BANK_NUM_WIDTH-1:0]    v_hzd_num[OCM_ROB_ENTRY_DEPTH-1:0]      ;
logic [OCM_ROB_ENTRY_DEPTH-1:0]            v_hzd_addr_en                           ;
logic [OCM_ROB_ENTRY_DEPTH-1:0]            v_hzd_id_en                             ;
logic [OCM_ROB_ENTRY_DEPTH-1:0]            id_hzd                                  ;
logic [OCM_ROB_ENTRY_DEPTH-1:0]            addr_hzd                                ;        
logic                                      crd                                     ;
logic                                      wfifo_out_vld                           ;
logic                                      wfifo_out_rdy                           ;
logic [OCM_ROB_ENTRY_WIDTH-1:0]            wfifo_out_data                          ;
logic                                      wr_data_buf_done                        ;
logic [OCM_ROB_ENTRY_WIDTH-1:0]            wr_data_buf_done_id                     ;
logic                                      wr_data_ram_done                        ;
logic [OCM_ROB_ENTRY_WIDTH-1:0]            wr_data_ram_done_id                     ;
logic                                      rd_data_ram_done                        ;
logic [OCM_ROB_ENTRY_WIDTH-1:0]            rd_data_ram_done_id                     ;
logic                                      rob_rd_data_ram_vld                     ;
pack_ocm_rob_ack_pld                       rob_rd_data_ram_pld                     ;
logic                                      rob_wr_data_ram_vld                     ;
pack_ocm_rob_ack_pld                       rob_wr_data_ram_pld                     ;

ocm_req_arb u_ocm_req_arb(
    .clk                    (clk                 ),
    .rst_n                  (rst_n               ),
    .arvld                  (arvld               ),
    .arrdy                  (arrdy               ),
    .arpld                  (arpld               ),
    .awvld                  (awvld               ),
    .awrdy                  (awrdy               ),
    .awpld                  (awpld               ),
    .rob_pre_alloc_aw_id    (rob_pre_alloc_aw_id ),
    .rob_pre_alloc_aw_vld   (rob_pre_alloc_aw_vld),
    .rob_pre_alloc_aw_rdy   (rob_pre_alloc_aw_rdy),
    .rob_pre_alloc_ar_id    (rob_pre_alloc_ar_id ),
    .rob_pre_alloc_ar_vld   (rob_pre_alloc_ar_vld),
    .rob_pre_alloc_ar_rdy   (rob_pre_alloc_ar_rdy),           
    .rob_req_pld            (rob_req_pld         ),
    .rob_req_en             (rob_req_en          ),
    .rob_req_id             (rob_req_id          ),
    .v_hzd_id               (v_hzd_id            ),
    .v_hzd_addr             (v_hzd_addr          ),
    .v_hzd_num              (v_hzd_num           ),
    .v_hzd_addr_en          (v_hzd_addr_en       ),
    .v_hzd_id_en            (v_hzd_id_en         ),
    .id_hzd                 (id_hzd              ),
    .addr_hzd               (addr_hzd            ),                          
    .init                   (init                ),
    .init_done              (init_done           )
);
assign rob_pre_alloc_xw_rdy = rob_pre_alloc_aw_rdy||rob_pre_alloc_w_rdy;
ocm_rob u_ocm_rob(
    .clk                    (clk                 ) ,
    .rst_n                  (rst_n               ) ,
    .crd                    (crd                 ) ,  
    .rob_req_pld            (rob_req_pld         ) ,
    .rob_req_en             (rob_req_en          ) ,
    .rob_req_id             (rob_req_id          ) ,
    .rob_pre_alloc_aw_id    (rob_pre_alloc_aw_id ) ,
    .rob_pre_alloc_aw_vld   (rob_pre_alloc_aw_vld) ,
    .rob_pre_alloc_aw_rdy   (rob_pre_alloc_xw_rdy) ,
    .rob_pre_alloc_ar_id    (rob_pre_alloc_ar_id ) ,
    .rob_pre_alloc_ar_vld   (rob_pre_alloc_ar_vld) ,
    .rob_pre_alloc_ar_rdy   (rob_pre_alloc_ar_rdy) ,
    .v_hzd_id               (v_hzd_id            ) ,
    .v_hzd_addr             (v_hzd_addr          ) ,
    .v_hzd_num              (v_hzd_num           ) ,
    .v_hzd_addr_en          (v_hzd_addr_en       ) ,
    .v_hzd_id_en            (v_hzd_id_en         ) ,
    .id_hzd                 (id_hzd              ) ,
    .addr_hzd               (addr_hzd            ) ,                          
    .wr_data_buf_done       (wr_data_buf_done    ) ,
    .wr_data_buf_done_id    (wr_data_buf_done_id ) ,
    .wr_data_ram_done       (wr_data_ram_done    ) ,
    .wr_data_ram_done_id    (wr_data_ram_done_id ) ,
    .rd_data_ram_done       (rd_data_ram_done    ) ,
    .rd_data_ram_done_id    (rd_data_ram_done_id ) ,
    .bvld                   (bvld                ) ,
    .brdy                   (brdy                ) ,
    .bpld                   (bpld                ) ,
    .rob_rd_data_ram_vld    (rob_rd_data_ram_vld ) ,
    .rob_rd_data_ram_pld    (rob_rd_data_ram_pld ) ,
    .rob_wr_data_ram_vld    (rob_wr_data_ram_vld ) ,
    .rob_wr_data_ram_pld    (rob_wr_data_ram_pld )
);

ocm_data_pipe u_ocm_data_pipe(
    .clk             (clk                 ),
    .rst_n           (rst_n               ),
    .wvld            (wvld                ),
    .wrdy            (wrdy                ),
    .wpld            (wpld                ),
    .rvld            (rvld                ),
    .rrdy            (rrdy                ),
    .rpld            (rpld                ),
    .rfifo_crd       (crd                 ),
    .wfifo_out_vld   (wfifo_out_vld       ),
    .wfifo_out_rdy   (wfifo_out_rdy       ),
    .wfifo_out_data  (wfifo_out_data      ),
    .rd_data_buf_en  (rob_rd_data_ram_vld ),
    .rd_data_buf_pld (rob_rd_data_ram_pld ),     
    .rd_data_ram_en  (rob_wr_data_ram_vld ),
    .rd_data_ram_pld (rob_wr_data_ram_pld ),
    .wr_data_buf_done(wr_data_buf_done    ),
    .wr_data_buf_id  (wr_data_buf_done_id ),
    .wr_data_ram_done(wr_data_ram_done    ),                                   
    .wr_data_ram_id  (wr_data_ram_done_id ),                                   
    .rd_data_ram_done(rd_data_ram_done    ),                                   
    .rd_data_ram_id  (rd_data_ram_done_id ),
    .sb_err          (sb_err              ),
    .db_err          (db_err              )                       
);

cmn_vrp_reg_fifo#(
    .PLD_TYPE  (logic [OCM_ROB_ENTRY_WIDTH-1:0]),
    .ADDR_WIDTH(OCM_REQ_ARB_DEPTH              )
)u_rob_w_fifo(
    .clk    (clk                    ),
    .rst_n  (rst_n                  ),
    .in_vld (rob_pre_alloc_aw_vld   ), 
    .in_rdy (rob_pre_alloc_w_rdy   ), 
    .in_pld (rob_pre_alloc_aw_id    ), 
    .out_vld(wfifo_out_vld          ), 
    .out_rdy(wfifo_out_rdy          ), 
    .out_pld(wfifo_out_data         )  
);

endmodule