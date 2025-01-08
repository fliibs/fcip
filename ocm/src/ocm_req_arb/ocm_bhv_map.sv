module ocm_bhv_map
import ocm_package::*;
(
    input  pack_ocm_req_arb_ack_pld     pld_in      ,
    output pack_ocm_rob_req_pld         rob_req_pld   
);
//==================================
//===========internal signals
//==================================
logic [OCM_AXI_LEN_OH_WIDTH-1:0]            len_ohot         ;
logic [OCM_SPLIT_DATA_B_WIDTH-1:0]          aligned_addr     ;
logic [$clog2(OCM_DATA_RAM_SPLIT_NUM)-1:0]  split_addr       ;
logic [OCM_AXI_LEN_OH_WIDTH-1:0]            axi_mask_len     ;

//==================================
//===========behavior map
//==================================
cmn_bin2onehot#(
    .BIN_WIDTH   (OCM_AXI_LEN_WIDTH     ),
    .ONEHOT_WIDTH(OCM_AXI_LEN_OH_WIDTH  )
)u_cmn_bin2onehot(
    .bin_in     (pld_in.axpld.len ),
    .onehot_out (len_ohot   )
);

genvar i ;
generate for(i=0;i<OCM_AXI_LEN_OH_WIDTH;i++) begin
    if(i==OCM_AXI_LEN_OH_WIDTH-1)
    assign axi_mask_len[i] = len_ohot[i]                      ;
    else
    assign axi_mask_len[i] = len_ohot[i] || axi_mask_len[i+1] ;
end
endgenerate

assign {rob_req_pld.ram_addr,rob_req_pld.ram_num,split_addr,aligned_addr}= pld_in.axpld.addr;

generate for(i=0;i<OCM_ROB_MASK_WIDTH;i++) begin
    assign rob_req_pld.len_msk[i] = axi_mask_len[i/2];
end
endgenerate

assign rob_req_pld.opcode  = pld_in.opcode                                ;
assign rob_req_pld.resp    = |aligned_addr || split_addr ? 2'b10 : 2'b00  ;
assign rob_req_pld.id      = pld_in.axpld.id                              ;
assign rob_req_pld.size    = pld_in.axpld.size                            ;
assign rob_req_pld.burst   = pld_in.axpld.burst                           ; 

endmodule