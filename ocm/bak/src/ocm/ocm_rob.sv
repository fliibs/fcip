module ocm_rob
import ocm_package::*;
(
    input  logic                                    clk                                         ,
    input  logic                                    rst_n                                       ,
    //io with hzd check 
    input  logic                                    axen                                        ,
    input  pack_ocm_ax_pld                          axpld                                       ,
    output logic [OCM_ROB_ENTRY_WIDTH-1:0]          v_hzd_id [OCM_ROB_ENTRY_NUM-1:0]            ,
    output logic [OCM_L_DATA_RAM_DATA_WIDTH-1:0]    v_hzd_addr[OCM_ROB_ENTRY_NUM-1:0]           ,
    output logic [OCM_DATA_RAM_DEPTH-1:0]           v_hzd_num[OCM_ROB_ENTRY_NUM-1:0]            ,
    output logic [OCM_ROB_ENTRY_NUM-1:0]            v_hzd_en                                    ,
    input  logic                                    hzd_id_en                                   ,
    input  logic                                    hzd_addr_en                                 ,
    //preallocate   
    input  logic                                    rob_id_rdy                                  ,
    output logic                                    rob_id_vld                                  ,
    output logic [OCM_ROB_ENTRY_WIDTH-1:0]          rob_id                                      ,
    //read and write req    
    output logic                                    read_data_buf_en                            ,
    output pack_ocm_arb_ack_pld                     read_data_buf_pld                           ,
    output logic                                    read_data_ram_en                            ,
    output pack_ocm_arb_ack_pld                     read_data_ram_pld                           ,
    //input done signel
    input  logic                                    wr_data_buf_done                            ,
    input  logic [OCM_ROB_ENTRY_WIDTH-1:0]          wr_data_buf_done_id                         ,
    input  logic                                    wr_data_ram_done                            ,
    input  logic [OCM_ROB_ENTRY_WIDTH-1:0]          wr_data_ram_done_id                         ,
    input  logic                                    rd_data_ram_done                            ,
    input  logic [OCM_ROB_ENTRY_WIDTH-1:0]          rd_data_ram_done_id                         ,
    //b channel
    output logic                                    bvld                                        ,
    input  logic                                    brdy                                        ,
    output pack_ocm_b_pld                           bpld                                        ,
    //credit 
    input  logic                                    credit                                                   
);
//==============================================
//================internal signals
//==============================================
logic [OCM_ROB_ENTRY_NUM-1:0] v_wr_data_buf_done                    ;
logic [OCM_ROB_ENTRY_NUM-1:0] v_rd_data_ram_done                    ;
logic [OCM_ROB_ENTRY_NUM-1:0] v_wr_data_ram_done                    ;
logic [OCM_ROB_ENTRY_NUM-1:0] v_b_vld                               ;
logic [OCM_ROB_ENTRY_NUM-1:0] v_b_rdy                               ;
pack_ocm_b_pld                v_b_pld[OCM_ROB_ENTRY_NUM-1:0]        ;
logic [OCM_ROB_ENTRY_NUM-1:0] v_axen                                ;
logic [OCM_ROB_ENTRY_NUM-1:0] [OCM_ROB_ENTRY_NUM-1:0]    v_age      ;
logic [OCM_ROB_ENTRY_NUM-1:0] v_pre_alloc_vld                       ;
logic [OCM_ROB_ENTRY_NUM-1:0] v_pre_alloc_rdy                       ;
logic [OCM_ROB_ENTRY_NUM-1:0] v_arb_req                             ;
logic [OCM_ROB_ENTRY_NUM-1:0] v_arb_op_is_rd                        ;
pack_ocm_arb_req_pld          v_arb_req_pld [OCM_ROB_ENTRY_NUM-1:0] ;
logic [OCM_ROB_ENTRY_NUM-1:0] v_arb_ack                             ;
logic [OCM_ROB_ENTRY_NUM-1:0] v_release_en                          ;

ocm_rob_done_dec#(
    .BIN_WIDTH(OCM_ROB_ENTRY_WIDTH)
)u_wr_data_buf_done_dec(
    .in_en   (wr_data_buf_done      ),
    .in_index(wr_data_buf_done_id   ),
    .v_out_en(v_wr_data_buf_done    )
);

ocm_rob_done_dec#(
    .BIN_WIDTH(OCM_ROB_ENTRY_WIDTH)
)u_update_en_dec(
    .in_en   (axen                  ),
    .in_index(axpld.rob_id          ),
    .v_out_en(v_axen                )
);

ocm_rob_done_dec#(
    .BIN_WIDTH(OCM_ROB_ENTRY_WIDTH)
)u_wr_data_ram_done_dec(
    .in_en   (wr_data_ram_done      ),
    .in_index(wr_data_ram_done_id   ),
    .v_out_en(v_wr_data_ram_done    )
);

ocm_rob_done_dec#(
    .BIN_WIDTH(OCM_ROB_ENTRY_WIDTH)
)u_rd_data_ram_done_dec(
    .in_en   (rd_data_ram_done      ),
    .in_index(rd_data_ram_done_id   ),
    .v_out_en(v_rd_data_ram_done    )
);

ocm_rob_bdec u_ocm_rob_bdec(
    .v_b_vld               (v_b_vld            ),
    .v_b_rdy               (v_b_rdy            ), 
    .v_b_pld               (v_b_pld            ),
    .bvld                  (bvld               ),
    .brdy                  (brdy               ),
    .bpld                  (bpld               )
);

ocm_rob_age_matrix u_rob_age_matrix(
    .clk           (clk     ),
    .rst_n         (rst_n   ),
    .axen          (axen    ),
    .v_update_en   (v_axen  ),
    .v_age         (v_age   )  
);

genvar i ;
generate for(i=0;i<OCM_ROB_ENTRY_NUM;i++) begin
    ocm_rob_entry u_ocm_rob_entry(
        .clk                      (clk                      ),
        .rst_n                    (rst_n                    ),
        .axpld                    (axpld                    ),
        .v_update_en              (v_axen[i]                ),
        .hzd_id_en                (hzd_id_en                ),
        .hzd_addr_en              (hzd_addr_en              ),
        .v_en                     (v_hzd_en[i]              ),
        .v_hzd_id                 (v_hzd_id[i]              ),
        .v_hzd_num                (v_hzd_num[i]             ),
        .v_hzd_addr               (v_hzd_addr[i]            ),
        .v_wr_data_buf_done       (v_wr_data_buf_done[i]    ),
        .v_wr_data_ram_done       (v_wr_data_ram_done[i]    ),
        .v_rd_data_ram_done       (v_rd_data_ram_done[i]    ),
        .v_pre_alloc_vld          (v_pre_alloc_vld[i]       ),
        .v_pre_alloc_rdy          (v_pre_alloc_rdy[i]       ),
        .v_b_vld                  (v_b_vld[i]               ),
        .v_b_rdy                  (v_b_rdy[i]               ),
        .v_b_pld                  (v_b_pld[i]               ),
        .v_arb_req                (v_arb_req[i]             ),
        .v_arb_op_is_rd           (v_arb_op_is_rd[i]        ),
        .v_arb_req_pld            (v_arb_req_pld[i]         ),
        .v_arb_ack                (v_arb_ack[i]             ),
        .v_release_en             (v_release_en[i]          ),
        .release_en               (v_release_en             ) 
    );
end
endgenerate

ocm_rob_pre_alloc u_rob_pre_alloc(
    .v_in_vld (v_pre_alloc_vld  ),
    .v_in_rdy (v_pre_alloc_rdy  ),
    .out_vld  (rob_id_vld       ),
    .out_rdy  (rob_id_rdy       ),
    .out_id   (rob_id           ) 
);

ocm_rob_arbiter u_ocm_rob_arbiter(
    .clk                    (clk                ),
    .rst_n                  (rst_n              ),
    .v_arb_req              (v_arb_req          ),
    .v_arb_ack              (v_arb_ack          ),
    .v_arb_req_is_rd        (v_arb_op_is_rd     ),
    .v_req_pld              (v_arb_req_pld      ),
    .credit                 (credit             ),
    .ack_read_data_buf_vld  (read_data_buf_en   ),
    .ack_read_data_ram_vld  (read_data_ram_en   ),
    .ack_read_data_buf_pld  (read_data_buf_pld  ),
    .ack_read_data_ram_pld  (read_data_ram_pld  ),
    .v_age                  (v_age              )            
); 
endmodule 