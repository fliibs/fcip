module ocm_data_sram
import ocm_package::*;
(
    input  logic                                                                    clk                                        ,
    input  logic [OCM_AXI_DATA_WIDTH-1:0]                                           dp_ram_din    [OCM_DATA_BUF_RAM_NUM-1:0]   ,
    input  logic [OCM_ROB_ENTRY_WIDTH-1:0]                                          dp_ram_wraddr [OCM_DATA_BUF_RAM_NUM-1:0]   ,
    input  logic [OCM_ROB_ENTRY_WIDTH-1:0]                                          dp_ram_rdaddr [OCM_DATA_BUF_RAM_NUM-1:0]   ,
    input  logic                                                                    dp_ram_wren   [OCM_DATA_BUF_RAM_NUM-1:0]   ,
    input  logic                                                                    dp_ram_rden   [OCM_DATA_BUF_RAM_NUM-1:0]   ,
    output logic [OCM_AXI_DATA_WIDTH-1:0]                                           dp_ram_dout   [OCM_DATA_BUF_RAM_NUM-1:0]   ,
    input  logic [OCM_DATA_RAM_SPLIT_NUM-1:0] [OCM_DATA_RAM_DATA_WIDTH-1:0]         sp_ram_din    [OCM_DATA_RAM_BANK_NUM-1:0]  ,
    input  logic [OCM_DATA_RAM_SPLIT_NUM-1:0]                                       sp_ram_en     [OCM_DATA_RAM_BANK_NUM-1:0]  ,
    input  logic [OCM_DATA_RAM_SPLIT_NUM-1:0]                                       sp_ram_wr     [OCM_DATA_RAM_BANK_NUM-1:0]  ,
    input  logic [OCM_DATA_RAM_SPLIT_NUM-1:0] [OCM_DATA_RAM_ADDR_WIDTH-1:0]         sp_ram_addr   [OCM_DATA_RAM_BANK_NUM-1:0]  ,
    output logic [OCM_DATA_RAM_SPLIT_NUM-1:0] [OCM_DATA_RAM_DATA_WIDTH-1:0]         sp_ram_dout   [OCM_DATA_RAM_BANK_NUM-1:0] 
);

genvar i,j;
generate for(i=0;i<OCM_DATA_BUF_RAM_NUM;i++) begin
    cmn_dual_mem_model #(
        .ADDR_WIDTH(OCM_ROB_ENTRY_WIDTH),  
        .DATA_WIDTH(OCM_AXI_DATA_WIDTH )
    )u_data_buf_sram (
        .clk     (clk               ),
        .rd_en   (dp_ram_rden[i]    ),
        .rd_addr (dp_ram_rdaddr[i]  ),
        .rd_data (dp_ram_dout[i]    ),
        .wr_en   (dp_ram_wren[i]    ),
        .wr_addr (dp_ram_wraddr[i]  ),
        .wr_data (dp_ram_din[i]     )
);
end
endgenerate

generate for(i=0;i<OCM_DATA_RAM_BANK_NUM;i++) begin
    for(j=0;j<OCM_DATA_RAM_SPLIT_NUM;j++) begin
    cmn_single_mem_model #(
        .ADDR_WIDTH(OCM_DATA_RAM_ADDR_WIDTH),
        .DATA_WIDTH(OCM_DATA_RAM_DATA_WIDTH)
    )u_cmn_single_mem_model(
        .clk     (clk               ),
        .en      (sp_ram_en[i][j]   ),
        .addr    (sp_ram_addr[i][j] ),
        .rd_data (sp_ram_dout[i][j] ),
        .wr_data (sp_ram_din[i][j]  ),
        .wr_en   (sp_ram_wr[i][j]   )
    );
    end
end
endgenerate
endmodule
