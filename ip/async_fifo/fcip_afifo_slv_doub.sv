module fcip_afifo_slv_doub #(
    parameter integer unsigned  FIFO_DEPTH              = 16,
    parameter integer unsigned  DATA_WIDTH              = 16,
    parameter integer unsigned  AUTO_CLEAR_EN           = 0,
    parameter integer unsigned  THRESHOLD_EN            = 1,
    parameter integer unsigned  ALMOST_FULL_THRESHOLD   = 12,
    parameter integer unsigned  SYNC_STAGE              = 2,
    parameter integer unsigned  DOUBLE_DATA_WIRE        = 0,
    parameter integer unsigned  VT_TYPE                 = 1 // 0: SVT, 1: LVT, 2: ULVT, 3: ELVT, 4: LVTLL, 5: ULVTLL
)(
    input  logic                    clk,
    input  logic                    rst_n,

    //power down & full zero
    input  logic                    stall,
    input  logic                    clear,
    output logic                    full_zero,

    //s port
    input  logic                    s_vld,
    input  logic [DATA_WIDTH-1:0]   s_pld,
    output logic                    s_rdy,

    //threshold port
    output logic                    almost_full,

    //control signals
    output logic [FIFO_DEPTH-1:0]   wptr_async,

    input  logic [FIFO_DEPTH-1:0]   rptr_async,
    input  logic [FIFO_DEPTH-1:0]   rptr_sync,

    output logic [(DOUBLE_DATA_WIRE? (DATA_WIDTH*2+1) : DATA_WIDTH):0]     pld_sync  //DATA_WIDTH+1,used for entry vld
);

localparam int unsigned PTR_WIDTH = $clog2(FIFO_DEPTH);

logic                   full;
logic                   s_handshake;
logic                   winc;
logic [FIFO_DEPTH-1:0]  wptr_sync;
logic [FIFO_DEPTH-1:0]  wptr_sync_nxt;
logic [FIFO_DEPTH-1:0]  wptr_async_nxt;
logic [FIFO_DEPTH-1:0]  wq2_rptr_sync0;
logic [FIFO_DEPTH-1:0]  wq2_rptr_sync1;
logic                   rd_async_ptr_zero;
logic                   wr_ptr_zero;
logic [FIFO_DEPTH-1:0]  wptr_async_inner_SIZE_ONLY;

logic                   s_gen_vld;
logic [DATA_WIDTH:0]    s_gen_pld;
logic                   s_gen_rdy;

logic                   s_vld_ext;
logic [DATA_WIDTH:0]    s_pld_ext;
logic                   bubble_req_vld;
logic [DATA_WIDTH:0]    bubble_req_pld;
logic                   bubble_gen_rdy;

logic [FIFO_DEPTH-1:0]  wptr_async_nxt_size_only;
logic [FIFO_DEPTH-1:0]  rptr_sync_marker;
logic [FIFO_DEPTH-1:0]  rptr_async_marker;
logic [FIFO_DEPTH-1:0]  wptr_async_marker_SIZE_ONLY;

logic [(DOUBLE_DATA_WIRE? (DATA_WIDTH*2+1) : DATA_WIDTH):0]    pld_sync_marker;

/*========================================*/
/*               CDC Clock Marker         */
/*========================================*/

logic clk_marker;

fcip_clk_marker #(
    .VT_TYPE(VT_TYPE)
) afifo_slv_wclk_marker(
    .I (clk),
    .Z (clk_marker)
);

/*========================================*/
/*               Bubble Gen               */
/*========================================*/

assign bubble_gen_rdy   = ~full_zero;
assign bubble_req_vld   = bubble_gen_rdy && (AUTO_CLEAR_EN==1);
assign bubble_req_pld   = {(DATA_WIDTH+1){1'b0}};

/*========================================*/
/*               fixed arbiter            */
/*========================================*/

generate
    
    if(AUTO_CLEAR_EN)begin:AUTO_CLEAR_EN_OPEN
        assign s_pld_ext = {s_pld,1'b1}; // bit[0] is 1(normal), is 0(bubble)
        assign s_vld_ext = s_vld && ~stall;
        
        fcip_fix_arb #(
            .PLD_TYPE(logic [DATA_WIDTH:0])
        )u_s_arbiter(
            .clk            (clk),
            .rst_n          (rst_n),
        
            .s_vld_priority (s_vld_ext),
            .s_rdy_priority (s_rdy),
            .s_pld_priority (s_pld_ext),
        
            .s_vld          (bubble_req_vld),    
            .s_rdy          (),    
            .s_pld          (bubble_req_pld),    
        
            .m_vld          (s_gen_vld),    
            .m_rdy          (s_gen_rdy),    
            .m_pld          (s_gen_pld)
        );
        
    end else begin:AUTO_CLEAR_DISABLE

        assign s_pld_ext = {s_pld,1'b1}; // bit[0] is 1(normal), is 0(bubble)
        assign s_vld_ext = s_vld && ~stall;

        assign s_gen_vld = s_vld_ext;
        assign s_gen_pld = s_pld_ext;
        assign s_rdy     = s_gen_rdy;

    end

endgenerate

/*========================================*/
/*              s stall                   */
/*========================================*/

assign s_gen_rdy = ~full;

/*========================================*/
/*             Gen full zero              */
/*========================================*/

assign rd_async_ptr_zero    = ( (|wq2_rptr_sync1)==0 ) || ( (&wq2_rptr_sync1) == 1);
assign wr_ptr_zero          = wptr_sync== {{(FIFO_DEPTH-1){1'b0}},1'b1};
assign full_zero            = rd_async_ptr_zero && wr_ptr_zero;

/*========================================*/
/*              write ptr gen             */
/*========================================*/

assign s_handshake  = s_gen_vld && s_gen_rdy;
assign winc         = s_handshake;

//write pointer sync

assign wptr_sync_nxt = {wptr_sync[FIFO_DEPTH-2:0],wptr_sync[FIFO_DEPTH-1]};

always_ff @( posedge clk_marker or negedge rst_n ) begin
    if(~rst_n)
        wptr_sync <= {{(FIFO_DEPTH-1){1'b0}},1'b1};
    else if(clear)
        wptr_sync <= {{(FIFO_DEPTH-1){1'b0}},1'b1};
    else if(winc)
        wptr_sync <= wptr_sync_nxt;
end

//write pointer async for read domain compare

assign wptr_async_nxt = {wptr_async_inner_SIZE_ONLY[FIFO_DEPTH-2:0],~wptr_async_inner_SIZE_ONLY[FIFO_DEPTH-1]};

always_ff @( posedge clk_marker or negedge rst_n ) begin
    if(~rst_n)
        wptr_async_inner_SIZE_ONLY <= {{(FIFO_DEPTH){1'b0}}};
    else if(clear)
        wptr_async_inner_SIZE_ONLY <= {{(FIFO_DEPTH){1'b0}}};
    else if(winc)
        wptr_async_inner_SIZE_ONLY <= wptr_async_nxt;
end

// no fanout wptr_async pointer for sdc marker
assign wptr_async_nxt_size_only = {wptr_async_marker_SIZE_ONLY[FIFO_DEPTH-2:0],~wptr_async_marker_SIZE_ONLY[FIFO_DEPTH-1]};

always_ff @( posedge clk_marker or negedge rst_n ) begin
    if(~rst_n)
        wptr_async_marker_SIZE_ONLY <= {{(FIFO_DEPTH){1'b0}}};
    else if(clear)
        wptr_async_marker_SIZE_ONLY <= {{(FIFO_DEPTH){1'b0}}};
    else if(winc)
        wptr_async_marker_SIZE_ONLY <= wptr_async_nxt_size_only;
end

/*========================================*/
/*              read ptr sync             */
/*========================================*/

generate
    if(SYNC_STAGE==2)begin:SYNC_STAGE_LEVEL_2
        fcip_sync_cell #(
            .DATA_WIDTH  (FIFO_DEPTH),
            .SYN_STAGE   (2), // must upper than 1
            .VT_TYPE     (1), // 0: LVT, 1: SVT, 2: ULVT, 7: LVTLL, 8: ULVTLL
            .RST_VALUE   (0)// 0: sync_arst, 1: sync_aset
        ) rptr_sync_cell(
            .clk         (clk_marker  ),
            .rst_n       (rst_n),
            .d           (rptr_async_marker),
            .q           (wq2_rptr_sync1)
        );
    end else begin:SYNC_STAGE_LEVEL_3
        fcip_sync_cell #(
            .DATA_WIDTH  (FIFO_DEPTH),
            .SYN_STAGE   (3), // must upper than 1
            .VT_TYPE     (1), // 0: LVT, 1: SVT, 2: ULVT, 7: LVTLL, 8: ULVTLL
            .RST_VALUE   (0)// 0: sync_arst, 1: sync_aset
        ) rptr_sync_cell(
            .clk         (clk_marker  ),
            .rst_n       (rst_n),
            .d           (rptr_async_marker),
            .q           (wq2_rptr_sync1)
        );
    end
endgenerate

/*========================================*/
/*               ptr compare              */
/*========================================*/

assign full = |((wptr_async_inner_SIZE_ONLY ^ wq2_rptr_sync1) & wptr_sync);

/*========================================*/
/*           Generate threshold           */
/*========================================*/

generate 
    if(THRESHOLD_EN) begin:THRESHOLD_EN_OPEN

        logic [FIFO_DEPTH-1:0]   wq2_rptr_r;
        logic                    rinc_fake;
        logic [PTR_WIDTH:0]      ptr_cnt;

        always_ff @( posedge clk_marker or negedge rst_n ) begin
            if(~rst_n)
                wq2_rptr_r <= {(FIFO_DEPTH){1'b0}};
            else
                wq2_rptr_r <= wq2_rptr_sync1;
        end

        assign rinc_fake = |(wq2_rptr_r ^ wq2_rptr_sync1);

        always_ff @( posedge clk_marker or negedge rst_n ) begin
            if(~rst_n)
                ptr_cnt <= 'b0;
            else if(winc && rinc_fake)
                ptr_cnt <= ptr_cnt;
            else if(winc)
                ptr_cnt <= ptr_cnt + 1'b1;
            else if(rinc_fake)
                ptr_cnt <= ptr_cnt - 1'b1;
        end

        always_ff @( posedge clk_marker or negedge rst_n ) begin
            if(~rst_n)
                almost_full <= 'b0;
            else if( ptr_cnt >= ALMOST_FULL_THRESHOLD)
                almost_full <= 1'b1;
            else if( (ptr_cnt == (ALMOST_FULL_THRESHOLD-1)) && winc && ~rinc_fake)
                almost_full <= 1'b1;
            else 
                almost_full <= 1'b0;
        end
    end else begin
        assign almost_full  = 1'b0;
    end
endgenerate

/*========================================*/
/*               Reg entry                */
/*========================================*/

logic [DATA_WIDTH:0]    mem_array[FIFO_DEPTH-1:0];

generate 
    for(genvar i=0 ; i < FIFO_DEPTH ; i++)begin
        always_ff @( posedge clk_marker ) begin : AFIFO_REG_ENTRY
            if(wptr_sync[i] && winc)
                mem_array[i] <= s_gen_pld;
        end
    end
endgenerate

    /*========================================*/
    /*              Read Mux 0                */
    /*========================================*/

    logic [FIFO_DEPTH-1:0]  select_onehot_0;
    logic [FIFO_DEPTH-1:0]  pld_mux_rev_0         [DATA_WIDTH:0];
    logic [FIFO_DEPTH-1:0]  pld_mux_rev_select_0  [DATA_WIDTH:0]; 
    logic [DATA_WIDTH:0]    pld_mux_select_0;

    assign select_onehot_0 = rptr_sync_marker;

    genvar i,j;
    generate
        for(i=0;i<FIFO_DEPTH;i=i+1) begin: MEM_ARRAY_ROW_0
            for(j=0;j<(DATA_WIDTH+1);j=j+1) begin: MEM_ARRAY_COL_0
                assign pld_mux_rev_0[j][i] = mem_array[i][j];
            end 
        end
    endgenerate

    genvar k;
    generate
        for(k=0;k<(DATA_WIDTH+1);k=k+1) begin: PLD_WIDTH_0 
            assign pld_mux_rev_select_0[k] = pld_mux_rev_0[k] & select_onehot_0;
        end
    endgenerate

    genvar l;
    generate
        for(l=0;l<(DATA_WIDTH+1);l=l+1) begin: SEL_PLD_DATA_0
            assign pld_mux_select_0[l] = |pld_mux_rev_select_0[l];
        end 
    endgenerate

    assign pld_sync_marker_0 = pld_mux_select_0;

    /*========================================*/
    /*              Read Mux 1                */
    /*========================================*/

    logic [FIFO_DEPTH-1:0]  select_onehot_1;
    logic [FIFO_DEPTH-1:0]  pld_mux_rev_1         [DATA_WIDTH:0];
    logic [FIFO_DEPTH-1:0]  pld_mux_rev_select_1  [DATA_WIDTH:0]; 
    logic [DATA_WIDTH:0]    pld_mux_select_1;

    assign rptr_sync_marker_shift = {rptr_sync_marker[FIFO_DEPTH-2:0],rptr_sync_marker[FIFO_DEPTH-1]};
    assign select_onehot_1        = rptr_sync_marker_shift;

    generate
        for(i=0;i<FIFO_DEPTH;i=i+1) begin: MEM_ARRAY_ROW_1
            for(j=0;j<(DATA_WIDTH+1);j=j+1) begin: MEM_ARRAY_COL_1
                assign pld_mux_rev_1[j][i] = mem_array[i][j];
            end 
        end
    endgenerate

    generate
        for(k=0;k<(DATA_WIDTH+1);k=k+1) begin: PLD_WIDTH_1
            assign pld_mux_rev_select_1[k] = pld_mux_rev_0[k] & select_onehot_0;
        end
    endgenerate

    generate
        for(l=0;l<(DATA_WIDTH+1);l=l+1) begin: SEL_PLD_DATA_1
            assign pld_mux_select_1[l] = |pld_mux_rev_select_0[l];
        end 
    endgenerate

    assign pld_sync_marker_1 = pld_mux_select_1;


    generate if( DOUBLE_DATA_WIRE == 1 ) begin

        assign pld_sync_marker = {pld_sync_marker_1,pld_sync_marker_0};

    end else begin
        
        assign pld_sync_marker = pld_sync_marker_0;

    end
    endgenerate

/*========================================*/
/*               CDC Marker               */
/*========================================*/

fcip_marker #(
    .DATA_WIDTH(FIFO_DEPTH),
    .VT_TYPE(VT_TYPE)
) async_rptr_sync_marker(
    .I  (rptr_sync),
    .Z  (rptr_sync_marker)
);

fcip_marker #(
    .DATA_WIDTH(FIFO_DEPTH),
    .VT_TYPE(VT_TYPE)
) wr_rptr_async_primary_marker(
    .I  (rptr_async),
    .Z  (rptr_async_marker)
);

generate if( DOUBLE_DATA_WIRE == 1 ) begin

    logic [DATA_WIDTH:0] pld_sync_0;
    logic [DATA_WIDTH:0] pld_sync_1;

        fcip_marker #(
            .DATA_WIDTH(DATA_WIDTH+1),
            .VT_TYPE(VT_TYPE)
        ) async_pld_sync_0_marker(
            .I  (pld_sync_marker[DATA_WIDTH:0]),
            .Z  (pld_sync_0)
        );

        fcip_marker #(
            .DATA_WIDTH(DATA_WIDTH+1),
            .VT_TYPE(VT_TYPE)
        ) async_pld_sync_1_marker(
            .I  (pld_sync_marker[ DATA_WIDTH*2 + 1 : DATA_WIDTH+1]),
            .Z  (pld_sync_1)
        );
        
        assign pld_sync = {pld_sync_1,pld_sync_0};

    end else begin

        fcip_marker #(
            .DATA_WIDTH(DATA_WIDTH+1),
            .VT_TYPE(VT_TYPE)
        ) async_pld_sync_marker(
            .I  (pld_sync_marker),
            .Z  (pld_sync)
        );

    end
endgenerate

fcip_marker #(
    .DATA_WIDTH(FIFO_DEPTH),
    .VT_TYPE(VT_TYPE)
) async_wptr_async_marker(
    .I  (wptr_async_marker_SIZE_ONLY),
    .Z  (wptr_async)
);



endmodule