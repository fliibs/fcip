module fifo_fake_read_resp_gen
#(
    parameter integer unsigned MEM_DEPTH = 256,
    parameter integer unsigned MEM_DATA_WIDTH = 128,
    parameter integer unsigned READ_SFIFO_DEPTH = 8,
    localparam int unsigned MEM_ADDR_WIDTH = $clog2(MEM_DEPTH)
)(
    input logic     clk,
    input logic     rst_n,

    //power down
    input  logic                        stall,
    input  logic                        clear,
    output logic                        idle,

    //read_req
    input  logic                        read_spram0_vld,
    output logic                        read_spram0_rdy,
    input  logic [MEM_DATA_WIDTH-1:0]   read_spram0_rdata,

    input  logic                        read_spram1_vld,
    output logic                        read_spram1_rdy,
    input  logic [MEM_DATA_WIDTH-1:0]   read_spram1_rdata,

    input  logic                        read_lut_req_vld,
    input  logic                        read_lut_req_pld,
    output logic                        read_lut_req_rdy,

    //read response
    output logic                        read_resp_vld,
    output logic [MEM_DATA_WIDTH-1:0]   read_resp_pld,
    input  logic                        read_resp_rdy
);

localparam int unsigned READ_SFIFO_THRESHOLD = READ_SFIFO_DEPTH-1;

logic                       spram0_rd_en;
logic                       spram1_rd_en;
logic                       sync_fifo_almost_full;
logic                       read_out_vld;
logic                       read_out_rdy;
logic [MEM_DATA_WIDTH-1:0]  read_out_data;
logic                       sync_fifo_full;
logic                       read_lut_handshake;

/*========================================*/
/*            read lookup table           */
/*========================================*/

assign read_lut_req_rdy         = ~(sync_fifo_full || sync_fifo_almost_full);
assign read_lut_handshake       = read_lut_req_rdy && read_lut_req_vld;

/*========================================*/
/*             ram read select            */
/*========================================*/

assign spram0_rd_en             = (read_lut_req_pld==0);
assign spram1_rd_en             = (read_lut_req_pld==1);

assign read_spram0_rdy          = spram0_rd_en && read_lut_handshake;
assign read_spram1_rdy          = spram1_rd_en && read_lut_handshake;

/*========================================*/
/*            read resp buffer            */
/*========================================*/

assign read_out_data    = read_spram1_vld ? read_spram1_rdata : read_spram0_rdata;
assign read_out_vld     = (read_spram0_vld && read_spram0_rdy) || (read_spram1_vld && read_spram1_rdy);
assign sync_fifo_full   = ~read_out_rdy;

sync_fifo_reg #(
    .FIFO_DEPTH(READ_SFIFO_DEPTH),
    .FIFO_WIDTH(MEM_DATA_WIDTH),
    .THRESHOLD(READ_SFIFO_THRESHOLD)
) u_sync_fifo(
    .clk                (clk),
    .rst_n              (rst_n),

    .stall              (stall),
    .clear              (clear),
    .idle               (sync_fifo_idle),

    .write_req_vld      (read_out_vld ),
    .write_req_pld      (read_out_data),
    .write_req_rdy      (read_out_rdy ),

    .read_resp_vld      (read_resp_vld),
    .read_resp_pld      (read_resp_pld),
    .read_resp_rdy      (read_resp_rdy),

    .custom_threshold_en(sync_fifo_almost_full),
    .empty              (),
    .full               ()
);

assign idle = sync_fifo_idle;

endmodule