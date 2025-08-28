module fcip_sfifo_spram_lut #(
    parameter  integer unsigned FIFO_DEPTH_PER_GROUP = 64,
    parameter  integer unsigned SRAM_GROUP_NUM = 64,
    localparam int unsigned ADDR_WIDTH = $clog2(SRAM_GROUP_NUM),
    localparam int unsigned DATA_WIDTH = $clog2(SRAM_GROUP_NUM)
)(
    input   logic                       clk,
    input   logic                       rst_n,

    input   logic                       write_vld,
    input   logic [DATA_WIDTH-1:0]      write_pld,
    output  logic                       write_rdy,
    
    output  logic                       read_vld,
    output  logic                       read_data,
    input   logic                       read_rdy,

    output  logic                       lut_empty,
    output  logic                       lut_full
);

logic [ADDR_WIDTH-1:0] rptr;
logic [ADDR_WIDTH-1:0] wptr;
logic [ADDR_WIDTH:0]   ptr_cnt;

logic ram_ctrl_full;
logic ram_ctrl_empty;

/*========================================*/
/*               write req                */
/*========================================*/

assign write_rdy    = ~ram_ctrl_full;
assign winc         = write_vld && write_rdy;

/*========================================*/
/*                read req                */
/*========================================*/

assign read_vld = ~ram_ctrl_empty;
assign rinc     = read_vld && read_rdy;

/*========================================*/
/*               sram ctrl                */
/*========================================*/

assign spram_addr   = wptr;
assign spram_din    = write_pld;
assign spram_en     = rinc || winc;
assign spram_wren   = winc;

/*========================================*/
/*               rptr/wptr                */
/*========================================*/

always_ff @( posedge clk or negedge rst_n ) begin
    if(~rst_n)
        wptr <= 'b0;
    else if(winc)
        wptr <= wptr + 1'b1;
end

always_ff @( posedge clk or negedge rst_n ) begin
    if(~rst_n)
        rptr <= 'b0;
    else if(rinc)
        rptr <= rptr + 1'b1;
end

always_ff @( posedge clk or negedge rst_n ) begin
    if(~rst_n)
        ptr_cnt <= 'b0;
    else if(winc && rinc)
        ptr_cnt <= ptr_cnt;
    else if(winc)
        ptr_cnt <= ptr_cnt + 1'b1;
    else if(rinc)
        ptr_cnt <= ptr_cnt - 1'b1;
end

assign ram_ctrl_empty = (ptr_cnt==0);
assign ram_ctrl_full  = (ptr_cnt==FIFO_DEPTH_PER_GROUP);

endmodule