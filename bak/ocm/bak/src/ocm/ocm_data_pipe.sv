module ocm_data_pipe
import ocm_package::*;
(
    input  logic                               clk                  ,
    input  logic                               clk_x2               ,
    input  logic                               rst_n                ,
    //upstream w channel signals        
    input  logic                               wvld                 ,
    input  pack_ocm_w_pld                      wpld                 ,
    //req_arbiter signals       
    input  logic                               wrdy                 ,
    input  logic [OCM_ROB_ENTRY_WIDTH-1:0]     w_rob_id             ,
    //init signals  
    input  logic                               init_start           ,
    output logic [OCM_AXI_ADDR_WIDTH-1:0]      init_rgn             ,
    //rob signals   
    input  logic                               read_data_buf_en     ,
    input  pack_ocm_arb_ack_pld                read_data_buf_pld    ,
    input  logic                               read_data_ram_en     ,
    input  pack_ocm_arb_ack_pld                read_data_ram_pld    ,

    //r channel 
    output logic                               rvld                 ,
    output pack_ocm_r_pld                      rpld                 ,
    input  logic                               rrdy                 ,
    //ack   
    output logic                               wr_data_buf_done     ,
    output logic [OCM_ROB_ENTRY_WIDTH-1:0]     wr_data_buf_id       ,
    output logic                               wr_data_ram_done     ,
    output logic [OCM_ROB_ENTRY_WIDTH-1:0]     wr_data_ram_id       ,  
    output logic                               rd_data_ram_done     ,
    output logic [OCM_ROB_ENTRY_WIDTH-1:0]     rd_data_ram_id       ,
    //ecc error
    output logic                               uncor_ecc            ,
    output logic                               cor_ecc              ,
    //credit
    output logic                               credit               
);
//================================================================
//===========================internal signals
//================================================================ 
//---------------------------xbar signals
logic                                   wr_data_ram_en                          ;
pack_ocm_data_ram_wr_pld                wr_data_ram_pld                         ;

//---------------------------data_ram signals
logic [OCM_DATA_RAM_NUM-1:0]            data_ram_en                             ;                     
logic [OCM_DATA_RAM_NUM-1:0]            data_ram_wr                             ;           
logic [OCM_DATA_RAM_NUM-1:0]            data_ram_rd                             ;                     
logic [OCM_L_DATA_RAM_ADDR_WIDTH-1:0]   data_ram_addr   [OCM_DATA_RAM_NUM-1:0]  ;
logic [OCM_L_DATA_RAM_DATA_WIDTH-1:0]   data_ram_din    [OCM_DATA_RAM_NUM-1:0]  ;
logic [OCM_L_DATA_RAM_DATA_WIDTH-1:0]   data_ram_dout   [OCM_DATA_RAM_NUM-1:0]  ;
logic [OCM_DATA_RAM_NUM-1:0]            axi_rd_en                               ; 

//---------------------------ecc_enc signals
logic [OCM_ECC_INF_WIDTH-1:0]           ecc_enc_inf     [OCM_DATA_RAM_NUM-1:0]  ;

//---------------------------ecc_dec signals
logic [OCM_ECC_INF_WIDTH-1:0]           ecc_dec_inf     [OCM_DATA_RAM_NUM-1:0]  ;
logic [OCM_L_DATA_RAM_DATA_WIDTH-1:0]   ecc_dec_data_in [OCM_DATA_RAM_NUM-1:0]  ;  
logic [OCM_L_DATA_RAM_ADDR_WIDTH-1:0]   ecc_dec_addr_in [OCM_DATA_RAM_NUM-1:0]  ;
logic [OCM_L_DATA_RAM_DATA_WIDTH-1:0]   ecc_dec_data_out[OCM_DATA_RAM_NUM-1:0]  ;  
logic [OCM_L_DATA_RAM_ADDR_WIDTH-1:0]   ecc_dec_addr_out[OCM_DATA_RAM_NUM-1:0]  ;
logic [OCM_DATA_RAM_NUM-1:0]            uncor_err_raw                           ;           
logic [OCM_DATA_RAM_NUM-1:0]            cor_err_raw                             ;   
logic [OCM_DATA_RAM_NUM-1:0]            ecc_dec_en                              ;   

//---------------------------ecc_ram_signals    
logic [OCM_DATA_RAM_NUM-1:0]            ecc_ram_en                              ;                     
logic [OCM_DATA_RAM_NUM-1:0]            ecc_ram_wr                              ;                     
logic [OCM_L_DATA_RAM_ADDR_WIDTH-1:0]   ecc_ram_addr   [OCM_DATA_RAM_NUM-1:0]   ;

//---------------------------refiles    
logic [OCM_AXI_RID_WIDTH-1:0]           rid                                     ;
logic [OCM_AXI_LEN-1:0]                 rlen                                    ;
logic [OCM_AXI_LEN-1:0]                 rlast                                   ;
logic [OCM_AXI_RID_WIDTH-1:0]           rid_buf        [OCM_DATA_RAM_NUM-1:0]   ;
logic [OCM_AXI_RID_WIDTH-1:0]           rlen_buf       [OCM_DATA_RAM_NUM-1:0]   ;
logic [OCM_DATA_RAM_NUM-1:0]            rlast_buf      [OCM_DATA_RAM_NUM-1:0]   ;

//---------------------------upstream signals
logic [OCM_DATA_RAM_NUM-1:0]            axi_rd_en_buf                           ;
logic [OCM_DATA_RAM_NUM-1:0]            axi_rd_en_buf_2x                        ;
logic [OCM_L_DATA_RAM_DATA_WIDTH-1:0]   fifo_data_in                            ;
logic [OCM_AXI_RID_WIDTH-1:0]           fifo_id_in                              ;
logic [OCM_AXI_LEN-1:0]                 fifo_len_in                             ;
logic                                   fifo_last_in                            ;
logic [OCM_L_DATA_RAM_DATA_WIDTH-1:0]   fifo_data_out                            ;
logic [OCM_AXI_RID_WIDTH-1:0]           fifo_id_out                              ;
logic [OCM_AXI_LEN-1:0]                 fifo_len_out                             ;
logic                                   fifo_last_out                            ;
logic                                   fifo_wren                               ;
logic                                   fifo_rden                               ;
logic [OCM_L_DATA_RAM_DATA_WIDTH-1:0]   fifo_din                                ;
logic [OCM_L_DATA_RAM_DATA_WIDTH-1:0]   fifo_dout                               ;
logic                                   fifo_full                               ;
logic                                   fifo_empty                              ;

logic [OCM_PACK_FIFO_ADDR_WIDTH:0]      credit_cnt                              ;
logic [OCM_AXI_DATA_WIDTH-1:0]          dec_rdata_buf                           ;
logic                                   dec_rvld_buf                            ;
logic [OCM_AXI_RID_WIDTH-1:0]           dec_rid_buf                             ;
logic                                   dec_rlast_buf                           ;


//================================================================
//===========================ocm_data_buffer
//================================================================ 
ocm_data_buffer u_ocm_data_buffer(
    .clk              (clk              ),
    .rst_n            (rst_n            ),
    .wvld             (wvld             ),
    .wpld             (wpld             ),
    .wrdy             (wrdy             ),
    .w_rob_id         (w_rob_id         ),
    .init_start       (init_start       ),
    .init_rgn         (init_rgn         ),
    .read_data_buf_en (read_data_buf_en ),
    .read_data_buf_pld(read_data_buf_pld),
    .wr_data_buf_done (wr_data_buf_done ),
    .wr_data_buf_id   (wr_data_buf_id   ),
    .wr_data_ram_en   (wr_data_ram_en   ),
    .wr_data_ram_pld  (wr_data_ram_pld  )
);

//================================================================
//===========================ocm_xbar
//================================================================ 
ocm_data_xbar u_ocm_data_xbar(
    .wr_data_ram_en   (wr_data_ram_en   ),
    .wr_data_ram_pld  (wr_data_ram_pld  ),
    .rd_data_ram_en   (read_data_ram_en ),
    .rd_data_ram_pld  (read_data_ram_pld),
    .data_ram_en      (data_ram_en      ),
    .data_ram_wr      (data_ram_wr      ),
    .data_ram_rd      (data_ram_rd      ),
    .data_ram_addr    (data_ram_addr    ),
    .data_ram_din     (data_ram_din     ),
    .data_ram_dout    (data_ram_dout    ),
    .rid              (rid              ),
    .rlen             (rlen             ),
    .rlast            (rlast            ),
    .wr_data_ram_done (wr_data_ram_done ),
    .wr_data_ram_id   (wr_data_ram_id   ),
    .rd_data_ram_done (rd_data_ram_done ),
    .rd_data_ram_id   (rd_data_ram_id   ),
    .axi_rd_en        (axi_rd_en        )                               
);

genvar i;
//================================================================
//===========================ocm_data_ram
//================================================================ 
generate for(i=0;i<OCM_DATA_RAM_NUM;i++) begin
cmn_sp_sram#(
    .DATA_WIDTH(OCM_L_DATA_RAM_DATA_WIDTH),   
    .ADDR_WIDTH(OCM_L_DATA_RAM_ADDR_WIDTH)
)u_sp_data_ram(
    .clk        (clk_x2                             ),      
    .en         (data_ram_en[i]                     ),       
    .wr         (data_ram_wr[i]                     ),       
    .be         ({OCM_L_DATA_RAM_DATA_WIDTH{1'b1}}  ),
    .addr       (data_ram_addr[i]                   ),     
    .data_in    (data_ram_din[i]                    ),
    .data_out   (data_ram_dout[i]                   )  
);
end
endgenerate
//================================================================
//===========================ocm_ecc_ram
//================================================================ 
assign ecc_ram_en   = data_ram_en             ;
assign ecc_ram_wr   = data_ram_wr             ;
assign ecc_ram_addr = data_ram_addr           ;

generate for(i=0;i<OCM_DATA_RAM_NUM;i++) begin
    cmn_sp_sram#(
        .DATA_WIDTH(OCM_ECC_INF_WIDTH         ),   
        .ADDR_WIDTH(OCM_L_DATA_RAM_ADDR_WIDTH )
    )u_sp_ecc_ram(
        .clk        (clk_x2                     ),      
        .en         (ecc_ram_en[i]              ),       
        .wr         (ecc_ram_wr[i]              ),       
        .be         ({OCM_ECC_INF_WIDTH{1'b1}}  ),
        .addr       (ecc_ram_addr[i]            ),     
        .data_in    (ecc_enc_inf[i]             ),
        .data_out   (ecc_dec_inf[i]             )  
    );
    end
endgenerate
//================================================================
//===========================ocm_ecc_encoder
//================================================================ 
generate for(i=0;i<OCM_DATA_RAM_NUM;i++) begin
    ocm_ecc_enc u_ocm_ecc_enc(
        .data_in    (data_ram_din[i]    ),
        .addr_in    (data_ram_addr[i]   ),
        .ecc_enc_inf(ecc_enc_inf[i]     )
    );
end
endgenerate

//================================================================
//===========================ocm_ecc_decoder
//================================================================ 
generate for(i=0;i<OCM_DATA_RAM_NUM;i++) begin
    ocm_ecc_dec u_ocm_ecc_dec(
        .data_in        (ecc_dec_data_in[i] ), 
        .addr_in        (ecc_dec_addr_in[i] ), 
        .ecc_enc_inf    (ecc_dec_inf[i]     ),
        .data_out       (ecc_dec_data_out[i]),
        .addr_out       (ecc_dec_addr_out[i]),
        .uncor_err      (uncor_err_raw[i]   ),
        .cor_err        (cor_err_raw[i]     )
    );
end
endgenerate

generate for(i=0;i<OCM_DATA_RAM_NUM;i++) begin
    always_ff@(posedge clk_x2 or negedge rst_n) begin
        if(~rst_n)          ecc_dec_en[i]<= 1'b0            ;
        else                ecc_dec_en[i]<= data_ram_rd[i]  ;
    end
end
endgenerate

assign uncor_ecc = &(ecc_dec_en & uncor_err_raw);
assign cor_ecc   = &(ecc_dec_en & cor_err_raw)  ;

//================================================================
//===========================ocm_id_regfile
//================================================================ 
generate for(i=0;i<OCM_DATA_RAM_NUM;i++) begin
    always_ff@(posedge clk_x2) begin
        if(data_ram_rd[i])         rid_buf[i] <= rid         ;
end
end
endgenerate
//================================================================
//===========================ocm_len_regfile
//================================================================ 
generate for(i=0;i<OCM_DATA_RAM_NUM;i++) begin
    always_ff@(posedge clk_x2) begin
        if(data_ram_rd[i])        rlen_buf[i] <= rlen        ; 
end
end
endgenerate
//================================================================
//===========================ocm_last_regfile
//================================================================
generate for(i=0;i<OCM_DATA_RAM_NUM;i++) begin
    always_ff@(posedge clk_x2) begin
        if(data_ram_rd[i])       rlast_buf[i] <= rlast        ; 
    end
end
endgenerate
//================================================================
//===========================mux
//================================================================
always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)              axi_rd_en_buf   <= {OCM_DATA_RAM_NUM{1'b0}} ;
    else                    axi_rd_en_buf   <= axi_rd_en                ;
end

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)              axi_rd_en_buf_2x<= {OCM_DATA_RAM_NUM{1'b0}} ;
    else                    axi_rd_en_buf_2x<= axi_rd_en_buf            ;
end

assign fifo_wren = |axi_rd_en_buf_2x;
always_comb begin
    fifo_data_in   = data_ram_dout[0]   ;
    fifo_id_in     = rid_buf[0]         ;    
    fifo_len_in    = rlen_buf[0]        ;
    fifo_last_in   = rlast_buf[0]       ;
    for (int j=0;j<OCM_DATA_RAM_NUM;j++) begin
        if(axi_rd_en_buf_2x[j]==1)
        fifo_data_in   = data_ram_dout[j]   ;
        fifo_id_in     = rid_buf[j]         ;  
        fifo_len_in    = rlen_buf[j]        ;
        fifo_last_in   = rlast_buf[j]       ;
    end
end

assign fifo_din = {fifo_data_in,fifo_id_in,fifo_len_in,fifo_last_in};
//================================================================
//===========================fifo
//================================================================
cmn_fifo #(
    .DATA_WIDTH(OCM_PACK_FIFO_DATA_WIDTH),
    .ADDR_WIDTH(OCM_PACK_FIFO_ADDR_WIDTH)
)u_cmn_fifo(
    .clk     (clk        ),
    .rst_n   (rst_n      ),
    .wr_en   (fifo_wren  ),
    .rd_en   (fifo_rden  ),
    .wr_data (fifo_din   ),
    .rd_data (fifo_dout  ),
    .empty   (fifo_empty ),
    .full    (fifo_full  )
);

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)                              credit_cnt <= {{1'b1},{(OCM_PACK_FIFO_ADDR_WIDTH){1'b0}}}                ;              
    else if(fifo_rden && |(credit_cnt))     credit_cnt <= credit_cnt                                                 ;
    else if(fifo_rden && !(|credit_cnt))    credit_cnt <= credit_cnt + {{(OCM_PACK_FIFO_ADDR_WIDTH){1'b0}},{1'b1}}   ;
end

always_ff@(posedge clk) begin
    credit <= |(credit_cnt);
end

//================================================================
//===========================dec
//================================================================
assign {fifo_data_out,fifo_id_out,fifo_len_out,fifo_last_out} = fifo_dout;

always@(posedge clk) begin
    dec_rdata_buf <= fifo_data_out[OCM_L_DATA_RAM_DATA_WIDTH-1:OCM_AXI_DATA_WIDTH];
end

always@(posedge clk) begin
    dec_rid_buf   <= fifo_id_out  ;
end

always@(posedge clk) begin
    dec_rlast_buf <= fifo_last_out;
end

always@(posedge clk or negedge rst_n) begin
    if(~rst_n)                  dec_rvld_buf <= 1'b0 ; 
    else if(fifo_len_out[1])    dec_rvld_buf <= 1'b1 ;
    else if(dec_rvld_buf)       dec_rvld_buf <= 1'b0 ;
end

assign fifo_rden  = !dec_rvld_buf && rrdy && !fifo_empty ;
assign rpld.rdata = dec_rvld_buf ? dec_rdata_buf : fifo_data_out[OCM_AXI_DATA_WIDTH-1:0]   ;
assign rpld.rid   = dec_rvld_buf ? dec_rid_buf   : fifo_id_out                             ;
assign rpld.rresp = 2'b00                                                                  ;

always_comb begin
    if(~(&fifo_len_out) && fifo_last_out)        rpld.rlast = 1'b1;
    else if(dec_rlast_buf && dec_rvld_buf)       rpld.rlast = 1'b1;
    else                                         rpld.rlast = 1'b0;
end

assign rvld = !fifo_empty ;

endmodule