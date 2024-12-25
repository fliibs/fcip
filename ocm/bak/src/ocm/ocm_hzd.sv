module ocm_hzd
    import ocm_package::*;
(
    input  logic [OCM_ROB_ENTRY_WIDTH-1:0]          v_hzd_id [OCM_ROB_ENTRY_NUM-1:0]            ,
    input  logic [OCM_L_DATA_RAM_DATA_WIDTH-1:0]    v_hzd_addr[OCM_ROB_ENTRY_NUM-1:0]           ,
    input  logic [OCM_DATA_RAM_DEPTH-1:0]           v_hzd_data_ram_num[OCM_ROB_ENTRY_NUM-1:0]   ,
    input  logic [OCM_ROB_ENTRY_NUM-1:0]            v_hzd_en                                    ,
    input  logic [OCM_ROB_ENTRY_WIDTH-1:0]          req_arb_id                                  ,
    input  logic [OCM_AXI_ADDR_WIDTH-1:0]           req_arb_addr                                ,
    output logic [OCM_ROB_ENTRY_NUM-1:0]            id_hzd                                      ,
    output logic [OCM_ROB_ENTRY_NUM-1:0]            addr_hzd                                
);
genvar i;
generate for(i=0;i<OCM_ROB_ENTRY_NUM;i++) begin
    assign addr_hzd[i]= (v_hzd_data_ram_num[i]==req_arb_addr[OCM_AXI_ADDR_WIDTH-1:OCM_AXI_ADDR_WIDTH-OCM_DATA_RAM_DEPTH] && v_hzd_addr[i]==req_arb_addr[OCM_L_DATA_RAM_DATA_WIDTH-1:0])? 1'b1 : 1'b0 ;
end
endgenerate

generate for(i=0;i<OCM_ROB_ENTRY_NUM;i++) begin
    assign id_hzd[i]  = (v_hzd_id[i]==req_arb_id) ? 1'b1 : 1'b0;
end
endgenerate

endmodule