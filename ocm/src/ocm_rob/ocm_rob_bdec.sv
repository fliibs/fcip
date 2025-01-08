module ocm_rob_bdec
import ocm_package::*;
(
    input  logic [OCM_ROB_ENTRY_DEPTH-1:0]    v_b_vld                         ,
    output logic [OCM_ROB_ENTRY_DEPTH-1:0]    v_b_rdy                         , 
    input  pack_ocm_b_pld                     v_b_pld[OCM_ROB_ENTRY_DEPTH-1:0],
    output logic                              bvld                            ,
    input  logic                              brdy                            ,
    output pack_ocm_b_pld                     bpld                            
);

logic [OCM_ROB_ENTRY_DEPTH-1:0] v_b_rdy_oh;

cmn_lead_one #(
    .ENTRY_NUM(OCM_ROB_ENTRY_DEPTH))
u_lead_one(
    .v_entry_vld    (v_b_vld    ),
    .v_free_idx_oh  (v_b_rdy_oh ),
    .v_free_idx_bin (),
    .v_free_vld     (bvld       )    
);

assign v_b_rdy     = brdy ? v_b_rdy_oh : {OCM_ROB_ENTRY_DEPTH{1'b0}};
always_comb begin
    bpld.bid   = {OCM_AXI_ID_WIDTH{1'b0}} ;
    bpld.bresp = {2{1'b0}}                  ;
    for(int i=0;i<OCM_ROB_ENTRY_DEPTH;i++) begin
        if(v_b_rdy_oh[i]) begin
            bpld=v_b_pld[i];
        end
    end
end

endmodule