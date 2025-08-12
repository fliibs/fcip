module afifo_write_domain #(
    parameter  integer FIFO_DEPTH = 16,
    parameter  integer FIFO_WIDTH = 16
)(
    input  logic                    wclk,
    input  logic                    wrst_n,
    //power down
    input  logic                    stall,
    input  logic                    clear,
    //output logic                    write_idle, //read empty

    //write req
    input  logic                    write_req_vld,
    input  logic [FIFO_WIDTH-1:0]   write_req_pld,
    output logic                    write_req_rdy,

    //control signals
    output logic [FIFO_DEPTH-1:0]   wptr_async,

    input  logic [FIFO_DEPTH-1:0]   rptr_async,
    input  logic [FIFO_DEPTH-1:0]   rptr_sync,
    output logic [FIFO_WIDTH-1:0]   pld_sync
);

logic       full;
logic       write_req_handshake;
logic       winc;

/*========================================*/
/*              write stall               */
/*========================================*/

assign write_req_rdy = ~(full || stall);

/*========================================*/
/*              write ptr gen             */
/*========================================*/

assign write_req_handshake  = write_req_vld && write_req_rdy;
assign winc                 = write_req_handshake;

//write pointer sync

logic [FIFO_DEPTH-1:0]  wptr_sync;
logic [FIFO_DEPTH-1:0]  wptr_sync_nxt;

assign wptr_sync_nxt = {wptr_sync[FIFO_DEPTH-2:0],wptr_sync[FIFO_DEPTH-1]};

always_ff @( posedge wclk or negedge wrst_n ) begin
    if(~wrst_n)
        wptr_sync <= {{(FIFO_DEPTH-1){1'b0}},1'b1};
    else if(clear)
        wptr_sync <= {{(FIFO_DEPTH-1){1'b0}},1'b1};
    else if(winc)
        wptr_sync <= wptr_sync_nxt;
end

//write pointer async for read domain compare

logic [FIFO_DEPTH-1:0]  wptr_async_nxt;

assign wptr_async_nxt = {wptr_async[FIFO_DEPTH-2:0],~wptr_async[FIFO_DEPTH-1]};;

always_ff @( posedge wclk or negedge wrst_n ) begin
    if(~wrst_n)
        wptr_async <= {{(FIFO_DEPTH){1'b0}}};
    else if(clear)
        wptr_async <= {{(FIFO_DEPTH){1'b0}}};
    else if(winc)
        wptr_async <= wptr_async_nxt;
end

/*========================================*/
/*              read ptr sync             */
/*========================================*/

//replace  sync std_cell
logic [FIFO_DEPTH-1:0] wq2_rptr_sync0;
logic [FIFO_DEPTH-1:0] wq2_rptr_sync1;

always_ff @( posedge wclk or negedge wrst_n ) begin
    if(~wrst_n)begin
        wq2_rptr_sync0 <= {{(FIFO_DEPTH){1'b0}}};
        wq2_rptr_sync1 <= {{(FIFO_DEPTH){1'b0}}};
    end else if(clear)begin
        wq2_rptr_sync0 <= {{(FIFO_DEPTH){1'b0}}};
        wq2_rptr_sync1 <= {{(FIFO_DEPTH){1'b0}}};
    end
    else begin
        wq2_rptr_sync0 <= rptr_async;
        wq2_rptr_sync1 <= wq2_rptr_sync0;
    end
end

/*========================================*/
/*               ptr compare              */
/*========================================*/

assign full = |((wptr_async ^ wq2_rptr_sync1) & wptr_sync);

/*========================================*/
/*               Reg entry                */
/*========================================*/

logic [FIFO_WIDTH-1:0] mem_array[FIFO_DEPTH-1:0];

generate
    for(genvar i=0 ; i < FIFO_DEPTH ; i++)
        always_ff @( posedge wclk or negedge wrst_n ) begin : AFIFO_REG_ENTRY
            if(~wrst_n)
                mem_array[i] <= 'b0;
            else if(clear)
                mem_array[i] <= 'b0;
            else if(wptr_sync[i] && winc)
                mem_array[i] <= write_req_pld;
        end
endgenerate

/*========================================*/
/*               Read Mux                 */
/*========================================*/

//replace data mux common ip
cmn_real_mux_onehot #(
    .WIDTH(FIFO_DEPTH),
    .PLD_WIDTH(FIFO_WIDTH)
)u_read_pld_mux(
    .select_onehot  (rptr_sync),
    .v_pld          (mem_array),
    .select_pld     (pld_sync)
);

endmodule