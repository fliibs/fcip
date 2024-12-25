module ocm_data_xbar
import ocm_package::*;
(
    input  logic                                    clk                                     ,
    input  logic                                    rst_n                                   ,
    input  logic                                    wr_data_ram_en                          ,
    input  pack_ocm_data_ram_wr_pld                 wr_data_ram_pld                         ,
    input  logic                                    rd_data_ram_en                          ,
    input  pack_ocm_arb_ack_pld                     rd_data_ram_pld                         ,
    output logic [OCM_DATA_RAM_NUM-1:0]             data_ram_en                             ,
    output logic [OCM_DATA_RAM_NUM-1:0]             data_ram_wr                             ,
    output logic [OCM_DATA_RAM_NUM-1:0]             data_ram_rd                             ,
    output logic [OCM_L_DATA_RAM_ADDR_WIDTH-1:0]    data_ram_addr   [OCM_DATA_RAM_NUM-1:0]  ,
    output logic [OCM_L_DATA_RAM_DATA_WIDTH-1:0]    data_ram_din    [OCM_DATA_RAM_NUM-1:0]  ,
    input  logic [OCM_L_DATA_RAM_DATA_WIDTH-1:0]    data_ram_dout   [OCM_DATA_RAM_NUM-1:0]  ,

    output logic [OCM_AXI_RID_WIDTH-1:0]            rid                                     ,
    output logic [OCM_AXI_LEN-1:0]                  rlen                                    ,
    output logic [OCM_AXI_LEN-1:0]                  rlast                                   ,
    output logic                                    wr_data_ram_done                        ,
    output logic [OCM_ROB_ENTRY_WIDTH-1:0]          wr_data_ram_id                          ,
    output logic                                    rd_data_ram_done                        ,
    output logic [OCM_ROB_ENTRY_WIDTH-1:0]          rd_data_ram_id                          ,
    output logic [OCM_DATA_RAM_NUM-1:0]             axi_rd_en                               
);

//================================================================
//===========================internal signals
//================================================================ 
logic [OCM_DATA_RAM_NUM-1:0]            data_buf_wr_part                            ;
logic [OCM_DATA_RAM_NUM-1:0]            data_buf_wr_full                            ;
logic [OCM_DATA_RAM_NUM-1:0]            data_ram_wr_buf                             ;
logic [OCM_L_DATA_RAM_ADDR_WIDTH-1:0]   data_ram_addr_buf                           ;
logic [OCM_L_DATA_RAM_DATA_WIDTH/2-1:0] data_ram_din_buf                            ;
logic [OCM_AXI_LEN-1:0]                 data_ram_msk_buf                            ;      

logic [OCM_DATA_RAM_NUM-1:0]            data_ram_wr_part                            ;
logic [OCM_L_DATA_RAM_ADDR_WIDTH-1:0]   data_ram_addr_part                          ;
logic [OCM_L_DATA_RAM_DATA_WIDTH/2-1:0] data_ram_din_part                           ;
logic [OCM_AXI_LEN-1:0]                 data_ram_msk_part                           ;      

logic [OCM_L_DATA_RAM_DATA_WIDTH-1:0]   data_ram_din_full    [OCM_DATA_RAM_NUM-1:0] ;

//================================================================
//===========================buffer for partial write
//================================================================ 
genvar i;
generate for(i=0;i<OCM_DATA_RAM_NUM;i++) begin
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            data_ram_wr_buf[i]   <= 1'b0                ; 
            data_ram_wr_part[i]  <= 1'b0                ;
        end
        else begin
            data_ram_wr_buf[i]   <= data_buf_wr_part[i] ;
            data_ram_wr_part[i]  <= data_ram_wr_buf[i]  ;
        end
    end
end
endgenerate

always@(posedge clk) begin
    for(int j=0;j<OCM_AXI_LEN;j++) begin
        if(wr_data_ram_pld.data_msk[j])
            data_ram_din_buf <= wr_data_ram_pld.data[j*OCM_AXI_DATA_WIDTH-1:(j-1)*OCM_AXI_DATA_WIDTH];
    end
    data_ram_din_part <= data_ram_din_buf ;
end

always@(posedge clk) begin
    data_ram_msk_buf    <= wr_data_ram_pld.data_msk ;
    data_ram_msk_part   <= data_ram_msk_buf         ;
end

always@(posedge clk) begin
    data_ram_addr_buf       <= wr_data_ram_pld.data_ram_addr;
    data_ram_addr_part      <= data_ram_addr_buf            ;
end
//================================================================
//===========================Behavior
//================================================================ 
integer j;
generate for(i=0;i<OCM_DATA_RAM_NUM;i++) begin
    for(j=0;j<OCM_AXI_LEN;j++) begin
        assign data_ram_din_full[i][j*OCM_AXI_DATA_WIDTH-1:(j-1)*OCM_AXI_DATA_WIDTH] =  data_ram_msk_part[j] ? data_ram_din_part[i] : data_ram_dout[i][j*OCM_AXI_DATA_WIDTH-1:(j-1)*OCM_AXI_DATA_WIDTH];
    end
    assign data_buf_wr_part[i]  = (wr_data_ram_pld.data_ram_num==i) && (~&wr_data_ram_pld.data_msk)  && wr_data_ram_en  ;
    assign data_buf_wr_full[i]  = (wr_data_ram_pld.data_ram_num==i) && (&wr_data_ram_pld.data_msk)   && wr_data_ram_en  ;
end
endgenerate

generate for(i=0;i<OCM_DATA_RAM_NUM;i++) begin
    assign axi_rd_en[i]         = (rd_data_ram_pld.data_ram_num==i) && rd_data_ram_en                                   ;
    assign data_ram_wr[i]       = data_buf_wr_full[i] || data_ram_wr_part[i]                                            ;
    assign data_ram_rd[i]       = data_buf_wr_part[i] || axi_rd_en[i]                                                   ;
    assign data_ram_din[i]      = data_ram_wr_part[i] ?  data_ram_din_full[i] : wr_data_ram_pld.data                    ;
    always_comb begin
        if(axi_rd_en[i])                data_ram_addr[i] = rd_data_ram_pld.data_ram_addr ;
        else if(data_buf_wr_full[i])    data_ram_addr[i] = wr_data_ram_pld.data_ram_addr ;
        else if(data_ram_wr_part[i] )   data_ram_addr[i] = data_ram_addr_part[i]         ;
    end
end

endgenerate 

assign data_ram_en      = data_ram_wr | data_ram_rd ;
assign rid              = rd_data_ram_pld.axid      ;
assign rlen             = rd_data_ram_pld.len       ; 
assign rlast            = rd_data_ram_pld.rlast     ;
assign wr_data_ram_done = wr_data_ram_en            ;
assign rd_data_ram_done = rd_data_ram_en            ;

assign wr_data_ram_id   = wr_data_ram_pld.awid      ;
assign rd_data_ram_id   = rd_data_ram_pld.axid      ;
endmodule