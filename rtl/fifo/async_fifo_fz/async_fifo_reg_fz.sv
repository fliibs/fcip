module async_fifo_reg_fz #(
    parameter integer unsigned FIFO_DEPTH = 16,
    parameter integer unsigned FIFO_WIDTH = 16,
    parameter integer unsigned FULL_ZERO  = 0
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
    input  logic [FIFO_WIDTH-1:0]   write_req_pld,
    output logic                    write_req_rdy,

    //read response
    output logic                    read_resp_vld,
    output logic [FIFO_WIDTH-1:0]   read_resp_pld,
    input  logic                    read_resp_rdy
);

logic [FIFO_DEPTH-1:0]   wptr_async;
logic [FIFO_DEPTH-1:0]   rptr_async;
logic [FIFO_DEPTH-1:0]   rptr_sync;
logic [FIFO_WIDTH:0]     pld_sync;

afifo_write_fz_wrap #(
    .FIFO_DEPTH (FIFO_DEPTH),
    .FIFO_WIDTH (FIFO_WIDTH),
    .FULL_ZERO  (FULL_ZERO)
) u_afifo_write_domain(
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

afifo_read_fz_wrap #(
    .FIFO_DEPTH (FIFO_DEPTH),
    .FIFO_WIDTH (FIFO_WIDTH)
) u_afifo_read_domain(
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