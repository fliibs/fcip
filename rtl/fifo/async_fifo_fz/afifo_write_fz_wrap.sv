module afifo_write_fz_wrap #(
    parameter  integer unsigned FIFO_DEPTH = 16,
    parameter  integer unsigned FIFO_WIDTH = 16,
    parameter  integer unsigned FULL_ZERO  = 0
)(
    input  logic                    wclk,
    input  logic                    wrst_n,

    //power down & full zero
    input  logic                    write_stall,
    input  logic                    write_clear,
    output logic                    write_full_zero,

    //write req
    input  logic                    write_req_vld,
    input  logic [FIFO_WIDTH-1:0]   write_req_pld,
    output logic                    write_req_rdy,

    //control signals
    output logic [FIFO_DEPTH-1:0]   wptr_async,

    input  logic [FIFO_DEPTH-1:0]   rptr_async,
    input  logic [FIFO_DEPTH-1:0]   rptr_sync,
    output logic [FIFO_WIDTH:0]     pld_sync
);

logic                   write_req_vld_flag;
logic [FIFO_WIDTH:0]    write_req_pld_flag;
logic                   bubble_req_vld;
logic [FIFO_WIDTH:0]    bubble_req_pld;

logic                   write_req_with_bubble_vld;
logic [FIFO_WIDTH:0]    write_req_with_bubble_pld;
logic                   write_req_with_bubble_rdy;
logic                   bubble_gen_rdy;

/*========================================*/
/*               Bubble Gen               */
/*========================================*/

assign bubble_req_vld = bubble_gen_rdy && (FULL_ZERO==1);
assign bubble_req_pld = {(FIFO_WIDTH+1){1'b0}};

/*========================================*/
/*               fixed arbiter            */
/*========================================*/

assign write_req_pld_flag = {write_req_pld,1'b1}; // bit[0] is 1(normal), is 0(bubble)
assign write_req_vld_flag = write_req_vld && ~write_stall;

cmn_fix_arb #(
    .PLD_TYPE(logic [FIFO_WIDTH:0])
)u_write_req_arbiter(
    .clk            (wclk),
    .rst_n          (wrst_n),

    .s_vld_priority (write_req_vld_flag),
    .s_rdy_priority (write_req_rdy),
    .s_pld_priority (write_req_pld_flag),

    .s_vld          (bubble_req_vld),    
    .s_rdy          (),    
    .s_pld          (bubble_req_pld),    

    .m_vld          (write_req_with_bubble_vld),    
    .m_rdy          (write_req_with_bubble_rdy),    
    .m_pld          (write_req_with_bubble_pld)
);

/*========================================*/
/*               write domain             */
/*========================================*/

afifo_write_domain_fz #(
    .FIFO_DEPTH (FIFO_DEPTH),
    .FIFO_WIDTH (FIFO_WIDTH+1)
) u_afifo_write_domain(
    .wclk           (wclk),
    .wrst_n         (wrst_n),

    .write_clear    (write_clear),
    .write_full_zero(write_full_zero),
    .bubble_gen_rdy (bubble_gen_rdy),

    .write_req_vld  (write_req_with_bubble_vld),
    .write_req_pld  (write_req_with_bubble_pld),
    .write_req_rdy  (write_req_with_bubble_rdy),

    .wptr_async     (wptr_async),
    .rptr_async     (rptr_async),
    .rptr_sync      (rptr_sync),
    .pld_sync       (pld_sync)
);

endmodule