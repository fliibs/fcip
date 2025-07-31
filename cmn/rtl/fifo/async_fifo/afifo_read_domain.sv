
module afifo_read_domain #(
    parameter  integer FIFO_DEPTH = 16,
    parameter  integer FIFO_WIDTH = 16
)(
    input  logic                    rclk,
    input  logic                    rrst_n,
    //power down
    input  logic                    stall,
    input  logic                    clear,
    output logic                    idle,

    //read response
    output logic                    read_resp_vld,
    output logic [FIFO_WIDTH-1:0]   read_resp_pld,
    input  logic                    read_resp_rdy,

    //control signals
    input  logic [FIFO_DEPTH-1:0]   wptr_async,

    output logic [FIFO_DEPTH-1:0]   rptr_async,
    output logic [FIFO_DEPTH-1:0]   rptr_sync,
    input  logic [FIFO_WIDTH-1:0]   pld_sync
);

logic   empty;
logic   rinc;
logic   read_req_handshake;

logic                       read_out_vld;
logic                       read_out_rdy;
logic [FIFO_WIDTH-1:0]      read_out_data;

/*========================================*/
/*               read stall               */
/*========================================*/

assign idle         = empty;

/*========================================*/
/*              read ptr gen              */
/*========================================*/

assign read_req_handshake   = (~empty) && read_out_rdy;
assign rinc                 = read_req_handshake;

//read pointer sync

//logic [FIFO_DEPTH-1:0]  rptr_sync;
logic [FIFO_DEPTH-1:0]  rptr_sync_nxt;

assign wptr_sync_nxt = {rptr_sync[FIFO_DEPTH-2:0],rptr_sync[FIFO_DEPTH-1]};

always_ff @( posedge rclk or negedge rrst_n ) begin
    if(~rrst_n)
        rptr_sync <= {{(FIFO_DEPTH-1){1'b0}},1'b1};
    else if(clear)
        rptr_sync <= {{(FIFO_DEPTH-1){1'b0}},1'b1};
    else if(rinc)
        rptr_sync <= rptr_sync_nxt;
end

//read pointer async for write domain compare

logic [FIFO_DEPTH-1:0]  rptr_async_nxt;

assign rptr_async_nxt = {rptr_async[FIFO_DEPTH-2:0],~rptr_async[FIFO_DEPTH-1]};;

always_ff @( posedge rclk or negedge rrst_n ) begin
    if(~rrst_n)
        rptr_async <= {{(FIFO_DEPTH){1'b0}}};
    else if(clear)
        rptr_async <= {{(FIFO_DEPTH){1'b0}}};
    else if(rinc)
        rptr_async <= rptr_async_nxt;
end

/*========================================*/
/*              write ptr sync             */
/*========================================*/

//replace  sync std_cell
logic [FIFO_DEPTH-1:0] rq2_wptr_sync0;
logic [FIFO_DEPTH-1:0] rq2_wptr_sync1;

always_ff @( posedge rclk or negedge rrst_n ) begin
    if(~rrst_n)begin
        rq2_wptr_sync0 <= {{(FIFO_DEPTH){1'b0}}};
        rq2_wptr_sync1 <= {{(FIFO_DEPTH){1'b0}}};
    end else if(clear)begin
        rq2_wptr_sync0 <= {{(FIFO_DEPTH){1'b0}}};
        rq2_wptr_sync1 <= {{(FIFO_DEPTH){1'b0}}};
    end
    else begin
        rq2_wptr_sync0 <= wptr_async;
        rq2_wptr_sync1 <= rq2_wptr_sync0;
    end
end

/*========================================*/
/*               ptr compare              */
/*========================================*/

assign empty = ~(|((rptr_async ^ rq2_wptr_sync1) & rptr_sync));

/*========================================*/
/*         read response reg slice        */
/*========================================*/

assign read_out_vld         = rinc;
assign read_out_data        = pld_sync;

reg_slice_forward #(
    .PLD_TYPE(logic [FIFO_WIDTH-1:0])
) u_reg_slice_forware(
    .clk        (rclk),
    .rst_n      (rrst_n),
    .s_vld      (read_out_vld ),
    .s_rdy      (read_out_rdy ),
    .s_pld      (read_out_data ),
    .m_vld      (read_resp_vld ),
    .m_rdy      (read_resp_rdy ),
    .m_pld      (read_resp_pld )
);

endmodule 