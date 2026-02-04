module fcip_afifo_mst_doub #(
    parameter integer unsigned FIFO_DEPTH    = 16,
    parameter integer unsigned DATA_WIDTH    = 16,
    parameter integer unsigned AUTO_CLEAR_EN = 0,
    parameter integer unsigned THRESHOLD_EN            = 1,
    parameter integer unsigned ALMOST_EMPTY_THRESHOLD  = 4,
    parameter integer unsigned SYNC_STAGE    = 2,
    parameter integer unsigned DOUBLE_DATA_WIRE = 0,
    parameter integer unsigned VT_TYPE       = 1 // 0: SVT, 1: LVT, 2: ULVT, 3: ELVT, 4: LVTLL, 5: ULVTLL
)(
    input  logic                    clk,
    input  logic                    rst_n,
    //power down
    input  logic                    stall,
    input  logic                    clear,
    output logic                    full_zero,
    output logic                    idle,

    //m port
    output logic                    m_vld,
    output logic [DATA_WIDTH-1:0]   m_pld,
    input  logic                    m_rdy,

    //threshold port
    output logic                    almost_empty,

    //control signals
    input  logic [FIFO_DEPTH-1:0]   wptr_async,
    output logic [FIFO_DEPTH-1:0]   rptr_async,
    output logic [FIFO_DEPTH-1:0]   rptr_sync,
    input  logic [(DOUBLE_DATA_WIRE? (DATA_WIDTH*2+1) : DATA_WIDTH):0]     pld_sync  //DATA_WIDTH+1,used for entry vld
);

localparam int unsigned PTR_WIDTH = $clog2(FIFO_DEPTH);

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
logic [FIFO_DEPTH-1:0]      rptr_sync_inner_SIZE_ONLY;
logic [FIFO_DEPTH-1:0]      rptr_async_inner_SIZE_ONLY;
logic [DATA_WIDTH:0]        pld_sync_marker;

logic [FIFO_DEPTH-1:0]      rptr_sync_nxt_size_only;
logic [FIFO_DEPTH-1:0]      rptr_async_nxt_size_only;
logic [FIFO_DEPTH-1:0]      rptr_sync_marker_SIZE_ONLY;
logic [FIFO_DEPTH-1:0]      rptr_async_marker_SIZE_ONLY;

logic [FIFO_DEPTH-1:0]      wptr_async_marker;

logic [DATA_WIDTH:0]        pld_sync_marker_0;
logic [DATA_WIDTH:0]        pld_sync_marker_1;

/*========================================*/
/*               CDC Clock Marker         */
/*========================================*/

logic clk_marker;

fcip_clk_marker #(
    .VT_TYPE(VT_TYPE)
) afifo_mst_rclk_marker(
    .I (clk),
    .Z (clk_marker)
);

/*========================================*/
/*               read stall               */
/*========================================*/

assign idle = empty;

/*========================================*/
/*             Gen full zero              */
/*========================================*/

assign wr_async_ptr_zero = ( (|rq2_wptr_sync1)==0 ) || ( (&rq2_wptr_sync1) == 1);
assign rd_ptr_zero       = rptr_sync_inner_SIZE_ONLY == {{(FIFO_DEPTH-1){1'b0}},1'b1};
assign full_zero         = wr_async_ptr_zero && rd_ptr_zero;

/*========================================*/
/*              read ptr gen              */
/*========================================*/

assign read_req_handshake = (~empty) && read_out_rdy;
assign rinc               = read_req_handshake;

//read pointer sync

assign rptr_sync_nxt = {rptr_sync_inner_SIZE_ONLY[FIFO_DEPTH-2:0],rptr_sync_inner_SIZE_ONLY[FIFO_DEPTH-1]};

always_ff @( posedge clk_marker or negedge rst_n ) begin
    if(~rst_n)
        rptr_sync_inner_SIZE_ONLY <= {{(FIFO_DEPTH-1){1'b0}},1'b1};
    else if(clear)
        rptr_sync_inner_SIZE_ONLY <= {{(FIFO_DEPTH-1){1'b0}},1'b1};
    else if(rinc)
        rptr_sync_inner_SIZE_ONLY <= rptr_sync_nxt;
end

// no fanout rptr_sync pointer for sdc marker

// assign rptr_sync_nxt_size_only = {rptr_sync_marker_SIZE_ONLY[FIFO_DEPTH-2:0],rptr_sync_marker_SIZE_ONLY[FIFO_DEPTH-1]};
// 
// always_ff @( posedge clk_marker or negedge rst_n ) begin
//     if(~rst_n)
//         rptr_sync_marker_SIZE_ONLY <= {{(FIFO_DEPTH-1){1'b0}},1'b1};
//     else if(clear)
//         rptr_sync_marker_SIZE_ONLY <= {{(FIFO_DEPTH-1){1'b0}},1'b1};
//     else if(rinc)
//         rptr_sync_marker_SIZE_ONLY <= rptr_sync_nxt_size_only;
// end

//read pointer async for write domain compare

assign rptr_async_nxt = {rptr_async_inner_SIZE_ONLY[FIFO_DEPTH-2:0],~rptr_async_inner_SIZE_ONLY[FIFO_DEPTH-1]};

always_ff @( posedge clk_marker or negedge rst_n ) begin
    if(~rst_n)
        rptr_async_inner_SIZE_ONLY <= {{(FIFO_DEPTH){1'b0}}};
    else if(clear)
        rptr_async_inner_SIZE_ONLY <= {{(FIFO_DEPTH){1'b0}}};
    else if(rinc)
        rptr_async_inner_SIZE_ONLY <= rptr_async_nxt;
end

// no fanout rptr_async pointer for sdc marker

assign rptr_async_nxt_size_only = {rptr_async_marker_SIZE_ONLY[FIFO_DEPTH-2:0],~rptr_async_marker_SIZE_ONLY[FIFO_DEPTH-1]};

always_ff @( posedge clk_marker or negedge rst_n ) begin
    if(~rst_n)
        rptr_async_marker_SIZE_ONLY <= {{(FIFO_DEPTH){1'b0}}};
    else if(clear)
        rptr_async_marker_SIZE_ONLY <= {{(FIFO_DEPTH){1'b0}}};
    else if(rinc)
        rptr_async_marker_SIZE_ONLY <= rptr_async_nxt_size_only;
end

/*==========================================*/
/*          read ptr switch ctrl and        */
/*no fanout rptr_sync pointer for sdc marker*/
/*==========================================*/

generate 
    if(DOUBLE_DATA_WIRE == 1 ) begin: DOUBLE_DATA_WIRE_LOGIC

        logic rptr_switch;

        always_ff @( posedge clk_marker or negedge rst_n ) begin
            if(~rst_n)
                rptr_switch <= 1'b0;
            else if(rinc)
                rptr_switch <= ~rptr_switch;
        end

        assign rptr_sync_nxt_size_only = (FIFO_DEPTH==2) ? {{(FIFO_DEPTH-1){1'b0}},1'b1} :
                        {rptr_sync_marker_SIZE_ONLY[FIFO_DEPTH-3:0],rptr_sync_marker_SIZE_ONLY[FIFO_DEPTH-1:FIFO_DEPTH-2]};

        always_ff @( posedge clk_marker or negedge rst_n ) begin
            if(~rst_n)
                rptr_sync_marker_SIZE_ONLY <= {{(FIFO_DEPTH-1){1'b0}},1'b1};
            else if(clear)
                rptr_sync_marker_SIZE_ONLY <= {{(FIFO_DEPTH-1){1'b0}},1'b1};
            else if(rinc && (rptr_switch==1'b1))
                rptr_sync_marker_SIZE_ONLY <= rptr_sync_nxt_size_only;
        end

        /*========================================*/
        /*          read response mux             */
        /*========================================*/

        assign pld_sync_marker = rptr_switch ? pld_sync_marker_1 : pld_sync_marker_0;


    end else begin:SINGLE_DATA_WIRE_LOGIC

            assign rptr_sync_nxt_size_only = {rptr_sync_marker_SIZE_ONLY[FIFO_DEPTH-2:0],rptr_sync_marker_SIZE_ONLY[FIFO_DEPTH-1]};

            always_ff @( posedge clk_marker or negedge rst_n ) begin
                if(~rst_n)
                    rptr_sync_marker_SIZE_ONLY <= {{(FIFO_DEPTH-1){1'b0}},1'b1};
                else if(clear)
                    rptr_sync_marker_SIZE_ONLY <= {{(FIFO_DEPTH-1){1'b0}},1'b1};
                else if(rinc)
                    rptr_sync_marker_SIZE_ONLY <= rptr_sync_nxt_size_only;
            end

    end
endgenerate

/*========================================*/
/*              write ptr sync             */
/*========================================*/

generate
    if(SYNC_STAGE == 2)begin:SYNC_STAGE_LEVEL_2
        fcip_sync_cell #(
            .DATA_WIDTH ( FIFO_DEPTH ),
            .SYN_STAGE  ( 2          ), // must upper than 1
            .VT_TYPE    ( 1          ), // 0: LVT, 1: SVT, 2: ULVT, 7: LVTLL, 8: ULVTLL
            .RST_VALUE  ( 0          )  // 0: sync_arst, 1: sync_aset
        ) rptr_sync_cell(
            .clk        ( clk_marker        ),
            .rst_n      ( rst_n             ),
            .d          ( wptr_async_marker ),
            .q          ( rq2_wptr_sync1    )
        );
    end else begin:SYNC_STAGE_LEVEL_3
        fcip_sync_cell #(
            .DATA_WIDTH ( FIFO_DEPTH ),
            .SYN_STAGE  ( 3          ), // must upper than 1
            .VT_TYPE    ( 1          ), // 0: LVT, 1: SVT, 2: ULVT, 7: LVTLL, 8: ULVTLL
            .RST_VALUE  ( 0          )  // 0: sync_arst, 1: sync_aset
        ) rptr_sync_cell(
            .clk        ( clk_marker        ),
            .rst_n      ( rst_n             ),
            .d          ( wptr_async_marker ),
            .q          ( rq2_wptr_sync1    )
        );
    end
endgenerate


/*========================================*/
/*               ptr compare              */
/*========================================*/

assign empty = ~(|((rptr_async_inner_SIZE_ONLY ^ rq2_wptr_sync1) & rptr_sync_inner_SIZE_ONLY));

/*========================================*/
/*           Generate threshold           */
/*========================================*/

generate 
    if(THRESHOLD_EN) begin:THRESHOLD_EN_OPEN

        logic [FIFO_DEPTH-1:0]   rq2_wptr_r;
        logic                    winc_fake;
        logic [PTR_WIDTH:0]      ptr_cnt;

        always_ff @( posedge clk_marker or negedge rst_n ) begin
            if(~rst_n)
                rq2_wptr_r <= {(FIFO_DEPTH){1'b0}};
            else
                rq2_wptr_r <= rq2_wptr_sync1;
        end

        assign winc_fake = |(rq2_wptr_r ^ rq2_wptr_sync1);

        always_ff @( posedge clk_marker or negedge rst_n ) begin
            if(~rst_n)
                ptr_cnt <= 'b0;
            else if(rinc && winc_fake)
                ptr_cnt <= ptr_cnt;
            else if(rinc)
                ptr_cnt <= ptr_cnt + 1'b1;
            else if(winc_fake)
                ptr_cnt <= ptr_cnt - 1'b1;
        end

        always_ff @( posedge clk_marker or negedge rst_n ) begin
            if(~rst_n)
                almost_empty <= 'b0;
            else if(ptr_cnt <= ALMOST_EMPTY_THRESHOLD)
                almost_empty <= 1'b1;
            else if( (ptr_cnt == (ALMOST_EMPTY_THRESHOLD-1)) && rinc && ~winc_fake)
                almost_empty <= 1'b1;
            else 
                almost_empty <= 1'b0;
        end
    end else begin
        assign almost_empty  = 1'b0;
    end
endgenerate

/*========================================*/
/*         read response reg slice        */
/*========================================*/

logic                   reg_slice_vld_r;
logic [DATA_WIDTH:0]    reg_slice_pld_r;

assign read_out_vld         = rinc;
assign read_out_data        = pld_sync_marker;
assign read_out_rdy         = ~reg_slice_vld_r || m_rdy;

always_ff @( posedge clk_marker or negedge rst_n ) begin
    if(~rst_n)
        reg_slice_vld_r <= 1'b0;
    else if(read_out_vld && read_out_rdy)
        reg_slice_vld_r <= 1'b1;
    else if(m_rdy)
        reg_slice_vld_r <= 1'b0;
end

always_ff @( posedge clk_marker or negedge rst_n ) begin
    if(~rst_n)
        reg_slice_pld_r <= 'b0;
    else if(read_out_vld && read_out_rdy)
        reg_slice_pld_r <= read_out_data;
end

/*========================================*/
/*               read stall               */
/*========================================*/

generate
    if(AUTO_CLEAR_EN == 1)begin
        logic read_resp_mask;
        logic bubble_en;

        assign bubble_en      = ~reg_slice_pld_r[0];
        assign read_resp_mask = stall || bubble_en;
        assign m_vld  = reg_slice_vld_r && ~read_resp_mask;
        assign m_pld  = reg_slice_pld_r[DATA_WIDTH:1];

    end else begin

        assign m_vld = reg_slice_vld_r;
        assign m_pld = reg_slice_pld_r[DATA_WIDTH:1];

    end
endgenerate

/*========================================*/
/*               CDC Marker               */
/*========================================*/

fcip_marker #(
    .DATA_WIDTH ( FIFO_DEPTH ),
    .VT_TYPE    (VT_TYPE)
) async_rptr_sync_marker(
    .I          ( rptr_sync_marker_SIZE_ONLY ),
    .Z          ( rptr_sync        )
);

fcip_marker #(
    .DATA_WIDTH ( FIFO_DEPTH ),
    .VT_TYPE    (VT_TYPE)
) rd_rptr_async_primary_marker(
    .I          ( rptr_async_marker_SIZE_ONLY ),
    .Z          ( rptr_async        )
);

generate 
    if(DOUBLE_DATA_WIRE == 1 ) begin
        fcip_marker #(
            .DATA_WIDTH ( DATA_WIDTH+1 ),
            .VT_TYPE    (VT_TYPE)
        ) async_pld_sync_0_marker(
            .I          ( pld_sync[DATA_WIDTH:0] ),
            .Z          ( pld_sync_marker_0 )
        );

        fcip_marker #(
            .DATA_WIDTH ( DATA_WIDTH+1 ),
            .VT_TYPE    (VT_TYPE)
        ) async_pld_sync_1_marker(
            .I          ( pld_sync[DATA_WIDTH*2 + 1 : DATA_WIDTH+1] ),
            .Z          ( pld_sync_marker_1 )
        );

    end else begin

        fcip_marker #(
            .DATA_WIDTH ( DATA_WIDTH+1 ),
            .VT_TYPE    (VT_TYPE)
        ) async_pld_sync_marker(
            .I          ( pld_sync        ),
            .Z          ( pld_sync_marker )
        );
    end 

endgenerate



fcip_marker #(
    .DATA_WIDTH ( FIFO_DEPTH ),
    .VT_TYPE    (VT_TYPE)
) async_wptr_async_marker(
    .I          ( wptr_async        ),
    .Z          ( wptr_async_marker )
);


endmodule