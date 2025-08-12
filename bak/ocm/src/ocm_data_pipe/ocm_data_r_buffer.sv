module ocm_data_r_buffer
import ocm_package::*;
(
    input  logic                                clk                                                 ,
    input  logic                                rst_n                                               ,
    input  [OCM_DATA_RAM_BANK_NUM-1:0]          ram_wrapper_out_en                                  ,
    input  pack_ocm_ram_wrapper_out_pld         ram_wrapper_out_pld [OCM_DATA_RAM_BANK_NUM-1:0]     ,
    output logic                                rvld                                                ,
    input  logic                                rrdy                                                ,
    output pack_ocm_r_pld                       rpld                                                ,
    output logic                                rfifo_crd                                                                                       
);

//================================================================
//===========================internal signals
//================================================================
    logic                                   rfifo_in_vld        ;
    logic                                   rfifo_in_rdy        ;
    pack_ocm_ram_wrapper_out_pld            rfifo_in_pld        ;
    logic                                   rfifo_out_vld       ;
    logic                                   rfifo_out_rdy       ;
    pack_ocm_ram_wrapper_out_pld            rfifo_out_pld       ;
    logic [OCM_DATA_FIFO_ADDR_WIDTH:0]      credit_cnt          ;
    logic                                   rfifo_in_hsk        ;
    logic                                   rfifo_out_hsk       ;
    logic                                   dec_vld_buf         ;

//================================================================
//===========================MUX
//================================================================
    cmn_real_mux_onehot #(
        .WIDTH    (OCM_DATA_RAM_BANK_NUM                ),
        .PLD_WIDTH($bits(pack_ocm_ram_wrapper_out_pld)  )
    ) u_mux (
        .select_onehot  (ram_wrapper_out_en  ),
        .v_pld          (ram_wrapper_out_pld ),
        .select_pld     (rfifo_in_pld        )
    );
    
    assign rfifo_in_vld  = |ram_wrapper_out_en       ;

//================================================================
//===========================credit cnt
//================================================================
    assign rfifo_in_hsk  = rfifo_in_vld  && rfifo_in_rdy   ;
    assign rfifo_out_hsk = rfifo_out_vld && rfifo_out_rdy  ;
    
    always_ff@(posedge clk or negedge rst_n) begin
        if(~rst_n)                              credit_cnt <= {{1'b1},{(OCM_DATA_FIFO_ADDR_WIDTH){1'b0}}}                ;     
        else if(rfifo_out_hsk && |(credit_cnt)) credit_cnt <= credit_cnt                                                 ;
        else if(rfifo_out_hsk && !(credit_cnt)) credit_cnt <= credit_cnt + {{(OCM_DATA_FIFO_ADDR_WIDTH){1'b0}},{1'b1}}   ;
        else                                    credit_cnt <= credit_cnt - {{(OCM_DATA_FIFO_ADDR_WIDTH){1'b0}},{1'b1}}   ;
    end

    assign rfifo_crd = |(credit_cnt);

//================================================================
//===========================fifo
//================================================================
    cmn_vrp_reg_fifo#(
        .PLD_TYPE  (pack_ocm_ram_wrapper_out_pld),
        .ADDR_WIDTH(OCM_DATA_FIFO_ADDR_WIDTH    )
    )u_r_fifo(
        .clk    (clk          ),
        .rst_n  (rst_n        ),
        .in_vld (rfifo_in_vld ), 
        .in_rdy (rfifo_in_rdy ), 
        .in_pld (rfifo_in_pld ), 
        .out_vld(rfifo_out_vld), 
        .out_rdy(rfifo_out_rdy), 
        .out_pld(rfifo_out_pld)  
    );
assign r_fifo_out_rdy = rrdy;
//================================================================
//===========================decoder
//================================================================
    assign rvld          = rfifo_out_vld                    ;
    assign rpld.rdata    = rfifo_out_pld.dout               ; 
    assign rpld.rid      = rfifo_out_pld.ram_bps_pld.id     ;
    assign rpld.rlast    = rfifo_out_pld.ram_bps_pld.last   ;
    assign rpld.rresp    = rfifo_out_pld.ram_bps_pld.resp   ;

endmodule