module async_fifo #(
    parameter  integer unsigned FIFO_DEPTH = 16,
    parameter  integer unsigned FIFO_WIDTH = 16
)(
    input  logic                    wclk,
    input  logic                    rclk,
    input  logic                    wrst_n,
    input  logic                    rrst_n,

    //power down
    input  logic                    stall,
    input  logic                    clear,
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
logic [FIFO_WIDTH-1:0]   pld_sync;

afifo_write_domain #(
    .FIFO_DEPTH (FIFO_DEPTH),
    .FIFO_WIDTH (FIFO_WIDTH)
) u_afifo_write_domain(
    .wclk           (wclk),
    .wrst_n         (wrst_n),
    .stall          (stall),
    .clear          (clear),
    .write_req_vld  (write_req_vld),
    .write_req_pld  (write_req_pld),
    .write_req_rdy  (write_req_rdy),
    .wptr_async     (wptr_async),
    .rptr_async     (rptr_async),
    .rptr_sync      (rptr_sync),
    .pld_sync       (pld_sync)
);

afifo_read_domain #(
    .FIFO_DEPTH (FIFO_DEPTH),
    .FIFO_WIDTH (FIFO_WIDTH)
) u_afifo_read_domain(
    .rclk           (rclk),
    .rrst_n         (rrst_n),
    .stall          (stall),
    .clear          (clear),
    .idle           (idle),
    .read_resp_vld  (read_resp_vld),
    .read_resp_pld  (read_resp_pld),
    .read_resp_rdy  (read_resp_rdy),
    .wptr_async     (wptr_async),
    .rptr_async     (rptr_async),
    .rptr_sync      (rptr_sync),
    .pld_sync       (pld_sync)
    );

endmodule