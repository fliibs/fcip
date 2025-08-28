module afifo_slv #(
    parameter integer unsigned  FIFO_DEPTH = 16,
    parameter integer unsigned  DATA_WIDTH = 16,
    parameter integer unsigned  AUTO_CLEAR_EN  = 0,
    parameter integer unsigned  SYNC_STAGE = 2
)(
    input  logic                    wclk,
    input  logic                    wrst_n,

    //power down & full zero
    input  logic                    write_stall,
    input  logic                    write_clear,
    output logic                    write_full_zero,

    //write req
    input  logic                    write_req_vld,
    input  logic [DATA_WIDTH-1:0]   write_req_pld,
    output logic                    write_req_rdy,

    //control signals
    output logic [FIFO_DEPTH-1:0]   wptr_async,

    input  logic [FIFO_DEPTH-1:0]   rptr_async,
    input  logic [FIFO_DEPTH-1:0]   rptr_sync,
    output logic [DATA_WIDTH:0]     pld_sync
);

logic                   full;
logic                   write_req_handshake;
logic                   winc;
logic [FIFO_DEPTH-1:0]  wptr_sync;
logic [FIFO_DEPTH-1:0]  wptr_sync_nxt;
logic [FIFO_DEPTH-1:0]  wptr_async_nxt;
logic [FIFO_DEPTH-1:0]  wq2_rptr_sync0;
logic [FIFO_DEPTH-1:0]  wq2_rptr_sync1;
logic                   rd_async_ptr_zero;
logic                   wr_ptr_zero;
logic [FIFO_DEPTH-1:0]  wptr_async_inner;

logic                   write_req_gen_vld;
logic [DATA_WIDTH:0]    write_req_gen_pld;
logic                   write_req_gen_rdy;

logic                   write_req_vld_ext;
logic [DATA_WIDTH:0]    write_req_pld_ext;
logic                   bubble_req_vld;
logic [DATA_WIDTH:0]    bubble_req_pld;
logic                   bubble_gen_rdy;

logic [FIFO_DEPTH-1:0]  rptr_sync_marker;
logic [FIFO_DEPTH-1:0]  rptr_async_marker;
logic [DATA_WIDTH:0]    pld_sync_marker;
logic [FIFO_DEPTH-1:0]  wptr_async_marker;

/*========================================*/
/*               Bubble Gen               */
/*========================================*/

assign bubble_gen_rdy   = ~write_full_zero;
assign bubble_req_vld   = bubble_gen_rdy && (AUTO_CLEAR_EN==1);
assign bubble_req_pld   = {(DATA_WIDTH+1){1'b0}};

/*========================================*/
/*               fixed arbiter            */
/*========================================*/

assign write_req_pld_ext = {write_req_pld,1'b1}; // bit[0] is 1(normal), is 0(bubble)
assign write_req_vld_ext = write_req_vld && ~write_stall;

cmn_fix_arb #(
    .PLD_TYPE(logic [DATA_WIDTH:0])
)u_write_req_arbiter(
    .clk            (wclk),
    .rst_n          (wrst_n),

    .s_vld_priority (write_req_vld_ext),
    .s_rdy_priority (write_req_rdy),
    .s_pld_priority (write_req_pld_ext),

    .s_vld          (bubble_req_vld),    
    .s_rdy          (),    
    .s_pld          (bubble_req_pld),    

    .m_vld          (write_req_gen_vld),    
    .m_rdy          (write_req_gen_rdy),    
    .m_pld          (write_req_gen_pld)
);

/*========================================*/
/*              write stall               */
/*========================================*/

assign write_req_gen_rdy = ~full;

/*========================================*/
/*             Gen full zero              */
/*========================================*/

assign rd_async_ptr_zero= ( (|wq2_rptr_sync1)==0 ) || ( (&wq2_rptr_sync1) == 1);
assign wr_ptr_zero      = (|wptr_sync)==0;
assign write_full_zero  = rd_async_ptr_zero && wr_ptr_zero;

/*========================================*/
/*              write ptr gen             */
/*========================================*/

assign write_req_handshake  = write_req_gen_vld && write_req_gen_rdy;
assign winc                 = write_req_handshake;

//write pointer sync

assign wptr_sync_nxt = {wptr_sync[FIFO_DEPTH-2:0],wptr_sync[FIFO_DEPTH-1]};

always_ff @( posedge wclk or negedge wrst_n ) begin
    if(~wrst_n)
        wptr_sync <= {{(FIFO_DEPTH-1){1'b0}},1'b1};
    else if(write_clear)
        wptr_sync <= {{(FIFO_DEPTH-1){1'b0}},1'b1};
    else if(winc)
        wptr_sync <= wptr_sync_nxt;
end

//write pointer async for read domain compare

assign wptr_async_nxt = {wptr_async_inner[FIFO_DEPTH-2:0],~wptr_async_inner[FIFO_DEPTH-1]};

always_ff @( posedge wclk or negedge wrst_n ) begin
    if(~wrst_n)
        wptr_async_inner <= {{(FIFO_DEPTH){1'b0}}};
    else if(write_clear)
        wptr_async_inner <= {{(FIFO_DEPTH){1'b0}}};
    else if(winc)
        wptr_async_inner <= wptr_async_nxt;
end

// no fanout wptr_async pointer for sdc marker
always_ff @( posedge wclk or negedge wrst_n ) begin
    if(~wrst_n)
        wptr_async_marker <= {{(FIFO_DEPTH){1'b0}}};
    else if(write_clear)
        wptr_async_marker <= {{(FIFO_DEPTH){1'b0}}};
    else if(winc)
        wptr_async_marker <= wptr_async_nxt;
end

/*========================================*/
/*              read ptr sync             */
/*========================================*/

fcip_sync_cell #(
    .DATA_WIDTH  (FIFO_DEPTH),
    .SYN_STAGE   (SYNC_STAGE), // must upper than 1
    .VT_TYPE     (1), // 0: LVT, 1: SVT, 2: ULVT, 7: LVTLL, 8: ULVTLL
    .RST_VALUE   (0)// 0: sync_arst, 1: sync_aset
) rptr_sync_cell(
    .clk         (wclk  ),
    .rst_n       (wrst_n),
    .d           (rptr_async_marker),
    .q           (wq2_rptr_sync1)
);

/*========================================*/
/*               ptr compare              */
/*========================================*/

assign full = |((wptr_async_inner ^ wq2_rptr_sync1) & wptr_sync);

/*========================================*/
/*               Reg entry                */
/*========================================*/

logic [DATA_WIDTH:0]    mem_array[FIFO_DEPTH-1:0];

generate 
    for(genvar i=0 ; i < FIFO_DEPTH ; i++)begin
        always_ff @( posedge wclk ) begin : AFIFO_REG_ENTRY
            if(wptr_sync[i] && winc)
                mem_array[i] <= write_req_gen_pld;
        end
    end
endgenerate

/*========================================*/
/*               Read Mux                 */
/*========================================*/

logic [FIFO_DEPTH-1:0]  select_onehot;
logic [FIFO_DEPTH-1:0]  pld_mux_rev         [DATA_WIDTH:0];
logic [FIFO_DEPTH-1:0]  pld_mux_rev_select  [DATA_WIDTH:0]; 
logic [DATA_WIDTH:0]    pld_mux_select;

assign select_onehot = rptr_sync_marker;

genvar i,j;
generate
    for(i=0;i<FIFO_DEPTH;i=i+1) begin: row
        for(j=0;j<DATA_WIDTH;j=j+1) begin: col 
            assign pld_mux_rev[j][i] = mem_array[i][j];
        end 
    end
endgenerate

genvar k;
generate
    for(k=0;k<DATA_WIDTH;k=k+1) begin: PLD_WIDTH_ 
        assign pld_mux_rev_select[k] = pld_mux_rev[k] & select_onehot;
    end
endgenerate

genvar l;
generate
    for(l=0;l<DATA_WIDTH;l=l+1) begin: select_pld_data
        assign pld_mux_select[l] = |pld_mux_rev_select[l];
    end 
endgenerate

assign pld_sync_marker = pld_mux_select;

/*========================================*/
/*               CDC Marker               */
/*========================================*/

fcip_marker #(
    .DATA_WIDTH(FIFO_DEPTH)
) async_rptr_sync_marker(
    .I  (rptr_sync),
    .Z  (rptr_sync_marker)
);

fcip_marker #(
    .DATA_WIDTH(FIFO_DEPTH)
) wr_rptr_async_primary_marker(
    .I  (rptr_async),
    .Z  (rptr_async_marker)
);

fcip_marker #(
    .DATA_WIDTH(DATA_WIDTH+1)
) async_pld_sync_marker(
    .I  (pld_sync_marker),
    .Z  (pld_sync)
);

fcip_marker #(
    .DATA_WIDTH(FIFO_DEPTH)
) async_wptr_async_marker(
    .I  (wptr_async_marker),
    .Z  (wptr_async)
);

endmodule