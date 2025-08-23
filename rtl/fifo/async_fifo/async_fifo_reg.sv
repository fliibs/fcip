module async_fifo_reg #(
    parameter  integer unsigned FIFO_DEPTH = 16,
    parameter  integer unsigned DATA_WIDTH = 16,
    parameter integer unsigned  AUTO_CLEAR_EN  = 0,
    parameter integer unsigned  SYNC_STAGE = 2
)(
    input  logic                    wclk,
    input  logic                    rclk,
    input  logic                    wrst_n,
    input  logic                    rrst_n,

    //power down
    input  logic                    read_stall,
    input  logic                    write_stall,
    input  logic                    read_clear,
    input  logic                    write_clear,

    output logic                    read_full_zero,
    output logic                    write_full_zero,

    output logic                    idle,

    //write req
    input  logic                    write_req_vld,
    input  logic [DATA_WIDTH-1:0]   write_req_pld,
    output logic                    write_req_rdy,

    //read response
    output logic                    read_resp_vld,
    output logic [DATA_WIDTH-1:0]   read_resp_pld,
    input  logic                    read_resp_rdy
);

logic [FIFO_DEPTH-1:0]   wptr_async;
logic [FIFO_DEPTH-1:0]   rptr_async;
logic [FIFO_DEPTH-1:0]   rptr_sync;
logic [DATA_WIDTH:0]     pld_sync;

afifo_slv #(
    .FIFO_DEPTH     (FIFO_DEPTH),
    .DATA_WIDTH     (DATA_WIDTH),
    .AUTO_CLEAR_EN  (AUTO_CLEAR_EN),
    .SYNC_STAGE     (SYNC_STAGE)
) u_afifo_slv(
    .wclk           (wclk),
    .wrst_n         (wrst_n),

    .write_stall    (write_stall),
    .write_clear    (write_clear),
    .write_full_zero(write_full_zero),

    .write_req_vld  (write_req_vld),
    .write_req_pld  (write_req_pld),
    .write_req_rdy  (write_req_rdy),

    .wptr_async     (wptr_async),
    .rptr_async     (rptr_async),
    .rptr_sync      (rptr_sync),
    .pld_sync       (pld_sync)
);

afifo_mst #(
    .FIFO_DEPTH     (FIFO_DEPTH),
    .DATA_WIDTH     (DATA_WIDTH),
    .AUTO_CLEAR_EN  (AUTO_CLEAR_EN),
    .SYNC_STAGE     (SYNC_STAGE)
) u_afifo_mst(
    .rclk           (rclk),
    .rrst_n         (rrst_n),

    .read_stall     (read_stall),
    .read_clear     (read_clear),
    .read_full_zero (read_full_zero),
    .read_idle      (idle),

    .read_resp_vld  (read_resp_vld),
    .read_resp_pld  (read_resp_pld),
    .read_resp_rdy  (read_resp_rdy),

    .wptr_async     (wptr_async),
    .rptr_async     (rptr_async),
    .rptr_sync      (rptr_sync),
    .pld_sync       (pld_sync)
    );

endmodule