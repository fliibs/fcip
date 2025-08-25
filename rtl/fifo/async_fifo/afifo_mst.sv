
module afifo_mst #(
    parameter integer unsigned FIFO_DEPTH = 16,
    parameter integer unsigned DATA_WIDTH = 16,
    parameter integer unsigned AUTO_CLEAR_EN  = 0,
    parameter integer unsigned SYNC_STAGE = 2
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
    output logic [DATA_WIDTH-1:0]   read_resp_pld,
    input  logic                    read_resp_rdy,

    //control signals
    input  logic [FIFO_DEPTH-1:0]   wptr_async,

    output logic [FIFO_DEPTH-1:0]   rptr_async,
    output logic [FIFO_DEPTH-1:0]   rptr_sync,
    input  logic [DATA_WIDTH:0]     pld_sync
);

logic                       empty;
logic                       rinc;
logic                       read_req_handshake;
logic                       read_out_vld;
logic                       read_out_rdy;
logic [DATA_WIDTH:0]        read_out_data;
logic                       wr_async_ptr_zero;
logic                       rd_ptr_zero;
logic [FIFO_DEPTH-1:0]      rptr_sync_nxt;
logic [FIFO_DEPTH-1:0]      rptr_async_nxt;
logic [FIFO_DEPTH-1:0]      rq2_wptr_sync1;
logic [FIFO_DEPTH-1:0]      rq2_wptr_sync0;
logic [FIFO_DEPTH-1:0]      rptr_sync_inner;
logic [FIFO_DEPTH-1:0]      rptr_async_inner;

logic [FIFO_DEPTH-1:0]      rptr_sync_marker;
logic [FIFO_DEPTH-1:0]      rptr_async_marker;
logic [DATA_WIDTH:0]        pld_sync_marker;
logic [FIFO_DEPTH-1:0]      wptr_async_marker;

/*========================================*/
/*               read stall               */
/*========================================*/

assign read_idle         = empty;

/*========================================*/
/*             Gen full zero              */
/*========================================*/

assign wr_async_ptr_zero= ( (|rq2_wptr_sync1)==0 ) || ( (&rq2_wptr_sync1) == 1);
assign rd_ptr_zero      = (|rptr_sync)==0;
assign read_full_zero   = wr_async_ptr_zero && rd_ptr_zero;

/*========================================*/
/*              read ptr gen              */
/*========================================*/

assign read_req_handshake   = (~empty) && read_out_rdy;
assign rinc                 = read_req_handshake;

//read pointer sync

assign rptr_sync_nxt = {rptr_sync_inner[FIFO_DEPTH-2:0],rptr_sync_inner[FIFO_DEPTH-1]};

always_ff @( posedge rclk or negedge rrst_n ) begin
    if(~rrst_n)
        rptr_sync_inner <= {{(FIFO_DEPTH-1){1'b0}},1'b1};
    else if(read_clear)
        rptr_sync_inner <= {{(FIFO_DEPTH-1){1'b0}},1'b1};
    else if(rinc)
        rptr_sync_inner <= rptr_sync_nxt;
end

// no fanout rptr_sync pointer for sdc marker
always_ff @( posedge rclk or negedge rrst_n ) begin
    if(~rrst_n)
        rptr_sync_marker <= {{(FIFO_DEPTH-1){1'b0}},1'b1};
    else if(read_clear)
        rptr_sync_marker <= {{(FIFO_DEPTH-1){1'b0}},1'b1};
    else if(rinc)
        rptr_sync_marker <= rptr_sync_nxt;
end

//read pointer async for write domain compare

assign rptr_async_nxt = {rptr_async_inner[FIFO_DEPTH-2:0],~rptr_async_inner[FIFO_DEPTH-1]};

always_ff @( posedge rclk or negedge rrst_n ) begin
    if(~rrst_n)
        rptr_async_inner <= {{(FIFO_DEPTH){1'b0}}};
    else if(read_clear)
        rptr_async_inner <= {{(FIFO_DEPTH){1'b0}}};
    else if(rinc)
        rptr_async_inner <= rptr_async_nxt;
end

// no fanout rptr_async pointer for sdc marker
always_ff @( posedge rclk or negedge rrst_n ) begin
    if(~rrst_n)
        rptr_async_marker <= {{(FIFO_DEPTH){1'b0}}};
    else if(read_clear)
        rptr_async_marker <= {{(FIFO_DEPTH){1'b0}}};
    else if(rinc)
        rptr_async_marker <= rptr_async_nxt;
end
/*========================================*/
/*              write ptr sync             */
/*========================================*/

//replace  sync std_cell

//always_ff @( posedge rclk or negedge rrst_n ) begin
//    if(~rrst_n)begin
//        rq2_wptr_sync0 <= {{(FIFO_DEPTH){1'b0}}};
//        rq2_wptr_sync1 <= {{(FIFO_DEPTH){1'b0}}};
//    end else if(read_clear)begin
//        rq2_wptr_sync0 <= {{(FIFO_DEPTH){1'b0}}};
//        rq2_wptr_sync1 <= {{(FIFO_DEPTH){1'b0}}};
//    end
//    else begin
//        rq2_wptr_sync0 <= wptr_async;
//        rq2_wptr_sync1 <= rq2_wptr_sync0;
//    end
//end

fcip_sync_cell #(
    .DATA_WIDTH  (FIFO_DEPTH),
    .SYN_STAGE   (SYNC_STAGE), // must upper than 1
    .VT_TYPE     (1), // 0: LVT, 1: SVT, 2: ULVT, 7: LVTLL, 8: ULVTLL
    .RST_VALUE   (0)// 0: sync_arst, 1: sync_aset
) rptr_sync_cell(
    .clk         (rclk  ),
    .rst_n       (rrst_n),
    .d           (wptr_async_marker),
    .q           (rq2_wptr_sync1)
);

/*========================================*/
/*               ptr compare              */
/*========================================*/

assign empty = ~(|((rptr_async_inner ^ rq2_wptr_sync1) & rptr_sync_inner));

/*========================================*/
/*         read response reg slice        */
/*========================================*/

logic                   reg_slice_vld_r;
logic [DATA_WIDTH-1:0]  reg_slice_pld_r;

assign read_out_vld         = rinc;
assign read_out_data        = pld_sync_marker;
assign read_out_rdy         = ~reg_slice_vld_r || read_resp_rdy;
//assign read_resp_vld        = reg_slice_vld_r;
//assign read_resp_pld        = reg_slice_pld_r;

always_ff @( posedge rclk or negedge rrst_n ) begin
    if(~rrst_n)
        reg_slice_vld_r <= 1'b0;
    else if(read_out_vld && read_out_rdy)
        reg_slice_vld_r <= 1'b1;
    else if(read_resp_rdy)
        reg_slice_vld_r <= 1'b0;
end

always_ff @( posedge rclk or negedge rrst_n ) begin
    if(~rrst_n)
        reg_slice_pld_r <= 'b0;
    else if(read_out_vld && read_out_rdy)
        reg_slice_pld_r <= read_out_data;
end

/*========================================*/
/*               read stall               */
/*========================================*/

generate
    if(AUTO_CLEAR_EN == 1)begin
        logic                       read_resp_mask;
        logic                       bubble_en;

        assign bubble_en        = ~reg_slice_pld_r[0];
        assign read_resp_mask   = read_stall || bubble_en;
        assign read_resp_vld    = reg_slice_vld_r && ~read_resp_mask;
        assign read_resp_pld    = reg_slice_pld_r[DATA_WIDTH-1:1];

    end else begin

        assign read_resp_vld    = reg_slice_vld_r;
        assign read_resp_pld    = reg_slice_pld_r[DATA_WIDTH-1:1];

    end
endgenerate

/*========================================*/
/*               CDC Marker               */
/*========================================*/

fcip_marker #(
    .DATA_WIDTH(FIFO_DEPTH)
) async_rptr_sync_marker(
    .I  (rptr_sync_marker),
    .Z  (rptr_sync)
);

fcip_marker #(
    .DATA_WIDTH(FIFO_DEPTH)
) rd_rptr_async_primary_marker(
    .I  (rptr_async_marker),
    .Z  (rptr_async)
);

fcip_marker #(
    .DATA_WIDTH(DATA_WIDTH+1)
) async_pld_sync_marker(
    .I  (pld_sync),
    .Z  (pld_sync_marker)
);

fcip_marker #(
    .DATA_WIDTH(FIFO_DEPTH)
) async_wptr_async_marker(
    .I  (wptr_async),
    .Z  (wptr_async_marker)
);


endmodule 