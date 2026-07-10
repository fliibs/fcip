module fcip_req_rsp_afifo #(
    parameter integer unsigned SYNC_STAGE       = 3     ,
    parameter integer unsigned FIFO_DEPTH       = 16    ,
    parameter integer unsigned AUTO_CLEAR_EN    = 1     ,
    parameter integer unsigned REQ_WIDTH        = 32    ,
    parameter integer unsigned RSP_WIDTH        = 32    ,
    parameter integer unsigned VT_TYPE          = 1     ,// 0: SVT, 1: LVT, 2: ULVT, 3: ELVT, 4: LVTLL, 5: ULVTLL
    localparam int unsigned REQ_SYNC_WIDTH      = REQ_WIDTH+1,
    localparam int unsigned RSP_SYNC_WIDTH      = RSP_WIDTH+1
)(
    input  logic                        clk,
    input  logic                        rst_n,

    // slave request slave interface
    input   logic                       slv_req_s_vld       ,
    output  logic                       slv_req_s_rdy       ,
    input   logic [REQ_WIDTH-1:0]       slv_req_s_pld       ,
    input   logic                       slv_req_s_last      ,

    // slave response master interface
    output  logic                       slv_rsp_m_vld       ,
    input   logic                       slv_rsp_m_rdy       ,
    output  logic [RSP_WIDTH-1:0]       slv_rsp_m_pld       ,
    output  logic                       slv_rsp_m_last      ,

    // master request master interface
    output  logic                       mst_req_s_vld       ,
    input   logic                       mst_req_s_rdy       ,
    output  logic [REQ_WIDTH-1:0]       mst_req_s_pld       ,
    output  logic                       mst_req_s_last      ,

    // master response slave interface
    input   logic                       mst_rsp_m_vld       ,
    output  logic                       mst_rsp_m_rdy       ,
    input   logic [RSP_WIDTH-1:0]       mst_rsp_m_pld       ,  
    input   logic                       mst_rsp_m_last      

);

// request sync
logic [FIFO_DEPTH-1:0]      req_wptr_async  ;
logic [FIFO_DEPTH-1:0]      req_rptr_async  ;
logic [FIFO_DEPTH-1:0]      req_rptr_sync   ;
logic [REQ_SYNC_WIDTH:0]    req_pld_sync    ;

// response sync
logic [FIFO_DEPTH-1:0]      rsp_wptr_async  ;
logic [FIFO_DEPTH-1:0]      rsp_rptr_async  ;
logic [FIFO_DEPTH-1:0]      rsp_rptr_sync   ;
logic [RSP_SYNC_WIDTH:0]    rsp_pld_sync    ;

fcip_req_rsp_afifo_slv #(
    .SYNC_STAGE    (SYNC_STAGE ),
    .FIFO_DEPTH    (FIFO_DEPTH),
    .AUTO_CLEAR_EN (AUTO_CLEAR_EN ),
    .REQ_WIDTH     (REQ_WIDTH),
    .RSP_WIDTH     (RSP_WIDTH),
    .VT_TYPE       (VT_TYPE      )
)u_fcip_req_rsp_afifo_slv(
    .clk                (clk),
    .rst_n              (rst_n),

    .req_s_vld          (slv_req_s_vld ),
    .req_s_rdy          (slv_req_s_rdy ),
    .req_s_pld          (slv_req_s_pld ),
    .req_s_last         (slv_req_s_last),

    .rsp_m_vld          (slv_rsp_m_vld ),
    .rsp_m_rdy          (slv_rsp_m_rdy ),
    .rsp_m_pld          (slv_rsp_m_pld ),
    .rsp_m_last         (slv_rsp_m_last),

    .req_wptr_async     (req_wptr_async),
    .req_rptr_async     (req_rptr_async),
    .req_rptr_sync      (req_rptr_sync ),
    .req_pld_sync       (req_pld_sync  ),

    .rsp_wptr_async     (rsp_wptr_async),
    .rsp_rptr_async     (rsp_rptr_async),
    .rsp_rptr_sync      (rsp_rptr_sync ),
    .rsp_pld_sync       (rsp_pld_sync  )    
);

fcip_req_rsp_afifo_mst #(
    .SYNC_STAGE     (SYNC_STAGE   ),
    .FIFO_DEPTH     (FIFO_DEPTH   ),
    .AUTO_CLEAR_EN  (AUTO_CLEAR_EN),
    .REQ_WIDTH      (REQ_WIDTH    ),
    .RSP_WIDTH      (RSP_WIDTH    ),
    .VT_TYPE        (VT_TYPE      )
)u_fcip_req_rsp_afifo_mst(
    .clk                (clk),
    .rst_n              (rst_n),

    .req_s_vld          (mst_req_s_vld ),
    .req_s_rdy          (mst_req_s_rdy ),
    .req_s_pld          (mst_req_s_pld ),
    .req_s_last         (mst_req_s_last),

    .rsp_m_vld          (mst_rsp_m_vld ),
    .rsp_m_rdy          (mst_rsp_m_rdy ),
    .rsp_m_pld          (mst_rsp_m_pld ),  
    .rsp_m_last         (mst_rsp_m_last),

    .req_wptr_async     (req_wptr_async),
    .req_rptr_async     (req_rptr_async),
    .req_rptr_sync      (req_rptr_sync ),
    .req_pld_sync       (req_pld_sync  ),

    .rsp_wptr_async     (rsp_wptr_async),
    .rsp_rptr_async     (rsp_rptr_async),
    .rsp_rptr_sync      (rsp_rptr_sync ),
    .rsp_pld_sync       (rsp_pld_sync  )
);

endmodule