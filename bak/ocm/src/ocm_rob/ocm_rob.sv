module ocm_rob
import ocm_package::*;
(
    input  logic                                    clk                                         ,
    input  logic                                    rst_n                                       ,
    input  logic                                    crd                                         ,  
    input  pack_ocm_rob_req_pld                     rob_req_pld                                 ,
    input  logic                                    rob_req_en                                  ,
    input  logic [OCM_ROB_ENTRY_WIDTH-1:0]          rob_req_id                                  ,
    output logic [OCM_ROB_ENTRY_WIDTH-1:0]          rob_pre_alloc_aw_id                         ,
    output logic                                    rob_pre_alloc_aw_vld                        ,
    input  logic                                    rob_pre_alloc_aw_rdy                        ,
    output logic [OCM_ROB_ENTRY_WIDTH-1:0]          rob_pre_alloc_ar_id                         ,
    output logic                                    rob_pre_alloc_ar_vld                        ,
    input  logic                                    rob_pre_alloc_ar_rdy                        ,
    output logic [OCM_ROB_ENTRY_WIDTH-1:0]          v_hzd_id [OCM_ROB_ENTRY_DEPTH-1:0]          ,
    output logic [OCM_DATA_RAM_ADDR_WIDTH-1:0]      v_hzd_addr[OCM_ROB_ENTRY_DEPTH-1:0]         ,
    output logic [OCM_DATA_RAM_BANK_NUM_WIDTH-1:0]  v_hzd_num[OCM_ROB_ENTRY_DEPTH-1:0]          ,
    output logic [OCM_ROB_ENTRY_DEPTH-1:0]          v_hzd_addr_en                               ,
    output logic [OCM_ROB_ENTRY_DEPTH-1:0]          v_hzd_id_en                                 ,
    input  logic [OCM_ROB_ENTRY_DEPTH-1:0]          id_hzd                                      ,
    input  logic [OCM_ROB_ENTRY_DEPTH-1:0]          addr_hzd                                    ,                          
    input  logic                                    wr_data_buf_done                            ,
    input  logic [OCM_ROB_ENTRY_WIDTH-1:0]          wr_data_buf_done_id                         ,
    input  logic                                    wr_data_ram_done                            ,
    input  logic [OCM_ROB_ENTRY_WIDTH-1:0]          wr_data_ram_done_id                         ,
    input  logic                                    rd_data_ram_done                            ,
    input  logic [OCM_ROB_ENTRY_WIDTH-1:0]          rd_data_ram_done_id                         ,
    output logic                                    bvld                                        ,
    input  logic                                    brdy                                        ,
    output pack_ocm_b_pld                           bpld                                        ,
    output logic                                    rob_rd_data_ram_vld                         ,
    output pack_ocm_rob_ack_pld                     rob_rd_data_ram_pld                         ,
    output logic                                    rob_wr_data_ram_vld                         ,
    output pack_ocm_rob_ack_pld                     rob_wr_data_ram_pld      

);

//========================================================   
//=========internal signals 
//========================================================   
logic [OCM_ROB_ENTRY_DEPTH-1:0]         v_wr_data_buf_done                              ;
logic [OCM_ROB_ENTRY_DEPTH-1:0]         v_rd_data_ram_done                              ;
logic [OCM_ROB_ENTRY_DEPTH-1:0]         v_wr_data_ram_done                              ;
logic [OCM_ROB_ENTRY_DEPTH-1:0]         v_rob_req_en                                    ;
logic [OCM_ROB_ENTRY_DEPTH-1:0]         v_age               [OCM_ROB_ENTRY_DEPTH-1:0]   ;
logic [OCM_ROB_ENTRY_DEPTH-1:0]         v_b_vld                                         ;
logic [OCM_ROB_ENTRY_DEPTH-1:0]         v_b_rdy                                         ;
pack_ocm_b_pld                          v_b_pld             [OCM_ROB_ENTRY_DEPTH-1:0]   ;
logic [OCM_ROB_ENTRY_DEPTH-1:0]         v_pre_alloc_vld                                 ;
logic [OCM_ROB_ENTRY_DEPTH-1:0]         v_pre_alloc_rdy                                 ;
logic [OCM_ROB_ENTRY_DEPTH-1:0]         v_arb_req_wr_vld                                ;
logic [OCM_ROB_ENTRY_DEPTH-1:0]         v_arb_req_wr_rdy                                ;
pack_ocm_rob_ack_pld                    v_arb_req_wr_pld    [OCM_ROB_ENTRY_DEPTH-1:0]   ;
logic [OCM_ROB_ENTRY_DEPTH-1:0]         v_arb_req_rd_vld                                ;
logic [OCM_ROB_ENTRY_DEPTH-1:0]         v_arb_req_rd_rdy                                ;
pack_ocm_rob_ack_pld                    v_arb_req_rd_pld    [OCM_ROB_ENTRY_DEPTH-1:0]   ;
logic [OCM_ROB_ENTRY_DEPTH-1:0]         release_en                                      ;

logic [OCM_DATA_RAM_BANK_NUM-1:0]       bank_agt_wr_update                              ; 
logic [OCM_DATA_RAM_BANK_NUM-1:0]       bank_agt_rd_update                              ;
logic [OCM_DATA_RAM_BANK_NUM-1:0]       bank_agt_wr_bank_en                             ;
logic [OCM_DATA_RAM_BANK_NUM-1:0]       bank_agt_rd_bank_en                             ;
logic [OCM_ROB_ENTRY_DEPTH-1:0]         v_arb_req_wr_vld_msk                            ;
logic [OCM_DATA_RAM_BANK_NUM_WIDTH-1:0] v_arb_req_wr_bank_num[OCM_ROB_ENTRY_DEPTH-1:0]  ;
logic [OCM_ROB_ENTRY_DEPTH-1:0]         v_arb_req_rd_vld_msk                            ;
logic [OCM_DATA_RAM_BANK_NUM_WIDTH-1:0] v_arb_req_rd_bank_num[OCM_ROB_ENTRY_DEPTH-1:0]  ;
pack_ocm_rob_ack_pld                    rob_rd_data_ram_pld_raw                         ;
pack_ocm_rob_ack_pld                    rob_wr_data_ram_pld_raw                         ;

//========================================================   
//=========done id decoder && entry update decoder 
//======================================================== 
cmn_rob_id_dec#(
    .BIN_WIDTH(OCM_ROB_ENTRY_WIDTH)
)u_wr_data_done_dec(
    .in_en   (wr_data_buf_done      ),
    .in_index(wr_data_buf_done_id   ),
    .v_out_en(v_wr_data_buf_done    )
);

cmn_rob_id_dec#(
    .BIN_WIDTH(OCM_ROB_ENTRY_WIDTH)
)u_wr_data_ram_done_dec(
    .in_en   (wr_data_ram_done      ),
    .in_index(wr_data_ram_done_id   ),
    .v_out_en(v_wr_data_ram_done    )
);

cmn_rob_id_dec#(
    .BIN_WIDTH(OCM_ROB_ENTRY_WIDTH)
)u_rd_data_ram_done_dec(
    .in_en   (rd_data_ram_done      ),
    .in_index(rd_data_ram_done_id   ),
    .v_out_en(v_rd_data_ram_done    )
);

cmn_rob_id_dec#(
    .BIN_WIDTH(OCM_ROB_ENTRY_WIDTH)
)u_ety_update_dec(
    .in_en   (rob_req_en          ),
    .in_index(rob_req_id          ),
    .v_out_en(v_rob_req_en        )
);

//========================================================   
//=========b decoder 
//======================================================== 
ocm_rob_bdec u_ocm_rob_bdec(
    .v_b_vld  (v_b_vld            ),
    .v_b_rdy  (v_b_rdy            ), 
    .v_b_pld  (v_b_pld            ),
    .bvld     (bvld               ),
    .brdy     (brdy               ),
    .bpld     (bpld               )
);
//========================================================   
//=========age matrix 
//======================================================== 
cmn_age_matrix #(
    .WIDTH(OCM_ROB_ENTRY_DEPTH)
)u_ocm_rob_age_mtx(
    .clk        (clk            ),
    .rst_n      (rst_n          ),
    .alloc_en   (rob_req_en     ),
    .v_alloc    (v_rob_req_en   ),
    .vv_matrix  (v_age          )
);
//========================================================   
//=========pre alloc
//======================================================== 

logic [OCM_ROB_ENTRY_WIDTH-1:0] pre_alloc_out_pld  [1:0]    ;
assign rob_pre_alloc_aw_id  = pre_alloc_out_pld[1]      ;
assign rob_pre_alloc_ar_id  = pre_alloc_out_pld[0]      ;
cmn_rob_list_prealloc #(
    .ROB_ENTRY_DEPTH(OCM_ROB_ENTRY_DEPTH),
    .REQ_NUM        (2)
)u_cmn_rob_list_preaaloc(
    .v_in_vld (v_pre_alloc_vld                              ),
    .v_in_rdy (v_pre_alloc_rdy                              ),
    .out_vld  ({rob_pre_alloc_aw_vld,rob_pre_alloc_ar_vld}  ),
    .out_rdy  ({rob_pre_alloc_aw_rdy,rob_pre_alloc_ar_rdy}  ),
    .out_pld  (pre_alloc_out_pld                            )
);

//========================================================   
//=========ROB entry
//======================================================== 
genvar i ;
generate for(i=0;i<OCM_ROB_ENTRY_DEPTH;i++) begin
    ocm_rob_entry u_ocm_rob_entry(
        .clk                (clk                    ),
        .rst_n              (rst_n                  ),
        .rob_req_pld        (rob_req_pld            ),
        .v_rob_req_en       (v_rob_req_en[i]        ),
        .id_hzd             (id_hzd                 ),
        .addr_hzd           (addr_hzd               ),
        .v_hzd_addr_en      (v_hzd_addr_en[i]       ),
        .v_hzd_id_en        (v_hzd_id_en[i]         ),
        .v_hzd_id           (v_hzd_id[i]            ),
        .v_hzd_num          (v_hzd_num[i]           ),
        .v_hzd_addr         (v_hzd_addr[i]          ),
        .v_wr_data_buf_done (v_wr_data_buf_done[i]  ),
        .v_wr_data_ram_done (v_wr_data_ram_done[i]  ),
        .v_rd_data_ram_done (v_rd_data_ram_done[i]  ),
        .v_pre_alloc_vld    (v_pre_alloc_vld[i]     ),
        .v_pre_alloc_rdy    (v_pre_alloc_rdy[i]     ),
        .v_b_vld            (v_b_vld[i]             ),
        .v_b_rdy            (v_b_rdy[i]             ),
        .v_b_pld            (v_b_pld[i]             ),
        .v_arb_req_wr_vld   (v_arb_req_wr_vld[i]    ),
        .v_arb_req_wr_rdy   (v_arb_req_wr_rdy[i]    ),
        .v_arb_req_wr_pld   (v_arb_req_wr_pld[i]    ),
        .v_arb_req_rd_vld   (v_arb_req_rd_vld[i]    ),
        .v_arb_req_rd_rdy   (v_arb_req_rd_rdy[i]    ),
        .v_arb_req_rd_pld   (v_arb_req_rd_pld[i]    ),
        .v_release_en       (release_en[i]          ),
        .release_en         (release_en             ) 
    );
end
endgenerate
//========================================================   
//=========Arbiter
//======================================================== 
generate for(i=0;i<OCM_DATA_RAM_BANK_NUM;i++) begin
    ocm_bank_agt u_ocm_bank_agt(
        .clk        (clk                    ),
        .rst_n      (rst_n                  ),    
        .wr_update  (bank_agt_wr_update [i] ),
        .rd_update  (bank_agt_rd_update [i] ),
        .wr_bank_en (bank_agt_wr_bank_en[i] ),     
        .rd_bank_en (bank_agt_rd_bank_en[i] )
    );   
end
endgenerate

generate for(i=0;i<OCM_ROB_ENTRY_DEPTH;i++) begin
    assign v_arb_req_wr_bank_num[i] = v_arb_req_wr_pld[i].ram_num  ;
    assign v_arb_req_rd_bank_num[i] = v_arb_req_rd_pld[i].ram_num  ;
end
endgenerate 

ocm_bank_merge ocm_arb_req_wr_vld_merge(
    .raw_vld  (v_arb_req_wr_vld     ),
    .bank_num (v_arb_req_wr_bank_num),
    .bank_mask(bank_agt_wr_bank_en  ),
    .vld      (v_arb_req_wr_vld_msk )
);

ocm_bank_merge ocm_arb_req_rd_vld_merge(
    .raw_vld  (v_arb_req_rd_vld     ),
    .bank_num (v_arb_req_rd_bank_num),
    .bank_mask(bank_agt_rd_bank_en  ),
    .vld      (v_arb_req_rd_vld_msk )
);

cmn_arb_vrp_matrix #(
    .WIDTH     (OCM_ROB_ENTRY_DEPTH ),
    .PLD_TYPE  (pack_ocm_rob_ack_pld)
)u_ocm_rob_wr_arb(
    .clk       (clk                     ),
    .rst_n     (rst_n                   ),
    .vv_matrix (v_age                   ),
    .v_vld_s   (v_arb_req_wr_vld_msk    ),
    .v_rdy_s   (v_arb_req_wr_rdy        ),
    .v_pld_s   (v_arb_req_wr_pld        ),
    .vld_m     (rob_wr_data_ram_vld     ),
    .rdy_m     (1'b1                    ),
    .pld_m     (rob_wr_data_ram_pld_raw )
);

ocm_rob_enc u_wr_ram_rob_id_enc(
    .id_ohot(v_arb_req_wr_rdy       ),
    .raw_pld(rob_wr_data_ram_pld_raw),   
    .enc_pld(rob_wr_data_ram_pld    )   
);

ocm_crd_arb_vrp_matrix #(
    .WIDTH     (OCM_ROB_ENTRY_DEPTH ),
    .PLD_TYPE  (pack_ocm_rob_ack_pld)
)u_ocm_rob_rd_arb(
    .clk       (clk                     ),
    .rst_n     (rst_n                   ),
    .crd       (crd                     ),
    .vv_matrix (v_age                   ),
    .v_vld_s   (v_arb_req_rd_vld_msk    ),
    .v_rdy_s   (v_arb_req_rd_rdy        ),
    .v_pld_s   (v_arb_req_rd_pld        ),
    .vld_m     (rob_rd_data_ram_vld     ),
    .rdy_m     (1'b1                    ),
    .pld_m     (rob_rd_data_ram_pld_raw )
);
ocm_rob_enc u_rd_ram_rob_id_enc(
    .id_ohot(v_arb_req_rd_rdy       ),
    .raw_pld(rob_rd_data_ram_pld_raw),   
    .enc_pld(rob_rd_data_ram_pld    )   
);
endmodule