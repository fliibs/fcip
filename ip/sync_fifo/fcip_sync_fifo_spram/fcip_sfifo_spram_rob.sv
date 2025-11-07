module fcip_sfifo_spram_rob #(
    parameter integer unsigned ROB_DEPTH  = 32,
    parameter integer unsigned DATA_WIDTH = 64,
    parameter integer unsigned FORWARD_EN = 1,
    parameter integer unsigned ALMOST_FULL_THRESHOLD  = 2,
    parameter integer unsigned ALMOST_EMPTY_THRESHOLD = 0,
    localparam int unsigned PTR_WIDTH = $clog2(ROB_DEPTH)
)(
    input   logic                   clk,
    input   logic                   rst_n,

    input   logic                   rob_req_vld,
    input   logic [DATA_WIDTH-1:0]  rob_req_pld,
    output  logic                   rob_req_rdy,

    input   logic                   ram_req_vld,
    input   logic [DATA_WIDTH-1:0]  ram_req_pld,
    input   logic [PTR_WIDTH-1:0]   ram_req_id,
    output  logic                   ram_req_rdy,
    
    output  logic                   read_vld,
    output  logic [DATA_WIDTH-1:0]  read_pld,
    input   logic                   read_rdy,

    output  logic                   rob_empty,
    output  logic                   rob_full,
    output  logic                   rob_almost_empty,
    output  logic                   rob_almost_full,

    input   logic                   sram_pre_winc,
    output  logic [PTR_WIDTH-1:0]   rob_prealloc_id
);

logic                   rob_winc;
logic                   sram_winc;
logic                   rinc;
logic                   winc_incr;
logic                   winc_vld;
logic [DATA_WIDTH-1:0]  array_data[ROB_DEPTH-1:0];
logic [ROB_DEPTH-1:0]   array_vld;
logic [DATA_WIDTH-1:0]  winc_data;

logic [PTR_WIDTH-1:0]   rob_wptr;
logic [PTR_WIDTH-1:0]   rob_rptr;
logic [PTR_WIDTH-1:0]   rob_vld_ptr_id;
logic [PTR_WIDTH:0]     ptr_cnt;


/*========================================*/
/*              read/write req            */
/*========================================*/

generate 
    if(FORWARD_EN==1)begin

        logic                   entry_read_vld;
        logic                   direct_forward_en;
        logic                   sram_forward_en;
        logic                   rob_forward_en;
        logic                   rob_forward_vld;
        logic [DATA_WIDTH-1:0]  rob_forward_pld;
        
        assign direct_forward_en= rob_empty && read_rdy;
        assign sram_forward_en  = ram_req_rdy && read_rdy && (ram_req_id==rob_rptr);
        assign rob_forward_en   = direct_forward_en || sram_forward_en;

        assign rob_forward_vld  = ram_req_vld || rob_req_vld;
        assign rob_forward_pld  = direct_forward_en ? rob_req_pld : ram_req_pld;
        assign entry_read_vld   = ~rob_empty && array_vld[rob_rptr];

        //out response
        assign read_vld         = rob_forward_en ? rob_forward_vld : entry_read_vld;
        assign read_pld         = rob_forward_en ? rob_forward_pld : array_data[rob_rptr];

        //rob entry ptr inc
        assign rob_winc         = rob_req_vld && rob_req_rdy && ~direct_forward_en;
        assign rinc             = (entry_read_vld && read_rdy) || (sram_forward_en && ram_req_vld);

    end else begin

        assign rob_winc         = rob_req_vld && rob_req_rdy;

        assign read_vld         = ~rob_empty && array_vld[rob_rptr];
        assign read_pld         = array_data[rob_rptr];
        assign rinc             = read_vld && read_rdy;

    end
endgenerate

assign sram_winc         = ram_req_vld && ram_req_rdy;

assign ram_req_rdy       = ~rob_full;
assign rob_req_rdy       = ~rob_full;

assign winc_incr         = sram_pre_winc || rob_winc;
assign winc_vld          = sram_winc || rob_winc;
assign rob_vld_ptr_id    = sram_winc ? ram_req_id : rob_wptr;
assign winc_data         = sram_winc ? ram_req_pld : rob_req_pld;

assign rob_prealloc_id   = rob_wptr;

/*========================================*/
/*                rptr/wptr               */
/*========================================*/

always_ff @( posedge clk or negedge rst_n ) begin
    if(~rst_n)
        rob_wptr <= 'b0;
    else if(winc_incr)
        rob_wptr <= rob_wptr + 1'b1;
end

always_ff @( posedge clk or negedge rst_n ) begin
    if(~rst_n)
        rob_rptr <= 'b0;
    else if(rinc)
        rob_rptr <= rob_rptr + 1'b1;
end

always_ff @( posedge clk or negedge rst_n ) begin
    if(~rst_n)
        ptr_cnt <= 'b0;
    else if(winc_incr && rinc)
        ptr_cnt <= ptr_cnt;
    else if(winc_incr)
        ptr_cnt <= ptr_cnt + 1'b1;
    else if(rinc)
        ptr_cnt <= ptr_cnt - 1'b1;
end

/*========================================*/
/*               pointer check            */
/*========================================*/

always_ff @( posedge clk or negedge rst_n ) begin
    if(~rst_n)
        rob_full <= 'b0;
    else if( (ptr_cnt == (ROB_DEPTH-1)) && winc_incr && ~rinc)
        rob_full <= 1'b1;
    else if( ptr_cnt <= (ROB_DEPTH-1) )
        rob_full <= 1'b0;
end

always_ff @( posedge clk or negedge rst_n ) begin
    if(~rst_n)
        rob_empty <= 'b1;
    else if( (ptr_cnt == 1) && rinc && ~winc_incr )
        rob_empty <= 1'b1;
    else if( ptr_cnt >= 1 )
        rob_empty <= 1'b0;
end

//assign rob_empty = (ptr_cnt==0);
//assign rob_full  = (ptr_cnt==ROB_DEPTH);

always_ff @( posedge clk or negedge rst_n ) begin
    if(~rst_n)
        rob_almost_full <= 'b0;
    else if( ptr_cnt >= ALMOST_FULL_THRESHOLD)
        rob_almost_full <= 1'b1;
    else if( (ptr_cnt == (ALMOST_FULL_THRESHOLD-1)) && winc_incr && ~rinc)
        rob_almost_full <= 1'b1;
    else 
        rob_almost_full <= 1'b0;
end

always_ff @( posedge clk or negedge rst_n ) begin
    if(~rst_n)
        rob_almost_empty <= 'b0;
    else if(ptr_cnt <= ALMOST_EMPTY_THRESHOLD)
        rob_almost_empty <= 1'b1;
    else if( (ptr_cnt == (ALMOST_EMPTY_THRESHOLD-1)) && rinc && ~winc_incr)
        rob_almost_empty <= 1'b1;
    else 
        rob_almost_empty <= 1'b0;
end

//assign rob_almost_empty = (ptr_cnt==ALMOST_EMPTY_THRESHOLD);
//assign rob_almost_full  = (ptr_cnt==ALMOST_FULL_THRESHOLD);

/*========================================*/
/*               rob entry                */
/*========================================*/

generate
    for(genvar i=0;i<ROB_DEPTH;i++)begin

        always_ff @( posedge clk ) begin
            if(winc_vld && (rob_vld_ptr_id==i))
                array_data[i] <= winc_data;
        end

        always_ff @( posedge clk or negedge rst_n) begin
            if(~rst_n)
                array_vld[i] <= 1'b0;
            else if(rinc && (rob_rptr==i) )
                array_vld[i] <= 1'b0;
            else if(winc_vld && (rob_vld_ptr_id==i))
                array_vld[i] <= 1'b1;
        end

    end
endgenerate

endmodule