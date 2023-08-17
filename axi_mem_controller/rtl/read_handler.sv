module read_handler #(
    parameter AXI_ADDR_WIDTH  = 32,
    parameter AXI_ID_WIDTH    = 6,
    parameter AXI_DATA_WIDTH  = 64,
    parameter AXI_USER_WIDTH  = 8
    
) (
    ports
);


    ax_pld_st  s_ar_pld;
    localparam AX_PLD_WIDTH = AXI_ADDR_WIDTH + AXI_ID_WIDTH + 8 + 3 + 2 + AXI_USER_WIDTH;

    logic      m_ar_fifo_vld;
    logic      m_ar_fifo_rdy;
    ax_pld_st  m_ar_fifo_pld;



    assign s_ar_pld.addr  = s_araddr;
    assign s_ar_pld.id    = s_arid;
    assign s_ar_pld.len   = s_arlen;
    assign s_ar_pld.size  = s_arsize;
    assign s_ar_pld.burst = s_arburst;
    assign s_ar_pld.user  = s_aruser;
    
    // read channel
    vrp_fifo #(
        .PLD_WIDTH ( AX_PLD_WIDTH ),
        .DEPTH     ( 8            )
    ) u_ar_fifo (
        .clk   ( clk           ),
        .rst_n ( rstn          ),
        .vld_s ( s_arvalid     ),
        .rdy_s ( s_arready     ),
        .pld_s ( s_ar_pld      ),
        .vld_m ( m_ar_fifo_vld ),
        .rdy_m ( m_ar_fifo_rdy ),
        .pld_m ( m_ar_fifo_pld )
    );
endmodule