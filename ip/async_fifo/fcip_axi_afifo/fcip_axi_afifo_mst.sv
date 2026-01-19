module fcip_axi_afifo_mst #(
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
    input   logic             clk,
    input   logic             rst_n,

    // lowpower interface
    input   logic             axi_fifo_mst_stall,
    input   logic             axi_fifo_mst_clear,
    output  logic             axi_fifo_mst_full_zero,

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
    input   logic                       rlast_m,

    //control pointer
    input  logic [AW_FIFO_DEPTH-1:0]    aw_chnl_mst_wptr_async,
    output logic [AW_FIFO_DEPTH-1:0]    aw_chnl_mst_rptr_async,
    output logic [AW_FIFO_DEPTH-1:0]    aw_chnl_mst_rptr_sync,
    input  logic [AW_PAYLOAD_WIDTH:0]   aw_chnl_mst_pld_sync,  //DATA_WIDTH+1,used for entry vld

    input  logic [W_FIFO_DEPTH-1:0]     w_chnl_mst_wptr_async,
    output logic [W_FIFO_DEPTH-1:0]     w_chnl_mst_rptr_async,
    output logic [W_FIFO_DEPTH-1:0]     w_chnl_mst_rptr_sync,
    input  logic [W_PAYLOAD_WIDTH:0]    w_chnl_mst_pld_sync,  //DATA_WIDTH+1,used for entry vld

    output logic [B_FIFO_DEPTH-1:0]     b_chnl_mst_wptr_async,
    input  logic [B_FIFO_DEPTH-1:0]     b_chnl_mst_rptr_async,
    input  logic [B_FIFO_DEPTH-1:0]     b_chnl_mst_rptr_sync,
    output logic [B_PAYLOAD_WIDTH:0]    b_chnl_mst_pld_sync,  //DATA_WIDTH+1,used for entry vld

    input  logic [AR_FIFO_DEPTH-1:0]    ar_chnl_mst_wptr_async,
    output logic [AR_FIFO_DEPTH-1:0]    ar_chnl_mst_rptr_async,
    output logic [AR_FIFO_DEPTH-1:0]    ar_chnl_mst_rptr_sync,
    input  logic [AR_PAYLOAD_WIDTH:0]   ar_chnl_mst_pld_sync,  //DATA_WIDTH+1,used for entry vld

    output logic [R_FIFO_DEPTH-1:0]     r_chnl_mst_wptr_async,
    input  logic [R_FIFO_DEPTH-1:0]     r_chnl_mst_rptr_async,
    input  logic [R_FIFO_DEPTH-1:0]     r_chnl_mst_rptr_sync,
    output logic [R_PAYLOAD_WIDTH:0]    r_chnl_mst_pld_sync  //DATA_WIDTH+1,used for entry vld
);

logic [AW_PAYLOAD_WIDTH-1:0]    aw_pld_m;
logic [W_PAYLOAD_WIDTH-1:0]     w_pld_m;
logic [B_PAYLOAD_WIDTH-1:0]     b_pld_m;
logic [AR_PAYLOAD_WIDTH-1:0]    ar_pld_m;
logic [R_PAYLOAD_WIDTH-1:0]     r_pld_m;

typedef struct packed{
    logic [ADDR_WIDTH-1:0]      addr;
    logic [AWID_WIDTH-1:0]      id;
    logic [AWUSER_WIDTH-1:0]    user;
    logic [AWLEN_WIDTH-1:0]     len;
    logic [3:0]                 region;
    logic [2:0]                 size;
    logic [1:0]                 burst;
    logic                       lock;
    logic [3:0]                 cache;
    logic [2:0]                 prot;
    logic [3:0]                 qos;
} aw_pld_t;

aw_pld_t aw_pld_m_pack;
assign aw_pld_m_pack = aw_pld_t'(aw_pld_m);

assign awuser_m     = aw_pld_m_pack.user;
assign awid_m       = aw_pld_m_pack.id;
assign awaddr_m     = aw_pld_m_pack.addr;
assign awregion_m   = aw_pld_m_pack.region;
assign awlen_m      = aw_pld_m_pack.len;
assign awsize_m     = aw_pld_m_pack.size;
assign awburst_m    = aw_pld_m_pack.burst;
assign awlock_m     = aw_pld_m_pack.lock;
assign awcache_m    = aw_pld_m_pack.cache;
assign awprot_m     = aw_pld_m_pack.prot;
assign awqos_m      = aw_pld_m_pack.qos;

typedef struct packed{
    logic [ADDR_WIDTH-1:0]      addr;
    logic [ARID_WIDTH-1:0]      id;
    logic [ARUSER_WIDTH-1:0]    user;
    logic [ARLEN_WIDTH-1:0]     len;
    logic [3:0]                 region;
    logic [2:0]                 size;
    logic [1:0]                 burst;
    logic                       lock;
    logic [3:0]                 cache;
    logic [2:0]                 prot;
    logic [3:0]                 qos;
} ar_pld_t;

ar_pld_t ar_pld_m_pack;
assign ar_pld_m_pack = ar_pld_t'(ar_pld_m);

assign aruser_m     = ar_pld_m_pack.user;
assign arid_m       = ar_pld_m_pack.id;
assign araddr_m     = ar_pld_m_pack.addr;
assign arregion_m   = ar_pld_m_pack.region;
assign arlen_m      = ar_pld_m_pack.len;
assign arsize_m     = ar_pld_m_pack.size;
assign arburst_m    = ar_pld_m_pack.burst;
assign arlock_m     = ar_pld_m_pack.lock;
assign arcache_m    = ar_pld_m_pack.cache;
assign arprot_m     = ar_pld_m_pack.prot;
assign arqos_m      = ar_pld_m_pack.qos;

typedef struct packed{
    logic [DATA_WIDTH-1:0]      data;
    logic [WUSER_WIDTH-1:0]     user;
    logic [DATA_WIDTH/8-1:0]    strb;
    logic                       last;
} w_pld_t;

w_pld_t w_pld_m_pack;
assign w_pld_m_pack = w_pld_t'(w_pld_m);

assign wuser_m  = w_pld_m_pack.user;
assign wdata_m  = w_pld_m_pack.data;
assign wstrb_m  = w_pld_m_pack.strb;
assign wlast_m  = w_pld_m_pack.last;

typedef struct packed{
    logic [BUSER_WIDTH-1:0]     user;
    logic [AWID_WIDTH-1:0]      id;
    logic [1:0]                 resp;
} b_pld_t;

b_pld_t b_pld_pack;

assign b_pld_pack.user  = buser_m;
assign b_pld_pack.id    = bid_m;
assign b_pld_pack.resp  = bresp_m;

assign b_pld_m          = b_pld_pack;

typedef struct packed{
    logic [DATA_WIDTH-1:0]      data;
    logic [RUSER_WIDTH-1:0]     user;
    logic [ARID_WIDTH-1:0]      id;
    logic                       last;
    logic [1:0]                 resp;
} r_pld_t;

r_pld_t r_pld_pack;

assign r_pld_pack.data  = rdata_m;
assign r_pld_pack.user  = ruser_m;
assign r_pld_pack.id    = rid_m;
assign r_pld_pack.last  = rlast_m;
assign r_pld_pack.resp  = rresp_m;

assign r_pld_m          = r_pld_pack;

//assign aw_pld_m = {awqos_m, awprot_m, awcache_m, awlock_m,
//                    awburst_m, awsize_m, awlen_m, awregion_m, awaddr_m,
//                    awid_m,awuser_m};
//
//assign w_pld_m  = {wlast_m, wstrb_m, wdata_m, wuser_m};
//
//assign b_pld_m  = {bresp_m, bid_m, buser_m};
//
//assign ar_pld_m = {arqos_m, arprot_m, arcache_m, arlock_m,
//                    arburst_m, arsize_m, arlen_m, arregion_m, araddr_m,
//                    arid_m,aruser_m};
//
//assign r_pld_m  = {rlast_m, rresp_m, rdata_m,rid_m,ruser_m};

// aw channel async slv

logic            aw_chnl_mst_full_zero;
logic            aw_chnl_mst_idle;

fcip_afifo_mst #(
    .FIFO_DEPTH    (AW_FIFO_DEPTH   ),
    .DATA_WIDTH    (AW_PAYLOAD_WIDTH   ),
    .AUTO_CLEAR_EN (AUTO_CLEAR_EN),
    .THRESHOLD_EN  (0),
    .SYNC_STAGE    (SYNC_STAGE   ),
    .VT_TYPE       (VT_TYPE      )
) u_afifo_aw_chnl_mst (
    .clk           (clk           ),
    .rst_n         (rst_n         ),

    .stall         (axi_fifo_mst_stall    ),
    .clear         (axi_fifo_mst_clear    ),
    .full_zero     (aw_chnl_mst_full_zero ),
    .idle          (aw_chnl_mst_idle      ),

    .m_vld         (awvalid_m             ),
    .m_pld         (aw_pld_m              ),
    .m_rdy         (awready_m             ),

    .almost_empty  (),

    .wptr_async    (aw_chnl_mst_wptr_async     ),
    .rptr_async    (aw_chnl_mst_rptr_async     ),
    .rptr_sync     (aw_chnl_mst_rptr_sync      ),
    .pld_sync      (aw_chnl_mst_pld_sync       )
);

// w channel async slv

logic            w_chnl_mst_full_zero;
logic            w_chnl_mst_idle;

fcip_afifo_mst #(
    .FIFO_DEPTH    (W_FIFO_DEPTH   ),
    .DATA_WIDTH    (W_PAYLOAD_WIDTH   ),
    .AUTO_CLEAR_EN (AUTO_CLEAR_EN),
    .THRESHOLD_EN  (0),
    .SYNC_STAGE    (SYNC_STAGE   ),
    .VT_TYPE       (VT_TYPE      )
) u_afifo_w_chnl_mst (
    .clk           (clk           ),
    .rst_n         (rst_n         ),

    .stall         (axi_fifo_mst_stall    ),
    .clear         (axi_fifo_mst_clear    ),
    .full_zero     (w_chnl_mst_full_zero),
    .idle          (w_chnl_mst_idle   ),

    .m_vld         (wvalid_m          ),
    .m_pld         (w_pld_m           ),
    .m_rdy         (wready_m          ),

    .almost_empty  (),

    .wptr_async    (w_chnl_mst_wptr_async     ),
    .rptr_async    (w_chnl_mst_rptr_async     ),
    .rptr_sync     (w_chnl_mst_rptr_sync      ),
    .pld_sync      (w_chnl_mst_pld_sync       )
);

// B channel async slv

logic            b_chnl_mst_full_zero;

fcip_afifo_slv #(
    .FIFO_DEPTH    (B_FIFO_DEPTH   ),
    .DATA_WIDTH    (B_PAYLOAD_WIDTH),
    .AUTO_CLEAR_EN (AUTO_CLEAR_EN ),
    .THRESHOLD_EN  (0),
    .SYNC_STAGE    (SYNC_STAGE    ),
    .VT_TYPE       (VT_TYPE      )
) u_afifo_b_chnl_slv (
    .clk           (clk           ),
    .rst_n         (rst_n         ),

    .stall         (axi_fifo_mst_stall   ),
    .clear         (axi_fifo_mst_clear   ),
    .full_zero     (b_chnl_mst_full_zero ),

    .s_vld         (bvalid_m          ),
    .s_pld         (b_pld_m           ),
    .s_rdy         (bready_m          ),

    .almost_full   (),

    .wptr_async    (b_chnl_mst_wptr_async     ),
    .rptr_async    (b_chnl_mst_rptr_async     ),
    .rptr_sync     (b_chnl_mst_rptr_sync      ),
    .pld_sync      (b_chnl_mst_pld_sync       )
);

// AR channel async slv

logic            ar_chnl_mst_full_zero;
logic            ar_chnl_mst_idle;

fcip_afifo_mst #(
    .FIFO_DEPTH    (AR_FIFO_DEPTH   ),
    .DATA_WIDTH    (AR_PAYLOAD_WIDTH   ),
    .AUTO_CLEAR_EN (AUTO_CLEAR_EN),
    .THRESHOLD_EN  (0),
    .SYNC_STAGE    (SYNC_STAGE   ),
    .VT_TYPE       (VT_TYPE      )
) u_afifo_ar_chnl_mst (
    .clk           (clk           ),
    .rst_n         (rst_n         ),

    .stall         (axi_fifo_mst_stall    ),
    .clear         (axi_fifo_mst_clear    ),
    .full_zero     (ar_chnl_mst_full_zero),
    .idle          (ar_chnl_mst_idle     ),

    .m_vld         (arvalid_m          ),
    .m_pld         (ar_pld_m           ),
    .m_rdy         (arready_m          ),

    .almost_empty  (),

    .wptr_async    (ar_chnl_mst_wptr_async     ),
    .rptr_async    (ar_chnl_mst_rptr_async     ),
    .rptr_sync     (ar_chnl_mst_rptr_sync      ),
    .pld_sync      (ar_chnl_mst_pld_sync       )
);

// R channel async slv

logic            r_chnl_mst_full_zero;

fcip_afifo_slv #(
    .FIFO_DEPTH    (R_FIFO_DEPTH   ),
    .DATA_WIDTH    (R_PAYLOAD_WIDTH   ),
    .AUTO_CLEAR_EN (AUTO_CLEAR_EN),
    .THRESHOLD_EN  (0),
    .SYNC_STAGE    (SYNC_STAGE   ),
    .VT_TYPE       (VT_TYPE      )
) u_afifo_r_chnl_slv (
    .clk           (clk           ),
    .rst_n         (rst_n         ),

    .stall         (axi_fifo_mst_stall     ),
    .clear         (axi_fifo_mst_clear     ),
    .full_zero     (r_chnl_mst_full_zero ),

    .s_vld         (rvalid_m          ),
    .s_pld         (r_pld_m           ),
    .s_rdy         (rready_m          ),

    .almost_full   (),

    .wptr_async    (r_chnl_mst_wptr_async     ),
    .rptr_async    (r_chnl_mst_rptr_async     ),
    .rptr_sync     (r_chnl_mst_rptr_sync      ),
    .pld_sync      (r_chnl_mst_pld_sync       )
);

// control and status signal

assign axi_fifo_mst_full_zero = r_chnl_mst_full_zero && ar_chnl_mst_full_zero && b_chnl_mst_full_zero && 
                                    w_chnl_mst_full_zero && aw_chnl_mst_full_zero;

endmodule