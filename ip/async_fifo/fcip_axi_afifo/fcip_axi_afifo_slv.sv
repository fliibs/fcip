module fcip_axi_afifo_slv #(
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
    parameter integer unsigned VT_TYPE          = 1,// 0: SVT, 1: LVT, 2: ULVT, 3: ELVT, 4: LVTLL, 5: ULVTLL
    localparam int unsigned    AW_PAYLOAD_WIDTH = AWUSER_WIDTH + AWID_WIDTH + ADDR_WIDTH +
                                4 + //region
                                8 + //length
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
    localparam int unsigned    AR_PAYLOAD_WIDTH = ARUSER_WIDTH + ARID_WIDTH + ADDR_WIDTH +
                                4 + //region
                                8 + //length
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
    input   logic            axi_fifo_slv_stall,
    input   logic            axi_fifo_slv_clear,
    output  logic            axi_fifo_slv_full_zero,

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

    //control pointer
    output logic [AW_FIFO_DEPTH-1:0]    aw_chnl_slv_wptr_async,
    input  logic [AW_FIFO_DEPTH-1:0]    aw_chnl_slv_rptr_async,
    input  logic [AW_FIFO_DEPTH-1:0]    aw_chnl_slv_rptr_sync,
    output logic [AW_PAYLOAD_WIDTH:0]   aw_chnl_slv_pld_sync,  //DATA_WIDTH+1,used for entry vld

    output logic [W_FIFO_DEPTH-1:0]     w_chnl_slv_wptr_async,
    input  logic [W_FIFO_DEPTH-1:0]     w_chnl_slv_rptr_async,
    input  logic [W_FIFO_DEPTH-1:0]     w_chnl_slv_rptr_sync,
    output logic [W_PAYLOAD_WIDTH:0]    w_chnl_slv_pld_sync,  //DATA_WIDTH+1,used for entry vld

    input  logic [B_FIFO_DEPTH-1:0]     b_chnl_slv_wptr_async,
    output logic [B_FIFO_DEPTH-1:0]     b_chnl_slv_rptr_async,
    output logic [B_FIFO_DEPTH-1:0]     b_chnl_slv_rptr_sync,
    input  logic [B_PAYLOAD_WIDTH:0]    b_chnl_slv_pld_sync,  //DATA_WIDTH+1,used for entry vld

    output logic [AR_FIFO_DEPTH-1:0]    ar_chnl_slv_wptr_async,
    input  logic [AR_FIFO_DEPTH-1:0]    ar_chnl_slv_rptr_async,
    input  logic [AR_FIFO_DEPTH-1:0]    ar_chnl_slv_rptr_sync,
    output logic [AR_PAYLOAD_WIDTH:0]   ar_chnl_slv_pld_sync,  //DATA_WIDTH+1,used for entry vld

    input  logic [R_FIFO_DEPTH-1:0]     r_chnl_slv_wptr_async,
    output logic [R_FIFO_DEPTH-1:0]     r_chnl_slv_rptr_async,
    output logic [R_FIFO_DEPTH-1:0]     r_chnl_slv_rptr_sync,
    input  logic [R_PAYLOAD_WIDTH:0]    r_chnl_slv_pld_sync  //DATA_WIDTH+1,used for entry vld
);

logic [AW_PAYLOAD_WIDTH-1:0]    aw_pld_s;
logic [W_PAYLOAD_WIDTH-1:0]     w_pld_s;
logic [B_PAYLOAD_WIDTH-1:0]     b_pld_s;
logic [AR_PAYLOAD_WIDTH-1:0]    ar_pld_s;
logic [R_PAYLOAD_WIDTH-1:0]     r_pld_s;

//assign aw_pld_s = {awqos_s, awprot_s, awcache_s, awlock_s,
//                    awburst_s, awsize_s, awlen_s, awregion_s, awaddr_s,
//                    awid_s,awuser_s};
//
//assign w_pld_s  = {wlast_s, wstrb_s, wdata_s, wuser_s};
//
//assign b_pld_s  = {bresp_s, bid_s, buser_s};
//
//assign ar_pld_s = {arqos_s, arprot_s, arcache_s, arlock_s,
//                    arburst_s, arsize_s, arlen_s, arregion_s, araddr_s,
//                    arid_s,aruser_s};
//
//assign r_pld_s  = {rlast_s, rresp_s, rdata_s,rid_s,ruser_s};

//aw pld pack
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

aw_pld_t aw_pld_s_pack;

assign aw_pld_s_pack.user       = awuser_s;
assign aw_pld_s_pack.id         = awid_s;
assign aw_pld_s_pack.addr       = awaddr_s;
assign aw_pld_s_pack.region     = awregion_s;
assign aw_pld_s_pack.len        = awlen_s;
assign aw_pld_s_pack.size       = awsize_s;
assign aw_pld_s_pack.burst      = awburst_s;
assign aw_pld_s_pack.lock       = awlock_s;
assign aw_pld_s_pack.cache      = awcache_s;
assign aw_pld_s_pack.prot       = awprot_s;
assign aw_pld_s_pack.qos        = awqos_s;

assign aw_pld_s                 = aw_pld_s_pack;

//ar pld pack
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

ar_pld_t ar_pld_s_pack;

assign ar_pld_s_pack.user       = aruser_s;
assign ar_pld_s_pack.id         = arid_s;
assign ar_pld_s_pack.addr       = araddr_s;
assign ar_pld_s_pack.region     = arregion_s;
assign ar_pld_s_pack.len        = arlen_s;
assign ar_pld_s_pack.size       = arsize_s;
assign ar_pld_s_pack.burst      = arburst_s;
assign ar_pld_s_pack.lock       = arlock_s;
assign ar_pld_s_pack.cache      = arcache_s;
assign ar_pld_s_pack.prot       = arprot_s;
assign ar_pld_s_pack.qos        = arqos_s;

assign ar_pld_s                 = ar_pld_s_pack;

//w pld pack
typedef struct packed{
    logic [DATA_WIDTH-1:0]      data;
    logic [WUSER_WIDTH-1:0]     user;
    logic [DATA_WIDTH/8-1:0]    strb;
    logic                       last;
} w_pld_t;

w_pld_t w_pld_s_pack;

assign w_pld_s_pack.user    = wuser_s;
assign w_pld_s_pack.data    = wdata_s;
assign w_pld_s_pack.strb    = wstrb_s;
assign w_pld_s_pack.last    = wlast_s;

assign w_pld_s = w_pld_s_pack;

//b pld pack

typedef struct packed{
    logic [BUSER_WIDTH-1:0]     user;
    logic [AWID_WIDTH-1:0]      id;
    logic [1:0]                 resp;
} b_pld_t;

b_pld_t b_pld_s_pack;

assign b_pld_s_pack = b_pld_t'(b_pld_s);

assign buser_s  = b_pld_s_pack.user;
assign bid_s    = b_pld_s_pack.id;
assign bresp_s  = b_pld_s_pack.resp;

//r pld pack

typedef struct packed{
    logic [DATA_WIDTH-1:0]      data;
    logic [RUSER_WIDTH-1:0]     user;
    logic [ARID_WIDTH-1:0]      id;
    logic                       last;
    logic [1:0]                 resp;
} r_pld_t;

r_pld_t r_pld_s_pack;

assign r_pld_s_pack = r_pld_t'(r_pld_s);

assign ruser_s      = r_pld_s_pack.user;
assign rid_s        = r_pld_s_pack.id;
assign rdata_s      = r_pld_s_pack.data;
assign rresp_s      = r_pld_s_pack.resp;
assign rlast_s      = r_pld_s_pack.last;

// aw channel async slv

logic            aw_chnl_slv_full_zero;

fcip_afifo_slv #(
    .FIFO_DEPTH    (AW_FIFO_DEPTH   ),
    .DATA_WIDTH    (AW_PAYLOAD_WIDTH   ),
    .AUTO_CLEAR_EN (AUTO_CLEAR_EN),
    .THRESHOLD_EN  (0),
    .SYNC_STAGE    (SYNC_STAGE   ),
    .VT_TYPE       (VT_TYPE      )
) u_afifo_aw_chnl_slv (
    .clk           (clk           ),
    .rst_n         (rst_n         ),

    .stall         (axi_fifo_slv_stall    ),
    .clear         (axi_fifo_slv_clear    ),
    .full_zero     (aw_chnl_slv_full_zero),

    .s_vld         (awvalid_s          ),
    .s_pld         (aw_pld_s           ),
    .s_rdy         (awready_s          ),

    .almost_full   (),

    .wptr_async    (aw_chnl_slv_wptr_async     ),
    .rptr_async    (aw_chnl_slv_rptr_async     ),
    .rptr_sync     (aw_chnl_slv_rptr_sync      ),
    .pld_sync      (aw_chnl_slv_pld_sync       )
);

// w channel async slv

//logic            w_chnl_slv_stall;
logic            w_chnl_slv_clear;
logic            w_chnl_slv_full_zero;

fcip_afifo_slv #(
    .FIFO_DEPTH    (W_FIFO_DEPTH   ),
    .DATA_WIDTH    (W_PAYLOAD_WIDTH   ),
    .AUTO_CLEAR_EN (AUTO_CLEAR_EN),
    .THRESHOLD_EN  (0),
    .SYNC_STAGE    (SYNC_STAGE   ),
    .VT_TYPE       (VT_TYPE      )
) u_afifo_w_chnl_slv (
    .clk           (clk           ),
    .rst_n         (rst_n         ),

    .stall         (axi_fifo_slv_stall    ),
    .clear         (axi_fifo_slv_clear    ),
    .full_zero     (w_chnl_slv_full_zero),

    .s_vld         (wvalid_s          ),
    .s_pld         (w_pld_s           ),
    .s_rdy         (wready_s          ),

    .almost_full   (),

    .wptr_async    (w_chnl_slv_wptr_async     ),
    .rptr_async    (w_chnl_slv_rptr_async     ),
    .rptr_sync     (w_chnl_slv_rptr_sync      ),
    .pld_sync      (w_chnl_slv_pld_sync       )
);

// B channel async slv

//logic            b_chnl_slv_stall;
//logic            b_chnl_slv_clear;
logic            b_chnl_slv_full_zero;
logic            b_chnl_slv_idle;

fcip_afifo_mst #(
    .FIFO_DEPTH    (B_FIFO_DEPTH   ),
    .DATA_WIDTH    (B_PAYLOAD_WIDTH   ),
    .AUTO_CLEAR_EN (AUTO_CLEAR_EN),
    .THRESHOLD_EN  (0),
    .SYNC_STAGE    (SYNC_STAGE   ),
    .VT_TYPE       (VT_TYPE      )
) u_afifo_b_chnl_mst (
    .clk           (clk           ),
    .rst_n         (rst_n         ),

    .stall         (axi_fifo_slv_stall     ),
    .clear         (axi_fifo_slv_clear     ),
    .full_zero     (b_chnl_slv_full_zero ),
    .idle          (b_chnl_slv_idle      ),

    .m_vld         (bvalid_s          ),
    .m_pld         (b_pld_s           ),
    .m_rdy         (bready_s          ),

    .almost_empty  (),

    .wptr_async    (b_chnl_slv_wptr_async     ),
    .rptr_async    (b_chnl_slv_rptr_async     ),
    .rptr_sync     (b_chnl_slv_rptr_sync      ),
    .pld_sync      (b_chnl_slv_pld_sync       )
);

// AR channel async slv

//logic            ar_chnl_slv_stall;
//logic            ar_chnl_slv_clear;
logic            ar_chnl_slv_full_zero;

fcip_afifo_slv #(
    .FIFO_DEPTH    (AR_FIFO_DEPTH   ),
    .DATA_WIDTH    (AR_PAYLOAD_WIDTH   ),
    .AUTO_CLEAR_EN (AUTO_CLEAR_EN),
    .THRESHOLD_EN  (0),
    .SYNC_STAGE    (SYNC_STAGE   ),
    .VT_TYPE       (VT_TYPE      )
) u_afifo_ar_chnl_slv (
    .clk           (clk           ),
    .rst_n         (rst_n         ),

    .stall         (axi_fifo_slv_stall    ),
    .clear         (axi_fifo_slv_clear    ),
    .full_zero     (ar_chnl_slv_full_zero),

    .s_vld         (arvalid_s          ),
    .s_pld         (ar_pld_s           ),
    .s_rdy         (arready_s          ),

    .almost_full   (),

    .wptr_async    (ar_chnl_slv_wptr_async     ),
    .rptr_async    (ar_chnl_slv_rptr_async     ),
    .rptr_sync     (ar_chnl_slv_rptr_sync      ),
    .pld_sync      (ar_chnl_slv_pld_sync       )
);

// R channel async slv

//logic            r_chnl_slv_stall;
//logic            r_chnl_slv_clear;
logic            r_chnl_slv_full_zero;
logic            r_chnl_slv_idle;

fcip_afifo_mst #(
    .FIFO_DEPTH    (R_FIFO_DEPTH   ),
    .DATA_WIDTH    (R_PAYLOAD_WIDTH   ),
    .AUTO_CLEAR_EN (AUTO_CLEAR_EN),
    .THRESHOLD_EN  (0),
    .SYNC_STAGE    (SYNC_STAGE   ),
    .VT_TYPE       (VT_TYPE      )
) u_afifo_r_chnl_mst (
    .clk           (clk           ),
    .rst_n         (rst_n         ),

    .stall         (axi_fifo_slv_stall     ),
    .clear         (axi_fifo_slv_clear     ),
    .full_zero     (r_chnl_slv_full_zero ),
    .idle          (r_chnl_slv_idle      ),

    .m_vld         (rvalid_s          ),
    .m_pld         (r_pld_s           ),
    .m_rdy         (rready_s          ),

    .almost_empty  (),

    .wptr_async    (r_chnl_slv_wptr_async     ),
    .rptr_async    (r_chnl_slv_rptr_async     ),
    .rptr_sync     (r_chnl_slv_rptr_sync      ),
    .pld_sync      (r_chnl_slv_pld_sync       )
);

// control and status signal

assign axi_fifo_slv_full_zero = r_chnl_slv_full_zero && ar_chnl_slv_full_zero && b_chnl_slv_full_zero && 
                                    w_chnl_slv_full_zero && aw_chnl_slv_full_zero;

endmodule