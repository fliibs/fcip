module fcip_sfifo_spram_ptr_ctrl #(
    parameter  integer unsigned FIFO_DEPTH_PER_GROUP = 64,
    parameter integer unsigned DATA_WIDTH = 64,
    parameter integer unsigned SIDEBAND_WIDTH = 64,
    localparam int unsigned ADDR_WIDTH = $clog2(FIFO_DEPTH_PER_GROUP)
)(
    input   logic                       clk,
    input   logic                       rst_n,

    input   logic                       write_vld,
    input   logic [DATA_WIDTH-1:0]      write_pld,
    output  logic                       write_rdy,
    
    input   logic                       read_vld,
    output  logic                       read_rdy,
    input   logic [SIDEBAND_WIDTH-1:0]  read_sideband,                       

    output  logic                       ram_ctrl_empty,
    output  logic                       ram_ctrl_full,

    output  logic                       mem_req_vld,
    input   logic                       mem_req_rdy,
    output  logic                       mem_req_opcode,
    output  logic [ADDR_WIDTH-1:0]      mem_req_addr,
    output  logic [DATA_WIDTH-1:0]      mem_req_data,
    output  logic [DATA_WIDTH-1:0]      mem_req_bit_en,
    output  logic [SIDEBAND_WIDTH-1:0]  mem_req_sideband
);

logic [ADDR_WIDTH-1:0] rptr;
logic [ADDR_WIDTH-1:0] wptr;
logic [ADDR_WIDTH:0]   ptr_cnt;

logic                  winc,rinc;

/*========================================*/
/*               write req                */
/*========================================*/

assign write_rdy    = ~ram_ctrl_full ; //TODO
assign winc         = write_vld && write_rdy;

/*========================================*/
/*                read req                */
/*========================================*/

assign read_rdy = ~ram_ctrl_empty && mem_req_rdy;
assign rinc     = read_vld && read_rdy;

/*========================================*/
/*               sram ctrl                */
/*========================================*/

assign mem_req_vld      = rinc || winc;     
assign mem_req_opcode   = winc ? 1'b1 : 1'b0;  
assign mem_req_addr     = wptr;    
assign mem_req_data     = write_pld;    
assign mem_req_bit_en   = {DATA_WIDTH{1'b1}};
assign mem_req_sideband = read_sideband;

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