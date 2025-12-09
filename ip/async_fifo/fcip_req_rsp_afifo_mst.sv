module fcip_req_rsp_afifo_mst #(
    parameter integer unsigned SYNC_STAGE       = 3     ,
    parameter integer unsigned FIFO_DEPTH       = 16    ,
    parameter integer unsigned AUTO_CLEAR_EN    = 1     ,
    parameter integer unsigned REQ_WIDTH        = 32    ,
    parameter integer unsigned RSP_WIDTH        = 32    ,
    parameter integer unsigned VT_TYPE          = 1     ,// 0: SVT, 1: LVT, 2: ULVT, 3: ELVT, 4: LVTLL, 5: ULVTLL
    localparam int unsigned PLD_SYNC_WIDTH      = REQ_WIDTH+1
)(
    input  logic                        clk,
    input  logic                        rst_n,

    // request master interface
    output  logic                       req_s_vld       ,
    input   logic                       req_s_rdy       ,
    output  logic [REQ_WIDTH-1:0]       req_s_pld       ,
    output  logic                       req_s_last      ,

    // response slave interface
    input   logic                       rsp_m_vld       ,
    output  logic                       rsp_m_rdy       ,
    input   logic [RSP_WIDTH-1:0]       rsp_m_pld       ,  
    input   logic                       rsp_m_last      ,

    // request sync
    input   logic [FIFO_DEPTH-1:0]      req_wptr_async  ,
    output  logic [FIFO_DEPTH-1:0]      req_rptr_async  ,
    output  logic [FIFO_DEPTH-1:0]      req_rptr_sync   ,
    input   logic [PLD_SYNC_WIDTH:0]    req_pld_sync    ,

    // response sync
    output  logic [FIFO_DEPTH-1:0]      rsp_wptr_async  ,
    input   logic [FIFO_DEPTH-1:0]      rsp_rptr_async  ,
    input   logic [FIFO_DEPTH-1:0]      rsp_rptr_sync   ,
    output  logic [PLD_SYNC_WIDTH:0]    rsp_pld_sync    
);

logic                   req_ext_s_vld ;
logic                   req_ext_s_rdy ;
logic [REQ_WIDTH:0]     req_ext_s_pld ;
logic                   req_ext_s_last;

logic                   rsp_ext_m_vld ;
logic                   rsp_ext_m_rdy ;
logic [REQ_WIDTH:0]     rsp_ext_m_pld ;
logic                   rsp_ext_m_last;

// request async fifo mst

fcip_afifo_mst #(
    .FIFO_DEPTH     (FIFO_DEPTH),
    .DATA_WIDTH     (REQ_WIDTH+1),
    .AUTO_CLEAR_EN  (AUTO_CLEAR_EN),
    .THRESHOLD_EN   (0),
    .SYNC_STAGE     (SYNC_STAGE),
    .VT_TYPE        (VT_TYPE      )
) u_req_afifo_dst(
    .clk            (clk),
    .rst_n          (rst_n),

    .stall          (1'b0),
    .clear          (1'b0),
    .full_zero      (),
    .idle           (),

    .m_vld          (req_ext_s_vld),
    .m_pld          (req_ext_s_pld),
    .m_rdy          (req_ext_s_rdy),

    .almost_empty   (),

    .wptr_async     (req_wptr_async),
    .rptr_async     (req_rptr_async),
    .rptr_sync      (req_rptr_sync),
    .pld_sync       (req_pld_sync)
);

    assign req_s_last   = req_ext_s_pld[0];
    assign req_s_pld    = req_ext_s_pld[REQ_WIDTH:1];
    assign req_s_vld    = req_ext_s_vld;
    assign req_ext_s_rdy= req_s_rdy;

    // response async fifo slv

fcip_afifo_slv #(
    .FIFO_DEPTH     (FIFO_DEPTH),
    .DATA_WIDTH     (RSP_WIDTH+1),
    .AUTO_CLEAR_EN  (AUTO_CLEAR_EN),
    .THRESHOLD_EN   (0),
    .SYNC_STAGE     (SYNC_STAGE),
    .VT_TYPE        (VT_TYPE      )
) u_rsp_afifo_src(
    .clk            (clk),
    .rst_n          (rst_n),

    .stall          (1'b0),
    .clear          (1'b0),
    .full_zero      (),

    .s_vld          (rsp_ext_m_vld),
    .s_pld          (rsp_ext_m_pld),
    .s_rdy          (rsp_ext_m_rdy),

    .almost_full    (),

    .wptr_async     (rsp_wptr_async),
    .rptr_async     (rsp_rptr_async),
    .rptr_sync      (rsp_rptr_sync),
    .pld_sync       (rsp_pld_sync)
);

    assign rsp_ext_m_vld = rsp_m_vld;
    assign rsp_ext_m_pld = {rsp_m_pld,rsp_m_last};
    assign rsp_m_rdy     = rsp_ext_m_rdy;

endmodule