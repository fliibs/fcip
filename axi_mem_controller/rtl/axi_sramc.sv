module axi_sramc
#(
    parameter AXI_ADDR_WIDTH  = 32,
    parameter AXI_ID_WIDTH    = 6,
    parameter AXI_DATA_WIDTH  = 64,
    parameter AXI_WSTRB_WIDTH = AXI_DATA_WIDTH/8,
    parameter AXI_USER_WIDTH  = 8
) (
    // clk&rstn
    input logic                               clk ,
    input logic                               rstn,
    // axi slave interface 
    // aw
    input  logic                              s_awvalid,
    output logic                              s_awready,
    input  logic [AXI_ADDR_WIDTH-1:0]         s_awaddr,
    input  logic [AXI_ID_WIDTH-1:0]           s_awid,
    input  logic [7:0]                        s_awlen,
    input  logic [2:0]                        s_awsize,
    input  logic [1:0]                        s_awburst,
    input  logic [3:0]                        s_awcache,
    input  logic [2:0]                        s_awprot,
    input  logic [3:0]                        s_awqos,
    input  logic [AXI_USER_WIDTH-1:0]         s_awuser,
    // w
    input  logic                              s_wvalid,
    output logic                              s_wready,
    input  logic [AXI_DATA_WIDTH-1:0]         s_wdata,
    input  logic [AXI_WSTRB_WIDTH-1:0]        s_wstrb,
    input  logic                              s_wlast,
    // b
    output logic                              s_bvalid,
    input  logic                              s_bready,
    output logic [AXI_ID_WIDTH-1:0]           s_bid,
    output logic [1:0]                        s_bresp,
    // ar
    input  logic                              s_arvalid,
    output logic                              s_arready,
    input  logic [AXI_ADDR_WIDTH-1:0]         s_araddr,
    input  logic [AXI_ID_WIDTH-1:0]           s_arid,
    input  logic [7:0]                        s_arlen,
    input  logic [2:0]                        s_arsize,
    input  logic [1:0]                        s_arburst,
    input  logic [3:0]                        s_arcache,
    input  logic [2:0]                        s_arprot,
    input  logic [3:0]                        s_arqos,
    input  logic [AXI_USER_WIDTH-1:0]         s_aruser,
    // r
    output logic                              s_rvalid,
    input  logic                              s_rready,
    output logic [AXI_DATA_WIDTH-1:0]         s_rdata,
    output logic [AXI_ID_WIDTH-1:0]           s_rid,
    output logic [1:0]                        s_rresp,
    output logic                              s_rlast,
    // memory wrapper master interface
    // memory in
    output logic                              m_mi_valid,
    input  logic                              m_mi_ready,
    output logic                              m_mi_rw,
    output logic                              m_mi_rmw,
    output logic                              m_mi_axlast,
    output logic [AXI_ID_WIDTH-1:0]           m_mi_axid,
    output logic [AXI_USER_WIDTH-1:0]         m_mi_axuser,
    output logic [AXI_ADDR_WIDTH-1:0]         m_mi_axaddr,
    output logic [AXI_DATA_WIDTH-1:0]         m_mi_data,
    // memory out
    input  logic                              m_mo_valid,
    output logic                              m_mo_ready,
    input  logic                              m_mo_rw,
    input  logic                              m_mo_rmw,
    input  logic                              m_mo_axlast,
    input  logic [AXI_ID_WIDTH-1:0]           m_mo_axid,
    input  logic [AXI_DATA_WIDTH-1:0]         m_mo_data,
    // Reg
    output logic                              axi_sramc_idle,
    output logic                              ecc_err


);
    `include "axi_sramc_typedef.svh"

    // ax_pld_st  s_ar_pld;
    // localparam AX_PLD_WIDTH = AXI_ADDR_WIDTH + AXI_ID_WIDTH + 8 + 3 + 2 + AXI_USER_WIDTH;

    // logic      m_ar_fifo_vld;
    // logic      m_ar_fifo_rdy;
    // ax_pld_st  m_ar_fifo_pld;



    // assign s_ar_pld.addr  = s_araddr;
    // assign s_ar_pld.id    = s_arid;
    // assign s_ar_pld.len   = s_arlen;
    // assign s_ar_pld.size  = s_arsize;
    // assign s_ar_pld.burst = s_arburst;
    // assign s_ar_pld.user  = s_aruser;
    
    // // read channel
    // vrp_fifo #(
    //     .PLD_WIDTH ( AX_PLD_WIDTH ),
    //     .DEPTH     ( 8            )
    // ) u_ar_fifo (
    //     .clk   ( clk           ),
    //     .rst_n ( rstn          ),
    //     .vld_s ( s_arvalid     ),
    //     .rdy_s ( s_arready     ),
    //     .pld_s ( s_ar_pld      ),
    //     .vld_m ( m_ar_fifo_vld ),
    //     .rdy_m ( m_ar_fifo_rdy ),
    //     .pld_m ( m_ar_fifo_pld )
    // );

    // write channel

endmodule