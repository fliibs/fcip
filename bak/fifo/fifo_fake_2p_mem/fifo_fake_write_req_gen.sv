module fifo_fake_write_req_gen
#(
    parameter integer unsigned MEM_DEPTH = 256,
    parameter integer unsigned MEM_DATA_WIDTH = 128,
    localparam int unsigned MEM_ADDR_WIDTH  = $clog2(MEM_DEPTH),
    localparam int unsigned LUT_DEPTH       = MEM_DEPTH*2
)(
    input  logic                        clk,
    input  logic                        rst_n,

    //power down
    //input  logic                        stall,
    input  logic                        clear,
    //output logic                        idle,

    //write req
    input  logic                        write_req_vld,
    input  logic [MEM_DATA_WIDTH-1:0]   write_req_pld,
    output logic                        write_req_rdy,

    //write req to spram0
    output logic                        write_spram0_req_vld,
    output logic [MEM_DATA_WIDTH-1:0]   write_spram0_req_pld,
    input  logic                        write_spram0_req_rdy,

    //write req to spram1
    output logic                        write_spram1_req_vld,
    output logic [MEM_DATA_WIDTH-1:0]   write_spram1_req_pld,
    input  logic                        write_spram1_req_rdy,

    //write req to lookup table
    output logic                        write_lut_req_vld,
    output logic                        write_lut_req_pld,
    input  logic                        write_lut_req_rdy
);

logic   write_alloc_index;
logic   write_req_handshake;
//logic   lut_full;

/*========================================*/
/*              Write stall               */
/*========================================*/

//assign lut_full                     = write_lut_req_rdy;
assign write_req_rdy                = (write_spram0_req_rdy || write_spram1_req_rdy) && write_lut_req_rdy;
assign write_req_handshake          = write_req_vld && write_req_rdy;

/*========================================*/
/*              spram prealloc            */
/*========================================*/

logic   write_prealloc_index;

always_ff @( posedge clk or negedge rst_n ) begin
    if(~rst_n)
        write_prealloc_index <= 1'b0;
    else if(clear)
        write_prealloc_index <= 1'b0;
    else if(write_req_handshake)
        write_prealloc_index <= ~write_alloc_index;
end

/*========================================*/
/*               Write  alloc             */
/*========================================*/

//assign write_alloc_index    = (write_spram0_req_rdy && write_spram1_req_rdy) ? write_prealloc_index : write_spram1_req_rdy ? 1'b1 : 1'b0;

assign write_alloc_index = write_spram0_req_vld ? 1'b0 : 1'b1;

assign write_lut_req_vld = write_req_handshake;
assign write_lut_req_pld = write_alloc_index; // 0: spram0 , 1:spram1

/*========================================*/
/*           Sram write req gen           */
/*========================================*/

//assign write_spram0_req_vld  = (write_alloc_index==0) && write_req_handshake;

assign write_spram0_req_vld  = ((write_prealloc_index==0) || (write_spram0_req_rdy && ~write_spram1_req_rdy)) && write_req_handshake;
assign write_spram0_req_pld  = write_req_pld;

//assign write_spram1_req_vld  = (write_alloc_index==1) && write_req_handshake;
assign write_spram1_req_vld  = ((write_prealloc_index==1) || (~write_spram1_req_rdy && write_spram1_req_rdy)) && write_req_handshake;
assign write_spram1_req_pld  = write_req_pld;

endmodule