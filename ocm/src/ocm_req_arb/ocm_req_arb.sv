module ocm_req_arb
import ocm_package::*;
(
    input  logic                                    clk                                         ,
    input  logic                                    rst_n                                       ,
    input  logic                                    arvld                                       ,
    output logic                                    arrdy                                       ,
    input  pack_ocm_ax_pld                          arpld                                       ,
    input  logic                                    awvld                                       ,
    output logic                                    awrdy                                       ,
    input  pack_ocm_ax_pld                          awpld                                       ,
    //rob                             
    input  logic [OCM_ROB_ENTRY_WIDTH-1:0]          rob_pre_alloc_aw_id                         ,
    input  logic                                    rob_pre_alloc_aw_vld                        ,
    output logic                                    rob_pre_alloc_aw_rdy                        ,
    input  logic [OCM_ROB_ENTRY_WIDTH-1:0]          rob_pre_alloc_ar_id                         ,
    input  logic                                    rob_pre_alloc_ar_vld                        ,
    output logic                                    rob_pre_alloc_ar_rdy                        ,
    //output to hzd check and behavior map                          
    output pack_ocm_rob_req_pld                     rob_req_pld                                 ,
    output logic                                    rob_req_en                                  ,
    output logic [OCM_ROB_ENTRY_WIDTH-1:0]          rob_req_id                                  ,
    //hzd      
    input  logic [OCM_ROB_ENTRY_WIDTH-1:0]          v_hzd_id [OCM_ROB_ENTRY_DEPTH-1:0]          ,
    input  logic [OCM_DATA_RAM_ADDR_WIDTH-1:0]      v_hzd_addr[OCM_ROB_ENTRY_DEPTH-1:0]         ,
    input  logic [OCM_DATA_RAM_BANK_NUM_WIDTH-1:0]  v_hzd_num[OCM_ROB_ENTRY_DEPTH-1:0]          ,
    input  logic [OCM_ROB_ENTRY_DEPTH-1:0]          v_hzd_addr_en                               ,
    input  logic [OCM_ROB_ENTRY_DEPTH-1:0]          v_hzd_id_en                                 ,
    output logic [OCM_ROB_ENTRY_DEPTH-1:0]          id_hzd                                      ,
    output logic [OCM_ROB_ENTRY_DEPTH-1:0]          addr_hzd                                    ,                          
    //init
    input  logic                                init                                        ,
    output logic                                init_done           
);
//============================================
//=====================internal signals
//============================================
logic [OCM_ROB_ENTRY_WIDTH-1:0]     rob_aw_out_id   ;
logic                               rob_aw_out_vld  ;
logic                               rob_aw_out_rdy  ;
logic [OCM_ROB_ENTRY_WIDTH-1:0]     rob_ar_out_id   ;
logic                               rob_ar_out_vld  ;
logic                               rob_ar_out_rdy  ;

logic                               init_vld        ;
logic                               init_rdy        ;
pack_ocm_ax_pld                     init_pld        ;
logic [OCM_INIT_ADDR_WIDTH:0]       init_rgn        ;

logic                               arb_ar_vld      ;
logic                               arb_ar_rdy      ;
logic                               arb_aw_vld      ;
logic                               arb_aw_rdy      ;

pack_ocm_req_arb_ack_pld            arb_ack_pld     ;           

//============================================
//=====================INIT
//============================================
ocm_req_init_agt u_ocm_req_init_agt(
    .clk          (clk          ),
    .rst_n        (rst_n        ),
    .init         (init         ),
    .rob_ar_out_id(rob_ar_out_id),
    .init_vld     (init_vld     ),
    .init_rdy     (init_rdy     ),
    .init_pld     (init_pld     ),
    .init_done    (init_done    ),
    .init_rgn     (init_rgn     )
);

//============================================
//=====================AWFIFO
//============================================
cmn_vrp_reg_fifo#(
    .PLD_TYPE  (logic [OCM_ROB_ENTRY_WIDTH-1:0]),
    .ADDR_WIDTH(OCM_REQ_ARB_DEPTH              )
)u_rob_aw_fifo(
    .clk    (clk                    ),
    .rst_n  (rst_n                  ),
    .in_vld (rob_pre_alloc_aw_vld   ), 
    .in_rdy (rob_pre_alloc_aw_rdy   ), 
    .in_pld (rob_pre_alloc_aw_id    ), 
    .out_vld(rob_aw_out_vld         ), 
    .out_rdy(rob_aw_out_rdy         ), 
    .out_pld(rob_aw_out_id          )  
);

assign rob_aw_out_rdy =  arb_aw_rdy ;

//============================================
//=====================ARFIFO
//============================================
cmn_vrp_reg_fifo#(
    .PLD_TYPE  (logic [OCM_ROB_ENTRY_WIDTH-1:0]),
    .ADDR_WIDTH(OCM_REQ_ARB_DEPTH              )
)u_rob_ar_fifo(
    .clk    (clk                    ),
    .rst_n  (rst_n                  ),
    .in_vld (rob_pre_alloc_ar_vld   ), 
    .in_rdy (rob_pre_alloc_ar_rdy   ), 
    .in_pld (rob_pre_alloc_ar_id    ), 
    .out_vld(rob_ar_out_vld         ), 
    .out_rdy(rob_ar_out_rdy         ), 
    .out_pld(rob_ar_out_id          )  
);
assign rob_ar_out_rdy = arb_ar_rdy  || init_rdy ;
//============================================
//=====================Arbiter
//============================================
cmn_multi_fix_arb u_cmn_multi_fix_arb(
    .s_vld_1th_prio (arb_aw_vld ),
    .s_rdy_1th_prio (arb_aw_rdy ),
    .s_pld_1th_prio (awpld      ),
    .s_vld_2th_prio (arb_ar_vld ),
    .s_rdy_2th_prio (arb_ar_rdy ),
    .s_pld_2th_prio (arpld      ),
    .s_vld          (init_vld   ),
    .s_rdy          (init_rdy   ),
    .s_pld          (init_pld   ),
    .m_vld          (rob_req_en ),
    .m_rdy          (1'b1       ),
    .m_pld          (arb_ack_pld)
);
assign arb_aw_vld = rob_aw_out_vld && awvld && (awpld.addr[OCM_AXI_ADDR_WIDTH-1:OCM_AXI_ADDR_WIDTH-OCM_INIT_ADDR_WIDTH] < init_rgn);       
assign arb_ar_vld = rob_ar_out_vld && arvld && (arpld.addr[OCM_AXI_ADDR_WIDTH-1:OCM_AXI_ADDR_WIDTH-OCM_INIT_ADDR_WIDTH] < init_rgn); 
assign arrdy      = arb_ar_rdy                      ;
assign awrdy      = arb_aw_rdy                      ;

assign rob_req_id  = arb_aw_vld ? rob_aw_out_id :rob_ar_out_id ;

//============================================
//=====================Behavior Map
//============================================
ocm_bhv_map u_ocm_aw_bhv_map(
    .pld_in     (arb_ack_pld),
    .rob_req_pld(rob_req_pld)   
);

//============================================
//=====================hzd check
//============================================
ocm_hzd u_ocm_hzd(
    .v_hzd_id          (v_hzd_id           ),
    .v_hzd_addr        (v_hzd_addr         ),
    .v_hzd_data_ram_num(v_hzd_num          ),
    .v_hzd_addr_en     (v_hzd_addr_en      ),
    .v_hzd_id_en       (v_hzd_id_en        ),
    .arb_ack_pld       (rob_req_pld        ),
    .id_hzd            (id_hzd             ),
    .addr_hzd          (addr_hzd           )
);
endmodule