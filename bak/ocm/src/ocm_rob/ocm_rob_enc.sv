module ocm_rob_enc
import ocm_package::*;
(
    input  logic   [OCM_ROB_ENTRY_DEPTH-1:0]  id_ohot                          ,
    input  pack_ocm_rob_ack_pld               raw_pld                          ,   
    output pack_ocm_rob_ack_pld               enc_pld                             
);
logic  [OCM_ROB_ENTRY_WIDTH-1:0]  id_idx;
cmn_onehot2bin #(
    .ONEHOT_WIDTH(OCM_ROB_ENTRY_DEPTH)
)u_rob_id_ohot2bin (
    .onehot_in(id_ohot),
    .bin_out  (id_idx)
);
assign enc_pld.opcode     = raw_pld.opcode      ;
assign enc_pld.ram_addr   = raw_pld.ram_addr    ;
assign enc_pld.ram_num    = raw_pld.ram_num     ; 
assign enc_pld.rob_id     = id_idx              ;  
assign enc_pld.ram_bps_pld= raw_pld.ram_bps_pld ;
endmodule