module fifo_fake_2p_mem
#(
    parameter integer unsigned MEM_DEPTH = 256,
    parameter integer unsigned MEM_DATA_WIDTH = 128,
    parameter integer unsigned READ_SFIFO_DEPTH = 8,
    localparam int unsigned MEM_ADDR_WIDTH = $clog2(MEM_DEPTH)
)(
    input logic                         clk,
    input logic                         rst_n,

    //power down
    input  logic                        stall,
    input  logic                        clear,
    output logic                        idle,

    //write req
    input  logic                        write_req_vld,
    input  logic [MEM_DATA_WIDTH-1:0]   write_req_pld,
    output logic                        write_req_rdy,

    //read response
    output logic                        read_resp_vld,
    output logic [MEM_DATA_WIDTH-1:0]   read_resp_pld,
    input  logic                        read_resp_rdy,

    //spram0 port
    output logic [MEM_ADDR_WIDTH-1:0]   spram0_addr,
    output logic [MEM_DATA_WIDTH-1:0]   spram0_din,
    input  logic [MEM_DATA_WIDTH-1:0]   spram0_dout,
    output logic                        spram0_en,
    output logic                        spram0_wren,

    //spram1 port
    output logic [MEM_ADDR_WIDTH-1:0]   spram1_addr,
    output logic [MEM_DATA_WIDTH-1:0]   spram1_din,
    input  logic [MEM_DATA_WIDTH-1:0]   spram1_dout,
    output logic                        spram1_en,
    output logic                        spram1_wren
);

logic                        write_spram0_vld;
logic [MEM_DATA_WIDTH-1:0]   write_spram0_pld;
logic                        write_spram0_rdy;
logic                        write_spram1_vld;
logic [MEM_DATA_WIDTH-1:0]   write_spram1_pld;
logic                        write_spram1_rdy;

logic                        write_lut_req_vld;
logic                        write_lut_req_pld;
logic                        write_lut_req_rdy;
logic                        read_lut_req_vld;
logic                        read_lut_req_pld;
logic                        read_lut_req_rdy;

logic                        read_spram0_vld;
logic                        read_spram0_rdy;
logic [MEM_DATA_WIDTH-1:0]   read_spram0_rdata;
logic                        spram0_fifo_idle;

logic                        read_spram1_vld;
logic                        read_spram1_rdy;
logic [MEM_DATA_WIDTH-1:0]   read_spram1_rdata;
logic                        spram1_fifo_idle;

//logic                        spram0_empty;
//logic                        spram1_empty;

/*========================================*/
/*              Write req gen             */
/*========================================*/

fifo_fake_write_req_gen #(
    .MEM_DEPTH      (MEM_DEPTH),
    .MEM_DATA_WIDTH (MEM_DATA_WIDTH)
)u_write_req_gen(
    .clk                    (clk),
    .rst_n                  (rst_n),
    .clear                  (clear),

    .write_req_vld          (write_req_vld),
    .write_req_pld          (write_req_pld),
    .write_req_rdy          (write_req_rdy),

    .write_spram0_req_vld   (write_spram0_vld),
    .write_spram0_req_pld   (write_spram0_pld),
    .write_spram0_req_rdy   (write_spram0_rdy),
    .write_spram1_req_vld   (write_spram1_vld),
    .write_spram1_req_pld   (write_spram1_pld),
    .write_spram1_req_rdy   (write_spram1_rdy),

    .write_lut_req_vld      (write_lut_req_vld),
    .write_lut_req_pld      (write_lut_req_pld),
    .write_lut_req_rdy      (write_lut_req_rdy)
);

/*========================================*/
/*              Lookup Table              */
/*========================================*/

sync_fifo_reg #(
    .FIFO_DEPTH(MEM_DEPTH*2),
    .FIFO_WIDTH(1),
    .THRESHOLD(MEM_DEPTH*2-1)
) u_lookup_table_fifo(
    .clk                (clk),
    .rst_n              (rst_n),

    .stall              (stall),
    .clear              (clear),
    .idle               (lut_fifo_idle),

    .write_req_vld      (write_lut_req_vld),
    .write_req_pld      (write_lut_req_pld),
    .write_req_rdy      (write_lut_req_rdy),

    .read_resp_vld      (read_lut_req_vld),
    .read_resp_pld      (read_lut_req_pld),
    .read_resp_rdy      (read_lut_req_rdy),

    .custom_threshold_en(),
    .empty              (),
    .full               ()
);

/*========================================*/
/*           spram0 controller            */
/*========================================*/

sync_fifo_spram #(
    .FIFO_DEPTH(MEM_DEPTH),
    .FIFO_WIDTH(MEM_DATA_WIDTH),
    .THRESHOLD(MEM_DEPTH-1)
) spram0_sfifo(
    .clk                (clk),
    .rst_n              (rst_n),

    .stall              (stall),
    .clear              (clear),
    .idle               (spram0_fifo_idle),

    .write_req_vld      (write_spram0_vld ),
    .write_req_pld      (write_spram0_pld),
    .write_req_rdy      (write_spram0_rdy ),

    .read_resp_vld      (read_spram0_vld),
    .read_resp_pld      (read_spram0_rdata),
    .read_resp_rdy      (read_spram0_rdy),

    .custom_threshold_en(),
    .empty              (),
    .full               (),

    .spram_addr         (spram0_addr         ),
    .spram_din          (spram0_din          ),
    .spram_dout         (spram0_dout         ),
    .spram_en           (spram0_en           ),
    .spram_wren         (spram0_wren         )
);

/*========================================*/
/*           spram1 controller            */
/*========================================*/

sync_fifo_spram #(
    .FIFO_DEPTH(MEM_DEPTH),
    .FIFO_WIDTH(MEM_DATA_WIDTH),
    .THRESHOLD(MEM_DEPTH-1)
) spram1_sfifo(
    .clk                (clk),
    .rst_n              (rst_n),

    .stall              (stall),
    .clear              (clear),
    .idle               (spram1_fifo_idle),

    .write_req_vld      (write_spram1_vld ),
    .write_req_pld      (write_spram1_pld),
    .write_req_rdy      (write_spram1_rdy ),

    .read_resp_vld      (read_spram1_vld),
    .read_resp_pld      (read_spram1_rdata),
    .read_resp_rdy      (read_spram1_rdy),

    .custom_threshold_en(),
    .empty              (),
    .full               (),

    .spram_addr         (spram1_addr         ),
    .spram_din          (spram1_din          ),
    .spram_dout         (spram1_dout         ),
    .spram_en           (spram1_en           ),
    .spram_wren         (spram1_wren         )
);

/*========================================*/
/*              Read Resp gen             */
/*========================================*/

fifo_fake_read_resp_gen #(
    .MEM_DEPTH      (MEM_DEPTH),
    .MEM_DATA_WIDTH (MEM_DATA_WIDTH),
    .READ_SFIFO_DEPTH(READ_SFIFO_DEPTH)
)u_read_resp_gen(
    .clk                    (clk              ),
    .rst_n                  (rst_n            ),
    .stall                  (stall            ),
    .clear                  (clear            ),
    .idle                   (read_fifo_idle   ),

    .read_spram0_vld        (read_spram0_vld  ),
    .read_spram0_rdy        (read_spram0_rdy  ),
    .read_spram0_rdata      (read_spram0_rdata),

    .read_spram1_vld        (read_spram1_vld  ),
    .read_spram1_rdy        (read_spram1_rdy  ),
    .read_spram1_rdata      (read_spram1_rdata),

    .read_lut_req_vld       (read_lut_req_vld ),
    .read_lut_req_pld       (read_lut_req_pld ),
    .read_lut_req_rdy       (read_lut_req_rdy ),

    .read_resp_vld          (read_resp_vld    ),
    .read_resp_pld          (read_resp_pld    ),
    .read_resp_rdy          (read_resp_rdy    )
);

assign idle           = spram0_fifo_idle && spram1_fifo_idle && read_fifo_idle && lut_fifo_idle;

endmodule