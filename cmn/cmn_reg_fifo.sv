module cmn_reg_fifo#(
        parameter  integer unsigned DATA_WDITH   = 32             ,
        parameter  integer unsigned ADDR_WIDTH   = 8
    )(
        input  logic                        clk         ,
        input  logic                        rst_n       ,

        input  logic                        in_vld       , // write channel
        output logic                        in_rdy       , // write channel
        input  logic [DATA_WDITH-1:0]       in_pld       , // write channel

        output logic                        out_vld       , // read channel
        input  logic                        out_rdy       , // read channel
        output logic [DATA_WDITH-1:0]       out_pld         // read channel
    );

    localparam type PLD_TYPE = logic [DATA_WDITH-1:0];

    cmn_vrp_reg_fifo #(
        .PLD_TYPE  (PLD_TYPE  ),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_reg_fifo (
        .clk    (clk    ),
        .rst_n  (rst_n  ),
        .in_vld (in_vld ),
        .in_rdy (in_rdy ),
        .in_pld (in_pld ),
        .out_vld(out_vld),
        .out_rdy(out_rdy),
        .out_pld(out_pld)
    );

endmodule