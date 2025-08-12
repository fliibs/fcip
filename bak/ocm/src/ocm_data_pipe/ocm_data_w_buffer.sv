module ocm_data_w_buffer
import ocm_package::*;
(
    input  logic                                        clk                                     ,
    input  logic                                        rst_n                                   ,
    input  logic                                        wvld                                    ,
    output logic                                        wrdy                                    ,
    input  pack_ocm_w_pld                               wpld                                    ,
    output logic                                        wfifo_out_rdy                           ,
    input  logic                                        wfifo_out_vld                           ,
    input  logic [OCM_ROB_ENTRY_WIDTH-1:0]              wfifo_out_data                          ,
    input  logic                                        rd_data_buf_en                          ,
    input  pack_ocm_rob_ack_pld                         rd_data_buf_pld                         ,                                                                              
    output logic                                        wr_data_ram_en                          ,
    output pack_ocm_rob_ack_pld                         wr_data_ram_pld                         ,
    output logic [OCM_DATA_RAM_UNENC_DATA_WIDTH-1:0]    wr_data_ram_data                        ,
    output logic                                        wr_data_buf_done                        ,
    output logic [OCM_ROB_ENTRY_WIDTH-1:0]              wr_data_buf_id                          ,
    //ram interface
    output logic [OCM_AXI_DATA_WIDTH-1:0]               ram_din    [OCM_DATA_BUF_RAM_NUM-1:0]   ,
    output logic [OCM_ROB_ENTRY_WIDTH-1:0]              ram_wraddr [OCM_DATA_BUF_RAM_NUM-1:0]   ,
    output logic [OCM_ROB_ENTRY_WIDTH-1:0]              ram_rdaddr [OCM_DATA_BUF_RAM_NUM-1:0]   ,
    output logic                                        ram_wren   [OCM_DATA_BUF_RAM_NUM-1:0]   ,                
    output logic                                        ram_rden   [OCM_DATA_BUF_RAM_NUM-1:0]   ,                
    input  logic [OCM_AXI_DATA_WIDTH-1:0]               ram_dout   [OCM_DATA_BUF_RAM_NUM-1:0]    
);

//=============================================
//=================internal signals
//=============================================
logic                               w_hsk                                                       ;
logic                               w_last_hsk                                                  ;
logic                               w_first_hsk                                                 ;
logic                               w_idle                                                      ;
logic [OCM_ROB_ENTRY_WIDTH-1:0]     w_rob_id_buf                                                ;
logic [1:0]                         w_strb_cnt  [OCM_ROB_ENTRY_WIDTH-1:0]                       ;
logic [3:0]                         w_strb_cnt_oh                                               ; 
logic [1:0]                         r_buf_cnt   [OCM_ROB_ENTRY_WIDTH-1:0]                       ;
logic [1:0]                         r_buf_cnt_buf                                               ;
logic [OCM_AXI_DATA_WIDTH-1:0]      ram_dout_buf[OCM_DATA_BUF_RAM_NUM-1:0]                      ; 

logic [OCM_DATA_RAM_SPLIT_NUM-1:0]  w_msk                                                       ;
logic [OCM_DATA_RAM_SPLIT_NUM-1:0]  w_msk_buf  [OCM_ROB_ENTRY_WIDTH-1:0][OCM_AXI_LEN_MAX-1:0]   ;


//=============================================
//=================wfifo IO
//=============================================
assign w_hsk        = wvld  && wrdy            ;
assign w_last_hsk   = w_hsk && wpld.wlast      ;
assign w_first_hsk  = w_hsk && w_idle          ;

always_ff@(posedge clk or negedge rst_n) begin
    if(!rst_n)              w_idle <= 1'b1     ;
    else if(w_hsk)          w_idle <= 1'b0     ;
    else if(w_last_hsk)     w_idle <= 1'b1     ; 
end

assign wfifo_out_rdy = w_hsk && !w_idle        ;
assign wrdy          = wfifo_out_vld           ;

//=============================================
//=================wr_data_buf_done
//=============================================
always_ff@(posedge clk) begin
    if(w_hsk)       w_rob_id_buf <=  wfifo_out_data             ;
end     
assign wr_data_buf_done = wvld && wrdy && wpld.wlast            ;
assign wr_data_buf_id   = w_idle ? wfifo_out_data : w_rob_id_buf;

//=============================================
//=================ram IF
//=============================================
genvar i;
cmn_bin2onehot#(
    .BIN_WIDTH   (2),
    .ONEHOT_WIDTH(4)
)u_strb_cnt_bin2ohot(
    .bin_in      (w_strb_cnt[wr_data_buf_id]),
    .onehot_out  (w_strb_cnt_oh             )
);

generate for(i=0;i<OCM_DATA_BUF_RAM_NUM;i++) begin
    assign ram_din[i]     = wpld.wdata               ;
    assign ram_wraddr[i]  = wfifo_out_data           ;
    assign ram_rdaddr[i]  = rd_data_buf_pld.rob_id   ;
    assign ram_rden[i]    = rd_data_buf_en           ;
    assign ram_wren[i]    = w_strb_cnt_oh[i]         ;
end
endgenerate

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        for(int j=0;j<OCM_ROB_ENTRY_WIDTH;j++) begin
            w_strb_cnt[j] <= {2{1'b0}};
        end
    end
    else if(w_first_hsk)  w_strb_cnt[wr_data_buf_id] <= 2'b01   ;
    else if(w_last_hsk)   w_strb_cnt[wr_data_buf_id] <= 2'b00   ;
    else                  w_strb_cnt[wr_data_buf_id] <= 2'b10   ;
end

generate for(i=0;i<OCM_DATA_RAM_SPLIT_NUM;i++) begin
    assign w_msk[i] = &wpld.wdata[OCM_DATA_RAM_SPLIT_DATA_WIDTH*(i+1)-1:OCM_DATA_RAM_SPLIT_DATA_WIDTH*i];
end
endgenerate

generate for(i=0;i<OCM_DATA_BUF_RAM_NUM;i++) begin
    always_ff@(posedge clk) begin
        if(w_strb_cnt_oh[i])
            w_msk_buf[i][wr_data_buf_id] <= w_msk;
    end
end
endgenerate

generate for(i=0;i<OCM_DATA_RAM_SPLIT_NUM;i++) begin
    always_ff@(posedge clk) begin
        ram_dout_buf[i] <= ram_dout[i];
    end
end
endgenerate
//=============================================
//=================Xbar IF Dec
//=============================================
always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)                  wr_data_ram_en <= 1'b0              ;
    else                        wr_data_ram_en <= rd_data_buf_en    ;
end

always_ff@(posedge clk) begin
    wr_data_ram_pld.ram_addr             <= rd_data_buf_pld.ram_addr         ;
    wr_data_ram_pld.ram_num              <= rd_data_buf_pld.ram_num          ;
    wr_data_ram_pld.rob_id               <= rd_data_buf_pld.rob_id           ;
    wr_data_ram_pld.ram_bps_pld.id       <= rd_data_buf_pld.ram_bps_pld.id   ;
    wr_data_ram_pld.ram_bps_pld.last     <= rd_data_buf_pld.ram_bps_pld.last ;
    wr_data_ram_pld.ram_bps_pld.resp     <= rd_data_buf_pld.ram_bps_pld.resp ;
end
assign wr_data_ram_pld.ram_bps_pld.data_msk = ram_dout_buf[r_buf_cnt_buf]                       ;
assign wr_data_ram_data                     = w_msk_buf[wr_data_ram_pld.rob_id][r_buf_cnt_buf]  ;
assign wr_data_ram_pld.opcode               = 2'b10 ;

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        for(int j=0;j<OCM_ROB_ENTRY_WIDTH;j++) begin
            r_buf_cnt[j] <= {2{1'b0}};
        end
    end
    else if(wr_data_ram_en && rd_data_buf_pld.ram_bps_pld.last)  r_buf_cnt[wr_data_buf_id]         <= 2'b00                                      ;
    else if(wr_data_ram_en )                                     r_buf_cnt[rd_data_buf_pld.rob_id] <= r_buf_cnt[rd_data_buf_pld.rob_id] + 2'b01  ;
end

always_ff@(posedge clk) begin
    r_buf_cnt_buf <= r_buf_cnt[rd_data_buf_pld.rob_id];
end

endmodule