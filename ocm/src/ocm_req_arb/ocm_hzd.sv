module ocm_hzd
    import ocm_package::*;
(
    input  logic [OCM_ROB_ENTRY_WIDTH-1:0]          v_hzd_id [OCM_ROB_ENTRY_DEPTH-1:0]            ,
    input  logic [OCM_DATA_RAM_ADDR_WIDTH-1:0]      v_hzd_addr[OCM_ROB_ENTRY_DEPTH-1:0]           ,
    input  logic [OCM_DATA_RAM_BANK_NUM_WIDTH-1:0]  v_hzd_data_ram_num[OCM_ROB_ENTRY_DEPTH-1:0]   ,
    input  logic [OCM_ROB_ENTRY_DEPTH-1:0]          v_hzd_addr_en                                 ,
    input  logic [OCM_ROB_ENTRY_DEPTH-1:0]          v_hzd_id_en                                   ,
    input  pack_ocm_rob_req_pld                     arb_ack_pld                                   ,
    output logic [OCM_ROB_ENTRY_DEPTH-1:0]          id_hzd                                        ,
    output logic [OCM_ROB_ENTRY_DEPTH-1:0]          addr_hzd                                
);

//TODO: addr hzd is not accurate ,should len be included to check addr hzd?
genvar i;
generate for(i=0;i<OCM_ROB_ENTRY_DEPTH;i++) begin
    // assign addr_hzd[i]= ((v_hzd_data_ram_num[i]==arb_ack_pld.ram_num) && (v_hzd_addr[i] == arb_ack_pld.ram_addr) && v_hzd_addr_en[i] ) ? 1'b1 : 1'b0 ;
    assign addr_hzd[i]=  (v_hzd_addr[i] == arb_ack_pld.ram_addr) && v_hzd_addr_en[i]  ? 1'b1 : 1'b0 ;
end
endgenerate

generate for(i=0;i<OCM_ROB_ENTRY_DEPTH;i++) begin
    assign id_hzd[i]  = ((v_hzd_id[i]==arb_ack_pld.id) && v_hzd_id_en[i]) ? 1'b1 : 1'b0 ;
end
endgenerate

endmodule