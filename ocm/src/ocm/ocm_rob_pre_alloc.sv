module ocm_rob_pre_alloc
    import ocm_package::*;    
(
    input  logic [OCM_ROB_ENTRY_NUM-1:0]    v_in_vld            ,
    output logic [OCM_ROB_ENTRY_NUM-1:0]    v_in_rdy            ,
    output logic                            out_vld             ,
    input  logic                            out_rdy             ,
    output logic [OCM_ROB_ENTRY_WIDTH-1:0]  out_id  
);
    logic [OCM_ROB_ENTRY_WIDTH-1:0]             free_rob_id     ;
    logic [OCM_ROB_ENTRY_NUM-1:0]               free_rob_ohot   ;
    logic                                       free_rob_vld    ;

cmn_lead_one #(
    .ENTRY_NUM (OCM_ROB_ENTRY_NUM)
) u_cmn_lead_one(
    .v_entry_vld    (v_in_vld           ),
    .v_free_idx_oh  (free_rob_ohot      ),
    .v_free_idx_bin (free_rob_id        ),
    .v_free_vld     (free_rob_vld       )
);

assign v_in_rdy     = free_rob_vld && out_rdy ? free_rob_ohot : {OCM_ROB_ENTRY_NUM{1'b0}};
assign out_vld      = free_rob_vld                                                       ;
endmodule