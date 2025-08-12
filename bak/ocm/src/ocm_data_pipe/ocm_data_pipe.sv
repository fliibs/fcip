module ocm_data_pipe
import ocm_package::*;
(
    input  logic                                        clk             ,
    input  logic                                        rst_n           ,
    input  logic                                        wvld            ,
    output logic                                        wrdy            ,
    input  pack_ocm_w_pld                               wpld            ,
    output logic                                        rvld            ,
    input  logic                                        rrdy            ,
    output pack_ocm_r_pld                               rpld            ,
    
    output logic                                        rfifo_crd       ,
    input  logic                                        wfifo_out_vld   ,
    output logic                                        wfifo_out_rdy   ,
    input  logic [OCM_ROB_ENTRY_WIDTH-1:0]              wfifo_out_data  ,

    input  logic                                        rd_data_buf_en   ,
    input  pack_ocm_rob_ack_pld                         rd_data_buf_pld  ,     
    input  logic                                        rd_data_ram_en   ,
    input  pack_ocm_rob_ack_pld                         rd_data_ram_pld  ,

    output logic                                        wr_data_buf_done ,
    output logic [OCM_ROB_ENTRY_WIDTH-1:0]              wr_data_buf_id   ,
    output logic                                        wr_data_ram_done ,                                   
    output logic [OCM_ROB_ENTRY_WIDTH-1:0]              wr_data_ram_id   ,                                   
    output logic                                        rd_data_ram_done ,                                   
    output logic [OCM_ROB_ENTRY_WIDTH-1:0]              rd_data_ram_id   ,

    output logic                                        sb_err           ,
    output logic                                        db_err                                  
);

//======================================================== 
//===============internal signals
//======================================================== 
logic                                        wr_data_ram_en                                                              ;
pack_ocm_rob_ack_pld                         wr_data_ram_pld                                                             ;
logic [OCM_DATA_RAM_UNENC_DATA_WIDTH-1:0]    wr_data_ram_data                                                            ;
pack_ocm_ram_wrapper_in_pld                  ram_wrapper_in_pld [OCM_DATA_RAM_BANK_NUM-1:0]                              ;
logic [OCM_DATA_RAM_UNENC_DATA_WIDTH-1:0]    ram_wrapper_din    [OCM_DATA_RAM_BANK_NUM-1:0]                              ;
pack_ocm_ram_wrapper_out_pld                 ram_wrapper_out_pld[OCM_DATA_RAM_BANK_NUM-1:0]                              ; 
logic [OCM_DATA_RAM_BANK_NUM-1:0]            ram_wrapper_out_en                                                          ; 
logic [OCM_DATA_RAM_BANK_NUM-1:0]            v_sb_err                                                                    ;
logic [OCM_DATA_RAM_BANK_NUM-1:0]            v_db_err                                                                    ;
logic [OCM_AXI_DATA_WIDTH-1:0]               dp_ram_din         [OCM_DATA_BUF_RAM_NUM-1:0]                               ;
logic [OCM_ROB_ENTRY_WIDTH-1:0]              dp_ram_wraddr      [OCM_DATA_BUF_RAM_NUM-1:0]                               ;
logic [OCM_ROB_ENTRY_WIDTH-1:0]              dp_ram_rdaddr      [OCM_DATA_BUF_RAM_NUM-1:0]                               ;
logic                                        dp_ram_wren        [OCM_DATA_BUF_RAM_NUM-1:0]                               ;
logic                                        dp_ram_rden        [OCM_DATA_BUF_RAM_NUM-1:0]                               ;
logic [OCM_AXI_DATA_WIDTH-1:0]               dp_ram_dout        [OCM_DATA_BUF_RAM_NUM-1:0]                               ;
logic [OCM_DATA_RAM_SPLIT_NUM-1:0] [OCM_DATA_RAM_DATA_WIDTH-1:0] sp_ram_din  [OCM_DATA_RAM_BANK_NUM-1:0]                 ;
logic [OCM_DATA_RAM_SPLIT_NUM-1:0]                               sp_ram_en   [OCM_DATA_RAM_BANK_NUM-1:0]                 ;
logic [OCM_DATA_RAM_SPLIT_NUM-1:0]                               sp_ram_wr   [OCM_DATA_RAM_BANK_NUM-1:0]                 ;
logic [OCM_DATA_RAM_SPLIT_NUM-1:0] [OCM_DATA_RAM_ADDR_WIDTH-1:0] sp_ram_addr [OCM_DATA_RAM_BANK_NUM-1:0]                 ;
logic [OCM_DATA_RAM_SPLIT_NUM-1:0] [OCM_DATA_RAM_DATA_WIDTH-1:0] sp_ram_dout [OCM_DATA_RAM_BANK_NUM-1:0]                 ;

genvar i;
ocm_data_w_buffer u_ocm_data_w_buffer(
    .clk                (clk                ),
    .rst_n              (rst_n              ),
    .wvld               (wvld               ),
    .wrdy               (wrdy               ),
    .wpld               (wpld               ),
    .wfifo_out_vld      (wfifo_out_vld      ),
    .wfifo_out_rdy      (wfifo_out_rdy      ),
    .wfifo_out_data     (wfifo_out_data     ),
    .rd_data_buf_en     (rd_data_buf_en     ),
    .rd_data_buf_pld    (rd_data_buf_pld    ),                                                                              
    .wr_data_ram_en     (wr_data_ram_en     ),
    .wr_data_ram_pld    (wr_data_ram_pld    ),
    .wr_data_ram_data   (wr_data_ram_data   ),
    .wr_data_buf_done   (wr_data_buf_done   ),
    .wr_data_buf_id     (wr_data_buf_id     ),
    .ram_din            (dp_ram_din    ),
    .ram_wraddr         (dp_ram_wraddr ),
    .ram_rdaddr         (dp_ram_rdaddr ),
    .ram_wren           (dp_ram_wren   ),                
    .ram_rden           (dp_ram_rden   ),                
    .ram_dout           (dp_ram_dout   ) 
);

ocm_xbar u_ocm_xbar(
    .wr_data_ram_en    (wr_data_ram_en      ),
    .wr_data_ram_pld   (wr_data_ram_pld     ),
    .wr_data_ram_data  (wr_data_ram_data    ),                 
    .rd_data_ram_en    (rd_data_ram_en      ),
    .rd_data_ram_pld   (rd_data_ram_pld     ),
    .ram_wrapper_in_pld(ram_wrapper_in_pld  ),
    .ram_wrapper_din   (ram_wrapper_din     ),
    .wr_data_ram_done  (wr_data_ram_done    ),
    .wr_data_ram_id    (wr_data_ram_id      ),
    .rd_data_ram_done  (rd_data_ram_done    ),
    .rd_data_ram_id    (rd_data_ram_id      )      
);

generate for(i=0;i<OCM_DATA_RAM_BANK_NUM;i++) begin
ocm_ram_wrapper u_ocm_ram_wrapper(
    .clk                   (clk                   ),
    .rst_n                 (rst_n                 ),
    .v_ram_wrapper_in_pld  (ram_wrapper_in_pld[i] ),
    .v_sram_wrapper_din    (ram_wrapper_din   [i] ),
    .v_sb_err              (v_sb_err[i]           ),
    .v_db_err              (v_db_err[i]           ),
    .v_ram_wrapper_out_pld (ram_wrapper_out_pld[i]), 
    .v_ram_wrapper_out_en  (ram_wrapper_out_en [i]),       
    .v_ram_din             (sp_ram_din [i]        ),
    .v_ram_dout            (sp_ram_dout[i]        ),
    .v_ram_en              (sp_ram_en  [i]        ),
    .v_ram_wr              (sp_ram_wr  [i]        ),
    .v_ram_addr            (sp_ram_addr[i]        )
);
end
endgenerate

assign sb_err = v_sb_err;
assign db_err = v_db_err;

ocm_data_sram u_ocm_data_sram(
    .clk           (clk          ),
    .dp_ram_din    (dp_ram_din   ),
    .dp_ram_wraddr (dp_ram_wraddr),
    .dp_ram_rdaddr (dp_ram_rdaddr),
    .dp_ram_wren   (dp_ram_wren  ),
    .dp_ram_rden   (dp_ram_rden  ),
    .dp_ram_dout   (dp_ram_dout  ),
    .sp_ram_din    (sp_ram_din   ),
    .sp_ram_en     (sp_ram_en    ),
    .sp_ram_wr     (sp_ram_wr    ),
    .sp_ram_addr   (sp_ram_addr  ),
    .sp_ram_dout   (sp_ram_dout  )
);

ocm_data_r_buffer u_ocm_data_r_buffer(
    .clk                 (clk                ),
    .rst_n               (rst_n              ),
    .ram_wrapper_out_en  (ram_wrapper_out_en ),
    .ram_wrapper_out_pld (ram_wrapper_out_pld),
    .rvld                (rvld               ),
    .rrdy                (rrdy               ),
    .rpld                (rpld               ),
    .rfifo_crd           (rfifo_crd          )                                            
);
endmodule