module afifo_read_fz_wrap #(
    parameter integer unsigned FIFO_DEPTH = 16,
    parameter integer unsigned FIFO_WIDTH = 16
)(
    input  logic                    rclk,
    input  logic                    rrst_n,
    //power down
    input  logic                    read_stall,
    input  logic                    read_clear,
    output logic                    read_full_zero,
    output logic                    read_idle,

    //read response
    output logic                    read_resp_vld,
    output logic [FIFO_WIDTH-1:0]   read_resp_pld,
    input  logic                    read_resp_rdy,

    //control signals
    input  logic [FIFO_DEPTH-1:0]   wptr_async,

    output logic [FIFO_DEPTH-1:0]   rptr_async,
    output logic [FIFO_DEPTH-1:0]   rptr_sync,
    input  logic [FIFO_WIDTH:0]     pld_sync
);

logic                   read_resp_with_bubble_vld;
logic [FIFO_WIDTH:0]    read_resp_with_bubble_pld;
logic                   bubble_en;
logic                   read_resp_mask;

/*========================================*/
/*               read stall               */
/*========================================*/

assign bubble_en        = ~read_resp_with_bubble_pld[0];
assign read_resp_mask   = read_stall || bubble_en;
assign read_resp_vld    = read_resp_with_bubble_vld && ~read_resp_mask;
assign read_resp_pld    = read_resp_with_bubble_pld[FIFO_WIDTH-1:1];

/*========================================*/
/*               read domain              */
/*========================================*/

afifo_read_domain_fz #(
    .FIFO_DEPTH (FIFO_DEPTH),
    .FIFO_WIDTH (FIFO_WIDTH+1)
) u_afifo_read_domain(
    .rclk           (rclk),
    .rrst_n         (rrst_n),

    .read_clear     (read_clear),
    .read_full_zero (read_full_zero),
    .read_idle      (read_idle),

    .read_resp_vld  (read_resp_with_bubble_vld),
    .read_resp_pld  (read_resp_with_bubble_pld),
    .read_resp_rdy  (read_resp_rdy),

    .wptr_async     (wptr_async),
    .rptr_async     (rptr_async),
    .rptr_sync      (rptr_sync),
    .pld_sync       (pld_sync)
);

endmodule