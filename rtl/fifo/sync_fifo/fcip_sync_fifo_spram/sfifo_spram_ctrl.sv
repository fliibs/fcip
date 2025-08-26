module sfifo_spram_ctrl #(
    parameter  integer unsigned FIFO_DEPTH_PER_GROUP = 64,
    parameter integer unsigned SRAM_GROUP_NUM  = 2,
    parameter integer unsigned DATA_WIDTH = 64,
    parameter  integer unsigned ALMOST_FULL_THRESHOLD = 2,
    parameter  integer unsigned ALMOST_EMPTY_THRESHOLD= 2,
    parameter integer unsigned FORWARD_EN = 1,
    parameter integer unsigned SIDEBAND_WIDTH = 1,
    localparam int unsigned ADDR_WIDTH = $clog2(FIFO_DEPTH_PER_GROUP)
)(
    input   logic                       clk,
    input   logic                       rst_n,

    input   logic                       write_vld,
    input   logic [DATA_WIDTH-1:0]      write_pld,
    output  logic                       write_rdy,
    
    output  logic                       sram_read_en,
    output  logic [SRAM_GROUP_NUM-1:0]  sram_read_sel,
    input   logic [SIDEBAND_WIDTH-1:0]  sram_pre_alloc_id,

    output  logic                       spram_ctrl_empty,
    output  logic                       spram_ctrl_full,
    output  logic                       spram_ctrl_almost_full,
    output  logic                       spram_ctrl_almost_empty,

    input   logic                       rob_almost_empty,
    input   logic                       rob_almost_full,

    output logic [SRAM_GROUP_NUM-1:0]   mem_req_vld,
    input  logic [SRAM_GROUP_NUM-1:0]   mem_req_rdy,
    output logic [SRAM_GROUP_NUM-1:0]   mem_req_opcode,
    output logic [ADDR_WIDTH-1:0]       mem_req_addr[SRAM_GROUP_NUM-1:0],
    output logic [DATA_WIDTH-1:0]       mem_req_data[SRAM_GROUP_NUM-1:0],
    output logic [DATA_WIDTH-1:0]       mem_req_bit_en[SRAM_GROUP_NUM-1:0],
    output logic [SIDEBAND_WIDTH-1:0]   mem_req_sideband[SRAM_GROUP_NUM-1:0]
);

logic                       ptr_ctrl_write_vld[SRAM_GROUP_NUM-1:0];
logic [DATA_WIDTH-1:0]      ptr_ctrl_write_pld;
logic [SRAM_GROUP_NUM-1:0]  ptr_ctrl_write_rdy;
logic [SRAM_GROUP_NUM-1:0]  ptr_ctrl_read_vld;
logic [SRAM_GROUP_NUM-1:0]  ptr_ctrl_read_rdy;
logic                       ptr_ctrl_empty[SRAM_GROUP_NUM-1:0];
logic                       ptr_ctrl_full[SRAM_GROUP_NUM-1:0];

logic                       lut_req_vld;
logic [SRAM_GROUP_NUM-1:0]  lut_req_pld;
logic                       lut_req_rdy;
logic                       lut_resp_vld;
logic [SRAM_GROUP_NUM-1:0]  lut_resp_pld;
logic                       lut_resp_rdy;

/*========================================*/
/*             sram write alloc           */
/*========================================*/

logic [SRAM_GROUP_NUM-1:0]      sram_write_rdy;
logic [SRAM_GROUP_NUM-1:0]      sram_write_alloc;

generate
    for(genvar i=0;i<SRAM_GROUP_NUM;i++)begin
        
        assign ptr_ctrl_read_vld[i]     = lut_resp_pld[i] && sram_read_en;
        assign sram_write_rdy[i]        = ptr_ctrl_write_rdy[i] && ~ptr_ctrl_read_vld[i];
        assign ptr_ctrl_write_vld[i]    = sram_write_alloc[i] && write_vld;

    end
endgenerate

assign write_rdy          = ~spram_ctrl_full;
assign ptr_ctrl_write_pld = write_pld;

cmn_grant_gen_rr #(
    .WIDTH(SRAM_GROUP_NUM)
) u_write_alloc(
    .clk    (clk),
    .rst_n  (rst_n),

    .v_vld  (sram_write_rdy),
    .v_grant(sram_write_alloc)
);

/*========================================*/
/*              sram ptr ctrl             */
/*========================================*/

logic [SRAM_GROUP_NUM-1:0] spram_ctrl_write_handshake;

generate
    for(genvar i=0;i<SRAM_GROUP_NUM;i++)begin:SRAM_GRP_PTR_CTRL
        
        sfifo_spram_ptr_ctrl #(
            .FIFO_DEPTH_PER_GROUP(FIFO_DEPTH_PER_GROUP),
            .DATA_WIDTH          (DATA_WIDTH),
            .SIDEBAND_WIDTH      (SIDEBAND_WIDTH)
        ) u_spram_ptr_ctrl(
            .clk            (clk                    ),
            .rst_n          (rst_n                  ),
            .write_vld      (ptr_ctrl_write_vld[i]  ),
            .write_pld      (ptr_ctrl_write_pld     ),
            .write_rdy      (ptr_ctrl_write_rdy[i]  ),

            .read_vld       (ptr_ctrl_read_vld[i]   ),
            .read_rdy       (ptr_ctrl_read_rdy[i]   ),
            .read_sideband  (sram_pre_alloc_id       ),

            .ram_ctrl_empty (ptr_ctrl_empty[i]      ),//unused
            .ram_ctrl_full  (ptr_ctrl_full[i]       ),//unused

            .mem_req_vld     (mem_req_vld[i]        ),
            .mem_req_rdy     (mem_req_rdy[i]        ),
            .mem_req_opcode  (mem_req_opcode[i]     ),
            .mem_req_addr    (mem_req_addr[i]       ),
            .mem_req_data    (mem_req_data[i]       ),
            .mem_req_bit_en  (mem_req_bit_en[i]     ),
            .mem_req_sideband(mem_req_sideband[i]   )
        );

        assign spram_ctrl_write_handshake[i] = ptr_ctrl_write_vld[i] && ptr_ctrl_write_rdy[i];

    end
endgenerate

/*========================================*/
/*                  LUT                   */
/*========================================*/
localparam  integer unsigned LUT_DEPTH = FIFO_DEPTH_PER_GROUP*SRAM_GROUP_NUM;

sync_fifo_reg #(
    .FIFO_DEPTH(LUT_DEPTH),
    .FIFO_WIDTH(SRAM_GROUP_NUM),
    .ALMOST_FULL_THRESHOLD (ALMOST_FULL_THRESHOLD),
    .ALMOST_EMPTY_THRESHOLD(ALMOST_EMPTY_THRESHOLD),
    .FORWARD_EN(0)
)u_sfifo_spram_lut(
    .clk            (clk  ),
    .rst_n          (rst_n),
    .stall          (1'b0),
    .clear          (1'b0),
    .idle           (),
    .write_req_vld  (lut_req_vld),
    .write_req_pld  (lut_req_pld),
    .write_req_rdy  (lut_req_rdy),

    .read_resp_vld  (lut_resp_vld),
    .read_resp_pld  (lut_resp_pld),
    .read_resp_rdy  (lut_resp_rdy),

    .almost_full    (spram_ctrl_almost_full),
    .almost_empty   (spram_ctrl_almost_empty),
    .empty          (ram_lut_empty),
    .full           (ram_lut_full)
);

assign lut_req_pld  = spram_ctrl_write_handshake;
assign lut_req_vld  = |spram_ctrl_write_handshake;
assign lut_full     = ram_lut_full;

assign lut_resp_rdy = ~rob_almost_full && (|ptr_ctrl_read_rdy); //TODO

assign spram_ctrl_empty     = ~(|ptr_ctrl_read_rdy) || ram_lut_empty;
assign spram_ctrl_full      = ram_lut_full;

/*========================================*/
/*           read delay control           */
/*========================================*/

assign sram_read_en          = lut_resp_vld && lut_resp_rdy;
assign sram_read_sel         = lut_resp_pld;

endmodule