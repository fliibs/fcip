module cmn_rob_list_prealloc
#(
    parameter  integer unsigned ROB_ENTRY_DEPTH = 16                      ,
    localparam integer unsigned ROB_ENTRY_WIDTH = $clog2(ROB_ENTRY_DEPTH) ,
    parameter  integer unsigned REQ_NUM         = 4
)(
    input  logic [ROB_ENTRY_DEPTH-1:0]      v_in_vld                ,
    output logic [ROB_ENTRY_DEPTH-1:0]      v_in_rdy                ,
    output logic [REQ_NUM-1:0]              out_vld                 ,
    input  logic [REQ_NUM-1:0]              out_rdy                 ,
    output logic [ROB_ENTRY_WIDTH-1:0]      out_pld  [REQ_NUM-1:0]  
);
logic  [ROB_ENTRY_DEPTH-1:0] rob_id_req_oh  [REQ_NUM-1:0]               ;
logic  [ROB_ENTRY_WIDTH-1:0] rob_id_req_idx [REQ_NUM-1:0]               ;
logic  [REQ_NUM-1:0]         rob_req_vld                                ;
logic  [REQ_NUM-1:0]         rob_id_req_oh_re[ROB_ENTRY_DEPTH-1:0]      ;

logic  [ROB_ENTRY_DEPTH-1:0] rob_id_oh                                  ;
logic  [REQ_NUM-1:0]         out_mask                                   ;

cmn_list_lead_one #(
    .ENTRY_NUM(ROB_ENTRY_DEPTH),
    .REQ_NUM  (REQ_NUM        )
)U_cmn_list_lead_one_rev(
    .v_entry_vld    (v_in_vld       ),
    .v_free_idx_oh  (rob_id_req_oh  ),
    .v_free_idx_bin (rob_id_req_idx ),
    .v_free_vld     (rob_req_vld    )
);

genvar i,j;
generate for(i=0;i<ROB_ENTRY_DEPTH;i++) begin
    for (j=0;j<REQ_NUM;j++) begin
        assign rob_id_req_oh_re[i][j] =  rob_id_req_oh[j][i] ;
    end
    assign rob_id_oh[i] = |rob_id_req_oh_re[i];
end
endgenerate

generate for(i=0;i<REQ_NUM;i++) begin
    assign out_mask[i] = out_rdy[i];
end
endgenerate

assign v_in_rdy =  |(out_mask & rob_req_vld) ? rob_id_oh :{ROB_ENTRY_DEPTH{1'b0}}  ; 
assign out_vld  = rob_req_vld                                                      ;
assign out_pld  = rob_id_req_idx                                                   ;
endmodule