module fcip_req_rsp_afifo_mst #(
    parameter integer unsigned SYNC_STAGE       = 3     ,
    parameter integer unsigned FIFO_DEPTH       = 16    ,
    parameter integer unsigned AUTO_CLEAR_EN    = 1     ,
    parameter integer unsigned REQ_WIDTH        = 32    ,
    parameter integer unsigned RSP_WIDTH        = 32    ,
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

afifo_mst #(
    .FIFO_DEPTH     (FIFO_DEPTH),
    .DATA_WIDTH     (REQ_WIDTH+1),
    .AUTO_CLEAR_EN  (AUTO_CLEAR_EN),
    .SYNC_STAGE     (SYNC_STAGE)
) u_req_afifo_dst(
    .rclk           (clk),
    .rrst_n         (rst_n),

    .read_stall     (1'b0),
    .read_clear     (1'b0),
    .read_full_zero (rsp_full_zero),
    .read_idle      (idle),

    .read_resp_vld  (req_ext_s_vld),
    .read_resp_pld  (req_ext_s_pld),
    .read_resp_rdy  (req_ext_s_rdy),

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

    afifo_slv #(
        .FIFO_DEPTH     (FIFO_DEPTH),
        .DATA_WIDTH     (RSP_WIDTH+1),
        .AUTO_CLEAR_EN  (AUTO_CLEAR_EN),
        .SYNC_STAGE     (SYNC_STAGE)
    ) u_rsp_afifo_src(
        .wclk           (clk),
        .wrst_n         (rst_n),
    
        .write_stall    (1'b0),
        .write_clear    (1'b0),
        .write_full_zero(req_full_zero),
    
        .write_req_vld  (rsp_ext_m_vld),
        .write_req_pld  (rsp_ext_m_pld),
        .write_req_rdy  (rsp_ext_m_rdy),
    
        .wptr_async     (rsp_wptr_async),
        .rptr_async     (rsp_rptr_async),
        .rptr_sync      (rsp_rptr_sync),
        .pld_sync       (rsp_pld_sync)
    );

    assign rsp_ext_m_vld = rsp_m_vld;
    assign rsp_ext_m_pld = {rsp_m_pld,rsp_m_last};
    assign rsp_m_rdy     = rsp_ext_m_rdy;

endmodule