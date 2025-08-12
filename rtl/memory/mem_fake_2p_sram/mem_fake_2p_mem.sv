module mem_fake_2p_mem 
    import mem_fake_pack::*;
#(
    parameter integer unsigned MEM_DEPTH = 256,
    localparam int unsigned MEM_ADDR_WIDTH = $clog2(MEM_DEPTH),
    parameter integer unsigned MEM_DATA_WIDTH = 128,
    parameter integer unsigned WRITE_BUFFER_DEPTH =16,
    parameter integer unsigned FIFO_DEPTH = 8,
    localparam int unsigned FIFO_PTR_WIDTH = $clog2(FIFO_DEPTH)
)(
    input  logic                        clk,
    input  logic                        rst_n,

    //write req
    input  logic                        write_req_vld,
    input  mem_fake_write_req_t         write_req_pld,
    output logic                        write_req_rdy,

    //read_req
    input  logic                        read_req_vld,
    input  logic [MEM_ADDR_WIDTH-1:0]   read_req_pld,
    output logic                        read_req_rdy,

    //read response
    output logic                        read_resp_vld,
    output logic [MEM_DATA_WIDTH-1:0]   read_resp_pld,
    input  logic                        read_resp_rdy,

    //mem port
    output logic [MEM_ADDR_WIDTH-1:0]   addr,
    output logic [MEM_DATA_WIDTH-1:0]   din,
    input  logic [MEM_DATA_WIDTH-1:0]   dout,
    output logic                        en,
    output logic                        wren,

    //lowpower
    input  logic                        stall,
    input  logic                        clear,
    output logic                        idle
);

localparam int unsigned FIFO_THRESHOLD = FIFO_DEPTH-1;

/*========================================*/
/*               write buffer             */
/*========================================*/

logic                        write_buffer_full;
logic                        write_buffer_empty;
logic                        write_sram_vld;
logic                        write_sram_rdy;
mem_fake_write_req_t         write_sram_pld;

logic                        read_cmp_vld;
logic [MEM_ADDR_WIDTH-1:0]   read_cmp_addr;
logic                        read_cmp_hit;

logic [MEM_DATA_WIDTH-1:0]   read_buffer_data;
logic                        read_sram_vld;
logic [MEM_ADDR_WIDTH-1:0]   read_sram_addr;
logic                        read_out_vld;
logic                        read_out_rdy;
logic [MEM_DATA_WIDTH-1:0]   read_out_data;
logic                        fifo_full;
logic                        fifo_almost_full;

mem_fake_write_buffer #(
    .MEM_DEPTH          (MEM_DEPTH),
    .MEM_ADDR_WIDTH     (MEM_ADDR_WIDTH),
    .MEM_DATA_WIDTH     (MEM_DATA_WIDTH),
    .WRITE_BUFFER_DEPTH (WRITE_BUFFER_DEPTH)
) u_mem_fake_write_buffer(
    .clk                    (clk             ),
    .rst_n                  (rst_n           ),

    .write_req_vld          (write_req_vld   ),
    .write_req_pld          (write_req_pld   ),
    .write_req_rdy          (write_req_rdy   ),

    .buffer_full            (write_buffer_full  ),
    .buffer_empty           (write_buffer_empty ),

    .write_vld              (write_sram_vld       ),
    .write_rdy              (write_sram_rdy       ),
    .write_pld              (write_sram_pld       ),

    .clear                  (clear           ),
    .stall                  (stall           ),

    .read_cmp_vld           (read_cmp_vld    ),
    .read_cmp_addr          (read_cmp_addr   ),
    .read_cmp_hit           (read_cmp_hit    ),
    .read_buffer_data       (read_buffer_data)
);

assign read_cmp_vld         = read_sram_vld;
assign read_cmp_addr        = read_sram_addr;

/*========================================*/
/*             Read req arbiter           */
/*========================================*/

//replace by fixed arbiter

assign read_req_rdy         = ~(fifo_full || write_buffer_full || fifo_almost_full || stall);
assign read_sram_vld        = read_req_vld && read_req_rdy;
assign read_sram_addr       = read_req_pld;

assign addr                 = read_sram_vld ? read_sram_addr : write_sram_pld.write_addr;
assign din                  = write_sram_pld.write_data;
assign en                   = read_sram_vld || write_sram_vld;
assign wren                 = read_sram_vld ? 1'b0 : write_sram_vld;

assign read_out_data        = read_cmp_hit ? read_buffer_data : dout;

always_ff @( posedge clk or negedge rst_n ) begin
    if(~rst_n)
        read_out_vld <= 1'b0;
    else 
        read_out_vld <= read_sram_vld;
end

assign fifo_full        = ~(read_out_rdy);

/*========================================*/
/*              Sync fifo                 */
/*========================================*/

sync_fifo_reg #(
    .FIFO_DEPTH(FIFO_DEPTH),
    .FIFO_WIDTH(MEM_DATA_WIDTH),
    .THRESHOLD(FIFO_THRESHOLD)
) u_sync_fifo(
    .clk                (clk),
    .rst_n              (rst_n),

    .stall              (stall),
    .clear              (clear),
    .idle               (sync_fifo_idle),

    .write_req_vld      (read_out_vld ),
    .write_req_pld      (read_out_data ),
    .write_req_rdy      (read_out_rdy),

    .read_resp_vld      (read_resp_vld),
    .read_resp_pld      (read_resp_pld),
    .read_resp_rdy      (read_resp_rdy),

    .custom_threshold_en(fifo_almost_full),
    .empty              (),
    .full               ()
);

assign idle = sync_fifo_idle && write_buffer_empty;

endmodule