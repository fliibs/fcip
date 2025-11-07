module fcip_axi_afifo #(
    parameter integer unsigned ADDR_WIDTH       = 32,
    parameter integer unsigned DATA_WIDTH       = 128,
    parameter integer unsigned AWID_WIDTH       = 8,
    parameter integer unsigned ARID_WIDTH       = 8,
    parameter integer unsigned AWLEN_WIDTH      = 8,
    parameter integer unsigned ARLEN_WIDTH      = 8,
    parameter integer unsigned AWUSER_WIDTH     = 1,
    parameter integer unsigned WUSER_WIDTH      = 1,
    parameter integer unsigned BUSER_WIDTH      = 1,
    parameter integer unsigned ARUSER_WIDTH     = 1,
    parameter integer unsigned RUSER_WIDTH      = 1,
    parameter integer unsigned AW_FIFO_DEPTH    = 8,
    parameter integer unsigned W_FIFO_DEPTH     = 8,
    parameter integer unsigned B_FIFO_DEPTH     = 8,
    parameter integer unsigned AR_FIFO_DEPTH    = 8,
    parameter integer unsigned R_FIFO_DEPTH     = 8,
    parameter integer unsigned SYNC_STAGE       = 2,
    parameter integer unsigned AUTO_CLEAR_EN    = 1,
    parameter integer unsigned VT_TYPE          = 1     ,// 0: SVT, 1: LVT, 2: ULVT, 3: ELVT, 4: LVTLL, 5: ULVTLL
    localparam int unsigned    AW_PAYLOAD_WIDTH = AWUSER_WIDTH + AWID_WIDTH + ADDR_WIDTH + AWLEN_WIDTH +
                                                    4 + //region
                                                    3 + //size
                                                    2 + //burst
                                                    1 + //lock
                                                    4 + //cache
                                                    3 + //prot
                                                    4 , //qos
    localparam int unsigned    W_PAYLOAD_WIDTH = WUSER_WIDTH + DATA_WIDTH + (DATA_WIDTH/8) +
                                                    1 , //wlast
    localparam int unsigned    B_PAYLOAD_WIDTH = BUSER_WIDTH + AWID_WIDTH + 
                                                    2 , //bresp                                
    localparam int unsigned    AR_PAYLOAD_WIDTH = ARUSER_WIDTH + ARID_WIDTH + ADDR_WIDTH + ARLEN_WIDTH +
                                                    4 + //region
                                                    3 + //size
                                                    2 + //burst
                                                    1 + //lock
                                                    4 + //cache
                                                    3 + //prot
                                                    4 , //qos
    localparam int unsigned    R_PAYLOAD_WIDTH = RUSER_WIDTH + ARID_WIDTH + DATA_WIDTH +
                                                    1 + //rlast
                                                    2  //rresp
)(
    input logic                         clk_s,
    input logic                         rst_s_n,
    input logic                         clk_m,
    input logic                         rst_m_n,

    //slave port
    input   logic                       axi_fifo_slv_stall,
    input   logic                       axi_fifo_slv_clear,
    output  logic                       axi_fifo_slv_full_zero,

    // AW channel
    input   logic                       awvalid_s,
    output  logic                       awready_s,
    input   logic [AWUSER_WIDTH-1:0]    awuser_s,
    input   logic [AWID_WIDTH-1:0]      awid_s,
    input   logic [ADDR_WIDTH-1:0]      awaddr_s,
    input   logic [3:0]                 awregion_s,
    input   logic [7:0]                 awlen_s,
    input   logic [2:0]                 awsize_s,
    input   logic [1:0]                 awburst_s,
    input   logic                       awlock_s,
    input   logic [3:0]                 awcache_s,
    input   logic [2:0]                 awprot_s,
    input   logic [3:0]                 awqos_s,

    // W channel
    input   logic                       wvalid_s,
    output  logic                       wready_s,
    input   logic [WUSER_WIDTH-1:0]     wuser_s,
    input   logic [DATA_WIDTH-1:0]      wdata_s,
    input   logic [(DATA_WIDTH/8)-1:0]  wstrb_s,
    input   logic                       wlast_s,

    // B channel
    output  logic                       bvalid_s,
    input   logic                       bready_s,
    output  logic [BUSER_WIDTH-1:0]     buser_s,
    output  logic [AWID_WIDTH-1:0]      bid_s,
    output  logic [1:0]                 bresp_s,

    // AR channel
    input   logic                       arvalid_s,
    output  logic                       arready_s,
    input   logic [ARUSER_WIDTH-1:0]    aruser_s,
    input   logic [ARID_WIDTH-1:0]      arid_s,
    input   logic [ADDR_WIDTH-1:0]      araddr_s,
    input   logic [3:0]                 arregion_s,
    input   logic [7:0]                 arlen_s,
    input   logic [2:0]                 arsize_s,
    input   logic [1:0]                 arburst_s,
    input   logic                       arlock_s,
    input   logic [3:0]                 arcache_s,
    input   logic [2:0]                 arprot_s,
    input   logic [3:0]                 arqos_s,

    // R channel
    output  logic                       rvalid_s,
    input   logic                       rready_s,
    output  logic [BUSER_WIDTH-1:0]     ruser_s,
    output  logic [ARID_WIDTH-1:0]      rid_s,
    output  logic [DATA_WIDTH-1:0]      rdata_s,
    output  logic [1:0]                 rresp_s,
    output  logic                       rlast_s,

    //master port
    //lowpower interface
    input   logic                       axi_fifo_mst_stall,
    input   logic                       axi_fifo_mst_clear,
    output  logic                       axi_fifo_mst_full_zero,

    // AW channel
    output  logic                       awvalid_m,
    input   logic                       awready_m,
    output  logic [AWUSER_WIDTH-1:0]    awuser_m,
    output  logic [AWID_WIDTH-1:0]      awid_m,
    output  logic [ADDR_WIDTH-1:0]      awaddr_m,
    output  logic [3:0]                 awregion_m,
    output  logic [7:0]                 awlen_m,
    output  logic [2:0]                 awsize_m,
    output  logic [1:0]                 awburst_m,
    output  logic                       awlock_m,
    output  logic [3:0]                 awcache_m,
    output  logic [2:0]                 awprot_m,
    output  logic [3:0]                 awqos_m,

    // W channel
    output  logic                       wvalid_m,
    input   logic                       wready_m,
    output  logic [WUSER_WIDTH-1:0]     wuser_m,
    output  logic [DATA_WIDTH-1:0]      wdata_m,
    output  logic [(DATA_WIDTH/8)-1:0]  wstrb_m,
    output  logic                       wlast_m,

    // B channel
    input   logic                       bvalid_m,
    output  logic                       bready_m,
    input   logic [BUSER_WIDTH-1:0]     buser_m,
    input   logic [AWID_WIDTH-1:0]      bid_m,
    input   logic [1:0]                 bresp_m,

    // AR channel
    output  logic                       arvalid_m,
    input   logic                       arready_m,
    output  logic [ARUSER_WIDTH-1:0]    aruser_m,
    output  logic [ARID_WIDTH-1:0]      arid_m,
    output  logic [ADDR_WIDTH-1:0]      araddr_m,
    output  logic [3:0]                 arregion_m,
    output  logic [7:0]                 arlen_m,
    output  logic [2:0]                 arsize_m,
    output  logic [1:0]                 arburst_m,
    output  logic                       arlock_m,
    output  logic [3:0]                 arcache_m,
    output  logic [2:0]                 arprot_m,
    output  logic [3:0]                 arqos_m,

    // R channel
    input   logic                       rvalid_m,
    output  logic                       rready_m,
    input   logic [BUSER_WIDTH-1:0]     ruser_m,
    input   logic [ARID_WIDTH-1:0]      rid_m,
    input   logic [DATA_WIDTH-1:0]      rdata_m,
    input   logic [1:0]                 rresp_m,
    input   logic                       rlast_m
);

logic [AW_FIFO_DEPTH-1:0]    aw_chnl_wptr_async;
logic [AW_FIFO_DEPTH-1:0]    aw_chnl_rptr_async;
logic [AW_FIFO_DEPTH-1:0]    aw_chnl_rptr_sync;
logic [AW_PAYLOAD_WIDTH:0]   aw_chnl_pld_sync;  //DATA_WIDTH+1,used for entry vld

logic [W_FIFO_DEPTH-1:0]     w_chnl_wptr_async;
logic [W_FIFO_DEPTH-1:0]     w_chnl_rptr_async;
logic [W_FIFO_DEPTH-1:0]     w_chnl_rptr_sync;
logic [W_PAYLOAD_WIDTH:0]    w_chnl_pld_sync;  //DATA_WIDTH+1,used for entry vld

logic [B_FIFO_DEPTH-1:0]     b_chnl_wptr_async;
logic [B_FIFO_DEPTH-1:0]     b_chnl_rptr_async;
logic [B_FIFO_DEPTH-1:0]     b_chnl_rptr_sync;
logic [B_PAYLOAD_WIDTH:0]    b_chnl_pld_sync;  //DATA_WIDTH+1,used for entry vld

logic [AR_FIFO_DEPTH-1:0]    ar_chnl_wptr_async;
logic [AR_FIFO_DEPTH-1:0]    ar_chnl_rptr_async;
logic [AR_FIFO_DEPTH-1:0]    ar_chnl_rptr_sync;
logic [AR_PAYLOAD_WIDTH:0]   ar_chnl_pld_sync;  //DATA_WIDTH+1,used for entry vld

logic [R_FIFO_DEPTH-1:0]     r_chnl_wptr_async;
logic [R_FIFO_DEPTH-1:0]     r_chnl_rptr_async;
logic [R_FIFO_DEPTH-1:0]     r_chnl_rptr_sync;
logic [R_PAYLOAD_WIDTH:0]    r_chnl_pld_sync; //DATA_WIDTH+1,used for entry vld

fcip_axi_afifo_slv #(
    .ADDR_WIDTH     (ADDR_WIDTH   ),
    .DATA_WIDTH     (DATA_WIDTH   ),
    .AWID_WIDTH     (AWID_WIDTH   ),
    .ARID_WIDTH     (ARID_WIDTH   ),
    .AWLEN_WIDTH    (AWLEN_WIDTH  ),
    .ARLEN_WIDTH    (ARLEN_WIDTH  ),
    .AWUSER_WIDTH   (AWUSER_WIDTH ),
    .WUSER_WIDTH    (WUSER_WIDTH  ),
    .BUSER_WIDTH    (BUSER_WIDTH  ),
    .ARUSER_WIDTH   (ARUSER_WIDTH ),
    .RUSER_WIDTH    (RUSER_WIDTH  ),
    .AW_FIFO_DEPTH  (AW_FIFO_DEPTH),
    .W_FIFO_DEPTH   (W_FIFO_DEPTH ),
    .B_FIFO_DEPTH   (B_FIFO_DEPTH ),
    .AR_FIFO_DEPTH  (AR_FIFO_DEPTH),
    .R_FIFO_DEPTH   (R_FIFO_DEPTH ),
    .SYNC_STAGE     (SYNC_STAGE   ),
    .AUTO_CLEAR_EN  (AUTO_CLEAR_EN),
    .VT_TYPE        (VT_TYPE      )
)u_fcip_axi_afifo_slv(
    .clk                        (clk_s),
    .rst_n                      (rst_s_n),
    .axi_fifo_slv_stall         (axi_fifo_slv_stall    ),
    .axi_fifo_slv_clear         (axi_fifo_slv_clear    ),
    .axi_fifo_slv_full_zero     (axi_fifo_slv_full_zero),

    .awvalid_s                  (awvalid_s ),
    .awready_s                  (awready_s ),
    .awuser_s                   (awuser_s  ),
    .awid_s                     (awid_s    ),
    .awaddr_s                   (awaddr_s  ),
    .awregion_s                 (awregion_s),
    .awlen_s                    (awlen_s   ),
    .awsize_s                   (awsize_s  ),
    .awburst_s                  (awburst_s ),
    .awlock_s                   (awlock_s  ),
    .awcache_s                  (awcache_s ),
    .awprot_s                   (awprot_s  ),
    .awqos_s                    (awqos_s   ),

    .wvalid_s                   (wvalid_s),
    .wready_s                   (wready_s),
    .wuser_s                    (wuser_s ),
    .wdata_s                    (wdata_s ),
    .wstrb_s                    (wstrb_s ),
    .wlast_s                    (wlast_s ),

    .bvalid_s                   (bvalid_s),
    .bready_s                   (bready_s),
    .buser_s                    (buser_s ),
    .bid_s                      (bid_s   ),
    .bresp_s                    (bresp_s ),

    .arvalid_s                  (arvalid_s ),
    .arready_s                  (arready_s ),
    .aruser_s                   (aruser_s  ),
    .arid_s                     (arid_s    ),
    .araddr_s                   (araddr_s  ),
    .arregion_s                 (arregion_s),
    .arlen_s                    (arlen_s   ),
    .arsize_s                   (arsize_s  ),
    .arburst_s                  (arburst_s ),
    .arlock_s                   (arlock_s  ),
    .arcache_s                  (arcache_s ),
    .arprot_s                   (arprot_s  ),
    .arqos_s                    (arqos_s   ),

    .rvalid_s                   (rvalid_s),
    .rready_s                   (rready_s),
    .ruser_s                    (ruser_s ),
    .rid_s                      (rid_s   ),
    .rdata_s                    (rdata_s ),
    .rresp_s                    (rresp_s ),
    .rlast_s                    (rlast_s ),

    .aw_chnl_slv_wptr_async     (aw_chnl_wptr_async),
    .aw_chnl_slv_rptr_async     (aw_chnl_rptr_async),
    .aw_chnl_slv_rptr_sync      (aw_chnl_rptr_sync ),
    .aw_chnl_slv_pld_sync       (aw_chnl_pld_sync  ),  //DATA_WIDTH+1,used for entry vld
    .w_chnl_slv_wptr_async      (w_chnl_wptr_async ),
    .w_chnl_slv_rptr_async      (w_chnl_rptr_async ),
    .w_chnl_slv_rptr_sync       (w_chnl_rptr_sync  ),
    .w_chnl_slv_pld_sync        (w_chnl_pld_sync   ),  //DATA_WIDTH+1,used for entry vld
    .b_chnl_slv_wptr_async      (b_chnl_wptr_async ),
    .b_chnl_slv_rptr_async      (b_chnl_rptr_async ),
    .b_chnl_slv_rptr_sync       (b_chnl_rptr_sync  ),
    .b_chnl_slv_pld_sync        (b_chnl_pld_sync   ),  //DATA_WIDTH+1,used for entry vld
    .ar_chnl_slv_wptr_async     (ar_chnl_wptr_async),
    .ar_chnl_slv_rptr_async     (ar_chnl_rptr_async),
    .ar_chnl_slv_rptr_sync      (ar_chnl_rptr_sync ),
    .ar_chnl_slv_pld_sync       (ar_chnl_pld_sync  ),  //DATA_WIDTH+1,used for entry vld
    .r_chnl_slv_wptr_async      (r_chnl_wptr_async ),
    .r_chnl_slv_rptr_async      (r_chnl_rptr_async ),
    .r_chnl_slv_rptr_sync       (r_chnl_rptr_sync  ),
    .r_chnl_slv_pld_sync        (r_chnl_pld_sync   )  //DATA_WIDTH+1,used for entry vld
);

fcip_axi_afifo_mst #(
    .ADDR_WIDTH     (ADDR_WIDTH   ),
    .DATA_WIDTH     (DATA_WIDTH   ),
    .AWID_WIDTH     (AWID_WIDTH   ),
    .ARID_WIDTH     (ARID_WIDTH   ),
    .AWLEN_WIDTH    (AWLEN_WIDTH  ),
    .ARLEN_WIDTH    (ARLEN_WIDTH  ),
    .AWUSER_WIDTH   (AWUSER_WIDTH ),
    .WUSER_WIDTH    (WUSER_WIDTH  ),
    .BUSER_WIDTH    (BUSER_WIDTH  ),
    .ARUSER_WIDTH   (ARUSER_WIDTH ),
    .RUSER_WIDTH    (RUSER_WIDTH  ),
    .AW_FIFO_DEPTH  (AW_FIFO_DEPTH),
    .W_FIFO_DEPTH   (W_FIFO_DEPTH ),
    .B_FIFO_DEPTH   (B_FIFO_DEPTH ),
    .AR_FIFO_DEPTH  (AR_FIFO_DEPTH),
    .R_FIFO_DEPTH   (R_FIFO_DEPTH ),
    .SYNC_STAGE     (SYNC_STAGE   ),
    .AUTO_CLEAR_EN  (AUTO_CLEAR_EN),
    .VT_TYPE        (VT_TYPE      )
)u_fcip_axi_afifo_mst(
    .clk                        (clk_m),
    .rst_n                      (rst_m_n),
    .axi_fifo_mst_stall         (axi_fifo_mst_stall    ),
    .axi_fifo_mst_clear         (axi_fifo_mst_clear    ),
    .axi_fifo_mst_full_zero     (axi_fifo_mst_full_zero),

    .awvalid_m                  (awvalid_m ),
    .awready_m                  (awready_m ),
    .awuser_m                   (awuser_m  ),
    .awid_m                     (awid_m    ),
    .awaddr_m                   (awaddr_m  ),
    .awregion_m                 (awregion_m),
    .awlen_m                    (awlen_m   ),
    .awsize_m                   (awsize_m  ),
    .awburst_m                  (awburst_m ),
    .awlock_m                   (awlock_m  ),
    .awcache_m                  (awcache_m ),
    .awprot_m                   (awprot_m  ),
    .awqos_m                    (awqos_m   ),

    .wvalid_m                   (wvalid_m),
    .wready_m                   (wready_m),
    .wuser_m                    (wuser_m ),
    .wdata_m                    (wdata_m ),
    .wstrb_m                    (wstrb_m ),
    .wlast_m                    (wlast_m ),

    .bvalid_m                   (bvalid_m),
    .bready_m                   (bready_m),
    .buser_m                    (buser_m ),
    .bid_m                      (bid_m   ),
    .bresp_m                    (bresp_m ),

    .arvalid_m                  (arvalid_m ),
    .arready_m                  (arready_m ),
    .aruser_m                   (aruser_m  ),
    .arid_m                     (arid_m    ),
    .araddr_m                   (araddr_m  ),
    .arregion_m                 (arregion_m),
    .arlen_m                    (arlen_m   ),
    .arsize_m                   (arsize_m  ),
    .arburst_m                  (arburst_m ),
    .arlock_m                   (arlock_m  ),
    .arcache_m                  (arcache_m ),
    .arprot_m                   (arprot_m  ),
    .arqos_m                    (arqos_m   ),

    .rvalid_m                   (rvalid_m),
    .rready_m                   (rready_m),
    .ruser_m                    (ruser_m ),
    .rid_m                      (rid_m   ),
    .rdata_m                    (rdata_m ),
    .rresp_m                    (rresp_m ),
    .rlast_m                    (rlast_m ),

    .aw_chnl_mst_wptr_async     (aw_chnl_wptr_async),
    .aw_chnl_mst_rptr_async     (aw_chnl_rptr_async),
    .aw_chnl_mst_rptr_sync      (aw_chnl_rptr_sync ),
    .aw_chnl_mst_pld_sync       (aw_chnl_pld_sync  ),  //DATA_WIDTH+1,used for entry vld
    .w_chnl_mst_wptr_async      (w_chnl_wptr_async ),
    .w_chnl_mst_rptr_async      (w_chnl_rptr_async ),
    .w_chnl_mst_rptr_sync       (w_chnl_rptr_sync  ),
    .w_chnl_mst_pld_sync        (w_chnl_pld_sync   ),  //DATA_WIDTH+1,used for entry vld
    .b_chnl_mst_wptr_async      (b_chnl_wptr_async ),
    .b_chnl_mst_rptr_async      (b_chnl_rptr_async ),
    .b_chnl_mst_rptr_sync       (b_chnl_rptr_sync  ),
    .b_chnl_mst_pld_sync        (b_chnl_pld_sync   ),  //DATA_WIDTH+1,used for entry vld
    .ar_chnl_mst_wptr_async     (ar_chnl_wptr_async),
    .ar_chnl_mst_rptr_async     (ar_chnl_rptr_async),
    .ar_chnl_mst_rptr_sync      (ar_chnl_rptr_sync ),
    .ar_chnl_mst_pld_sync       (ar_chnl_pld_sync  ),  //DATA_WIDTH+1,used for entry vld
    .r_chnl_mst_wptr_async      (r_chnl_wptr_async ),
    .r_chnl_mst_rptr_async      (r_chnl_rptr_async ),
    .r_chnl_mst_rptr_sync       (r_chnl_rptr_sync  ),
    .r_chnl_mst_pld_sync        (r_chnl_pld_sync   )  //DATA_WIDTH+1,used for entry vld
);
endmodule