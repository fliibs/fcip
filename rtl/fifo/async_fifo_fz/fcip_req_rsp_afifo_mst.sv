module fcip_req_rsp_afifo_mst #(
    parameter integer unsigned SYNC_STAGE   = 3     ,
    parameter integer unsigned FIFO_DEPTH   = 16    ,
    parameter integer unsigned AUTO_CLEAR   = 1     ,
    parameter integer unsigned REQ_WIDTH    = 32    ,
    parameter integer unsigned RSP_WIDTH    = 32
)(
    input  logic                    clk,
    input  logic                    rst_n,

    // request master interface
    output  logic                   req_s_vld       ,
    input   logic                   req_s_rdy       ,
    output  logic [REQ_WIDTH-1:0]   req_s_pld       ,
    output  logic                   req_s_last      ,

    // response slave interface
    input   logic                   rsp_m_vld       ,
    output  logic                   rsp_m_rdy       ,
    input   logic [RSP_WIDTH-1:0]   rsp_m_pld       ,  
    input   logic                   rsp_m_last      ,

    // request sync
    input   logic [FIFO_DEPTH-1:0]  req_wptr_async  ,
    output  logic [FIFO_DEPTH-1:0]  req_rptr_async  ,
    output  logic [FIFO_DEPTH-1:0]  req_rptr_sync   ,
    input   logic [REQ_WIDTH-1:0]   req_pld_sync    ,

    // response sync
    output  logic [FIFO_DEPTH-1:0]  rsp_wptr_async  ,
    input   logic [FIFO_DEPTH-1:0]  rsp_rptr_async  ,
    input   logic [FIFO_DEPTH-1:0]  rsp_rptr_sync   ,
    output  logic [RSP_WIDTH:0]     rsp_pld_sync    
);


    // request async fifo slv


    // response async fifo mst






endmodule