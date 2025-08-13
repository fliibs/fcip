module fcip_req_rsp_afifo_slv #(
    parameter integer unsigned SYNC_STAGE   = 3     ,
    parameter integer unsigned FIFO_DEPTH   = 16    ,
    parameter integer unsigned AUTO_CLEAR   = 1     ,
    parameter integer unsigned REQ_WIDTH    = 32    ,
    parameter integer unsigned RSP_WIDTH    = 32
)(
    input  logic                    clk,
    input  logic                    rst_n,

    //input  logic                    read_stall,
    //input  logic                    read_clear,
    //output logic                    read_full_zero,
    //output logic                    read_idle,


    // request slave interface
    input   logic                   req_s_vld       ,
    output  logic                   req_s_rdy       ,
    input   logic [REQ_WIDTH-1:0]   req_s_pld       ,
    input   logic                   req_s_last      ,

    // response master interface
    output  logic                   rsp_m_vld       ,
    input   logic                   rsp_m_rdy       ,
    output  logic [RSP_WIDTH-1:0]   rsp_m_pld       ,
    output  logic                   rsp_m_last      ,

    // request sync
    output  logic [FIFO_DEPTH-1:0]  req_wptr_async  ,
    input   logic [FIFO_DEPTH-1:0]  req_rptr_async  ,
    input   logic [FIFO_DEPTH-1:0]  req_rptr_sync   ,
    output  logic [REQ_WIDTH-1:0]   req_pld_sync    ,

    // response sync
    input   logic [FIFO_DEPTH-1:0]  rsp_wptr_async  ,
    output  logic [FIFO_DEPTH-1:0]  rsp_rptr_async  ,
    output  logic [FIFO_DEPTH-1:0]  rsp_rptr_sync   ,
    input   logic [RSP_WIDTH:0]     rsp_pld_sync    
);


    // request async fifo slv


    // response async fifo mst


    // transaction counter


    // stall buffer for waiting for async fifo clear




endmodule