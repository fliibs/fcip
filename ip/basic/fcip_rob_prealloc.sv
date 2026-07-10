module fcip_rob_prealloc #(
    parameter integer unsigned ROB_ENTRY_NUM   = 32,
    parameter integer unsigned ROB_ENTRY_WIDTH = $clog2(ROB_ENTRY_NUM)
)(
    input  logic [ROB_ENTRY_NUM-1:0]        v_in_vld            ,
    output logic [ROB_ENTRY_NUM-1:0]        v_in_rdy            ,
    output logic                            out_vld             ,
    input  logic                            out_rdy             ,
    output logic [ROB_ENTRY_WIDTH-1:0]      out_pld             ,
    output logic [ROB_ENTRY_NUM-1:0]        out_pld_oh          
);
logic [ROB_ENTRY_WIDTH-1:0]                 rob_id     ;
logic [ROB_ENTRY_NUM-1:0]                   rob_oh     ;
logic                                       rob_vld    ;

fcip_lead_one #(
    .ENTRY_NUM (ROB_ENTRY_NUM)
) u_cmn_lead_one(
    .v_entry_vld    (v_in_vld           ),
    .v_free_idx_oh  (rob_oh        ),
    .v_free_idx_bin (rob_id        ),
    .v_free_vld     (rob_vld       )
);

assign v_in_rdy     = rob_vld && out_rdy ? rob_oh : {ROB_ENTRY_NUM{1'b0}} ;
assign out_vld      = rob_vld                                             ;
assign out_pld      = rob_id                                              ;
assign out_pld_oh   = rob_vld && out_rdy ? rob_oh : {ROB_ENTRY_NUM{1'b0}} ;
endmodule