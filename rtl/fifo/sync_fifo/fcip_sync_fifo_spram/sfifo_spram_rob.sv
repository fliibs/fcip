module sfifo_spram_rob #(
    parameter integer unsigned ROB_DEPTH  = 32,
    parameter integer unsigned DATA_WIDTH = 64,
    parameter integer unsigned FORWARD_EN = 1,
    localparam int unsigned PTR_WIDTH = $clog2(ROB_DEPTH)
)(
    input   logic                   clk,
    input   logic                   rst_n,

    input   logic                   rob_req_vld,
    input   logic [DATA_WIDTH-1:0]  rob_req_pld,
    //input   logic                 rob_req_id,
    output  logic                   rob_req_rdy,
    output  logic [PTR_WIDTH-1:0]   rob_prealloc_id,

    input   logic                   ram_req_vld,
    input   logic [DATA_WIDTH-1:0]  ram_req_pld,
    //input   logic [ADDR_WIDTH-1:0]  ram_req_id,
    output  logic                   ram_req_rdy,
    
    output  logic                   read_vld,
    output  logic [DATA_WIDTH-1:0]  read_pld,
    input   logic                   read_rdy,

    output  logic                   rob_empty,
    output  logic                   rob_full,

    input   logic                   sram_pre_winc
);

logic                   rinc;
logic                   winc_incr;
logic                   winc_vld;
logic [DATA_WIDTH-1:0]  array_data[ROB_DEPTH-1:0];
logic [ROB_DEPTH-1:0]   array_vld;
//logic [ROB_DEPTH-1:0]   array_idle;
logic [DATA_WIDTH-1:0]  winc_data;

logic [PTR_WIDTH-1:0]   rob_wptr;
logic [PTR_WIDTH-1:0]   rob_rptr;
logic [PTR_WIDTH:0]     ptr_cnt;

/*========================================*/
/*                write req               */
/*========================================*/

assign ram_req_rdy       = ~rob_full;
assign sram_winc          = ram_req_vld && ram_req_rdy;

//assign rob_req_rdy       = rob_empty;
assign rob_req_rdy       = ~rob_full;
assign rob_winc          = rob_req_vld && rob_req_rdy;

assign winc_incr         = sram_pre_winc || rob_winc;
assign winc_vld          = sram_winc || rob_winc;
assign winc_data         = sram_winc ? ram_req_pld : rob_req_pld;

/*========================================*/
/*                read req                */
/*========================================*/

assign read_vld     = ~rob_empty && array_vld[rob_rptr];
assign read_pld     = array_data[rob_rptr];
assign rinc         = read_vld && read_rdy;

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

assign rob_empty = (ptr_cnt==0);
assign rob_full  = (ptr_cnt==ROB_DEPTH);

/*========================================*/
/*               rob entry                */
/*========================================*/

generate
    for(genvar i=0;i<ROB_DEPTH;i++)begin

        always_ff @( posedge clk ) begin
            if(winc_vld && (rob_wptr==i))
                array_data[i] <= winc_data;
        end

        always_ff @( posedge clk or negedge rst_n) begin
            if(~rst_n)
                array_vld[i] <= 1'b0;
            else if(rinc && (rob_rptr==i) )
                array_vld[i] <= 1'b0;
            else if(winc_vld && (rob_wptr==i))
                array_vld[i] <= 1'b1;
        end

        //always_ff @( posedge clk ) begin
        //    if(~rst_n)
        //        array_idle[i] <= 1'b1;
        //    else if(sram_pre_winc && (rob_prealloc_id==i))
        //        array_idle[i] <= 1'b0;
        //    else if(winc && (rob_wptr==i))
        //        array_idle[i] <= 1'b0;
        //end
    end
endgenerate

endmodule