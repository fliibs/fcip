module fcip_sync_fifo_spram #(
    parameter  integer unsigned FIFO_DEPTH_PER_GROUP = 64,
    parameter  integer unsigned SRAM_GROUP_NUM = 2,
    parameter  integer unsigned DATA_WIDTH = 16,
    parameter  integer unsigned ALMOST_FULL_THRESHOLD = 2,
    parameter  integer unsigned ALMOST_EMPTY_THRESHOLD= 2,
    parameter  integer unsigned FORWARD_EN = 1,
    parameter  integer unsigned ROB_DEPTH = 16, //ROB DEPTH should be larger than MEM DATA PIPE Latency
    //for memory crl wrapper
    parameter  integer unsigned SRAM_ACCESS_LATENCY  = 1,
    parameter  integer unsigned SRAM_REQ_PIPE_STAGE = 0,
    parameter  integer unsigned SRAM_RSP_PIPE_STAGE = 0,
    parameter  integer unsigned MCP_CYCLE = 1,
    localparam int unsigned ADDR_WIDTH = $clog2(FIFO_DEPTH_PER_GROUP)
)(
    input  logic                        clk,
    input  logic                        rst_n,

    //power down
    input  logic                        stall,
    input  logic                        clear,
    output logic                        idle,

    //write req
    input  logic                        write_req_vld,
    input  logic [DATA_WIDTH-1:0]       write_req_pld,
    output logic                        write_req_rdy,

    //read response
    output logic                        read_resp_vld,
    output logic [DATA_WIDTH-1:0]       read_resp_pld,
    input  logic                        read_resp_rdy,

    output logic                        almost_full,
    output logic                        almost_empty,
    output logic                        empty,
    output logic                        full,

    //mem port
    output logic [ADDR_WIDTH -1 : 0]   spram_addr[SRAM_GROUP_NUM-1:0],
    output logic [DATA_WIDTH -1 : 0]   spram_din[SRAM_GROUP_NUM-1:0],
    input  logic [DATA_WIDTH -1 : 0]   spram_dout[SRAM_GROUP_NUM-1:0],
    output logic [SRAM_GROUP_NUM-1:0]  spram_en,
    output logic [SRAM_GROUP_NUM-1:0]  spram_wren,
    output logic [DATA_WIDTH -1 : 0]   spram_bit_en[SRAM_GROUP_NUM-1:0]
);

localparam int unsigned ROB_PTR_WIDTH               = $clog2(ROB_DEPTH);
localparam int unsigned SRAM_DELAY_TOTAL            = SRAM_ACCESS_LATENCY + SRAM_REQ_PIPE_STAGE + SRAM_RSP_PIPE_STAGE;
localparam int unsigned ROB_ALMOST_FULL_THRESHOLD   = ROB_DEPTH - SRAM_DELAY_TOTAL;
localparam int unsigned MEM_SIDEBAND_WIDTH          = ROB_PTR_WIDTH;

logic                           sram_empty;
logic                           rob_write_vld;
logic [DATA_WIDTH-1:0]          rob_write_pld;
logic                           rob_write_rdy;
logic [ROB_PTR_WIDTH-1:0]       rob_prealloc_id;
logic                           rob_empty;
logic [ROB_PTR_WIDTH-1:0]       sram_pre_alloc_id;
logic                           sram_req_vld;
logic [DATA_WIDTH-1:0]          sram_req_pld;
logic                           sram_req_rdy;
logic [ROB_PTR_WIDTH-1:0]       sram_req_id;
logic                           read_vld;
logic [DATA_WIDTH-1:0]          read_pld;
logic                           read_rdy;
logic                           rob_almost_empty;
logic                           rob_almost_full;
logic                           sram_pre_winc;

logic                           spram_ctrl_empty;
logic                           spram_ctrl_full;
logic                           sel_ram_en;
logic                           sel_rob_en;
logic                           rob_forward_en;
logic                           spram_ctrl_almost_full;
logic                           spram_ctrl_almost_empty;

logic                           ram_write_vld;
logic [DATA_WIDTH-1:0]          ram_write_pld;
logic                           ram_write_rdy;

logic                           sram_read_en;
logic [SRAM_GROUP_NUM-1:0]      sram_read_sel;
logic [SRAM_GROUP_NUM-1:0]      mem_req_vld;
logic [SRAM_GROUP_NUM-1:0]      mem_req_rdy;
logic [SRAM_GROUP_NUM-1:0]      mem_req_opcode;
logic [ADDR_WIDTH-1:0]          mem_req_addr[SRAM_GROUP_NUM-1:0];
logic [DATA_WIDTH-1:0]          mem_req_data[SRAM_GROUP_NUM-1:0];
logic [DATA_WIDTH-1:0]          mem_req_bit_en[SRAM_GROUP_NUM-1:0];
logic [MEM_SIDEBAND_WIDTH-1:0]  mem_req_sideband[SRAM_GROUP_NUM-1:0];

assign empty        = spram_ctrl_empty;
assign full         = spram_ctrl_full;
assign almost_full  = spram_ctrl_almost_full;
assign almost_empty = spram_ctrl_almost_empty;

assign idle         = rob_empty && spram_ctrl_empty;
/*========================================*/
/*               write arbiter            */
/*========================================*/

assign write_req_rdy    = sel_rob_en || sel_ram_en;

//assign rob_forward_en   = rob_write_rdy && spram_ctrl_empty;

assign sel_rob_en       = rob_write_rdy && spram_ctrl_empty;
assign sel_ram_en       = ram_write_rdy && ~sel_rob_en;

assign ram_write_vld    = write_req_vld && sel_ram_en;
assign ram_write_pld    = write_req_pld;
assign rob_write_vld    = write_req_vld && sel_rob_en;
assign rob_write_pld    = write_req_pld;

/*========================================*/
/*              SRAM R/W Ctrl             */
/*========================================*/

fcip_sfifo_spram_ctrl #(
    .FIFO_DEPTH_PER_GROUP(FIFO_DEPTH_PER_GROUP),
    .SRAM_GROUP_NUM (SRAM_GROUP_NUM),
    .DATA_WIDTH(DATA_WIDTH),
    .ALMOST_FULL_THRESHOLD (ALMOST_FULL_THRESHOLD),
    .ALMOST_EMPTY_THRESHOLD(ALMOST_EMPTY_THRESHOLD),
    .FORWARD_EN(0),
    .SIDEBAND_WIDTH(MEM_SIDEBAND_WIDTH)
)u_sfifo_spram_ctrl(
    .clk                    (clk             ),
    .rst_n                  (rst_n           ),
    .write_vld              (ram_write_vld   ),
    .write_pld              (ram_write_pld   ),
    .write_rdy              (ram_write_rdy   ),

    .sram_read_en           (sram_read_en     ),
    .sram_read_sel          (sram_read_sel    ),
    .sram_pre_alloc_id      (sram_pre_alloc_id),

    .spram_ctrl_empty       (spram_ctrl_empty),
    .spram_ctrl_full        (spram_ctrl_full ),
    .spram_ctrl_almost_full (spram_ctrl_almost_full),
    .spram_ctrl_almost_empty(spram_ctrl_almost_empty),

    .rob_almost_empty       (rob_almost_empty       ),
    .rob_almost_full        (rob_almost_full        ),

    .mem_req_vld            (mem_req_vld     ),
    .mem_req_rdy            (mem_req_rdy     ),
    .mem_req_opcode         (mem_req_opcode  ),
    .mem_req_addr           (mem_req_addr    ),
    .mem_req_data           (mem_req_data    ),
    .mem_req_bit_en         (mem_req_bit_en  ),
    .mem_req_sideband       (mem_req_sideband)
);

/*========================================*/
/*               pre-alloc                */
/*========================================*/

assign sram_pre_winc        = sram_read_en;  // sram ctrl empty and read enable
assign sram_pre_alloc_id    = rob_prealloc_id;

/*========================================*/
/*            fcip_mem_ctrl_wrap          */
/*========================================*/

logic [SRAM_GROUP_NUM-1:0]      mem_rsp_en;
logic [MEM_SIDEBAND_WIDTH-1:0]  mem_rsp_sideband[SRAM_GROUP_NUM-1:0];
logic [DATA_WIDTH-1:0]          mem_rsp_data[SRAM_GROUP_NUM-1:0];

generate
    for(genvar i=0;i<SRAM_GROUP_NUM;i++)begin:FIFO_SPRAM_MEM_CTRL_GEN

        fcip_mem_ctrl_wrap #(
            .SRAM_ACCESS_LATENCY(SRAM_ACCESS_LATENCY),
            .SRAM_REQ_PIPE_STAGE(SRAM_REQ_PIPE_STAGE),
            .SRAM_RSP_PIPE_STAGE(SRAM_RSP_PIPE_STAGE),
            .SIDEBAND_WIDTH(MEM_SIDEBAND_WIDTH),
            .DATA_WIDTH(DATA_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH),
            .MCP_CYCLE(MCP_CYCLE)
        )u_fifo_spram_mem_ctrl(
            .clk                 (clk             ),
            .rst_n               (rst_n           ),
            .mem_req_vld         (mem_req_vld[i]  ),
            .mem_req_rdy         (mem_req_rdy[i]  ),
            .mem_req_opcode      (mem_req_opcode[i]  ),
            .mem_req_addr        (mem_req_addr[i]    ),
            .mem_req_data        (mem_req_data[i]    ),
            .mem_req_bit_en      (mem_req_bit_en[i]  ),
            .mem_req_sideband    (mem_req_sideband[i]),

            .mem_rsp_en          (mem_rsp_en[i]      ),
            .mem_rsp_sideband    (mem_rsp_sideband[i]),
            .mem_rsp_data        (mem_rsp_data[i]    ),
            
            .spram_addr          (spram_addr[i]),
            .spram_din           (spram_din[i] ),
            .spram_dout          (spram_dout[i]),
            .spram_en            (spram_en[i]  ),
            .spram_wren          (spram_wren[i]),
            .spram_bit_en        (spram_bit_en[i])
        );

    end
endgenerate

/*========================================*/
/*                 ROB                    */
/*========================================*/

fcip_sfifo_spram_rob #(
    .ROB_DEPTH (ROB_DEPTH),
    .DATA_WIDTH(DATA_WIDTH),
    .FORWARD_EN(FORWARD_EN),
    .ALMOST_FULL_THRESHOLD(ROB_ALMOST_FULL_THRESHOLD),
    .ALMOST_EMPTY_THRESHOLD(0)
)u_sfifo_spram_rob(
    .clk                (clk            ),
    .rst_n              (rst_n          ),

    .rob_req_vld        (rob_write_vld  ),
    .rob_req_pld        (rob_write_pld  ),
    .rob_req_rdy        (rob_write_rdy  ),

    .ram_req_vld        (sram_req_vld    ),
    .ram_req_pld        (sram_req_pld    ),
    .ram_req_id         (sram_req_id     ),
    .ram_req_rdy        (sram_req_rdy    ),

    .read_vld           (read_resp_vld  ),
    .read_pld           (read_resp_pld  ),
    .read_rdy           (read_resp_rdy  ),

    .rob_empty          (rob_empty      ),
    .rob_full           (      ),
    .rob_almost_empty   (rob_almost_empty),
    .rob_almost_full    (rob_almost_full ),

    .sram_pre_winc      (sram_pre_winc  ),
    .rob_prealloc_id    (rob_prealloc_id)
    );

/*========================================*/
/*             Delay control              */
/*========================================*/

logic                       sram_read_en_delay;
logic [SRAM_GROUP_NUM-1:0]  sram_read_sel_delay;


    fcip_data_pipe #(
        .DATA_WIDTH  (1),
        .PIPE_STAGE  (SRAM_DELAY_TOTAL), // must upper than 1
        .VT_TYPE     (0) // 0: LVT, 1: SVT, 2: ULVT, 7: LVTLL, 8: ULVTLL
    ) u_sram_en_pipe(
        .clk         (clk  ),
        .rst_n       (rst_n),
        .d           (sram_read_en),
        .q           (sram_read_en_delay)
    );

    fcip_data_pipe #(
        .DATA_WIDTH  (SRAM_GROUP_NUM),
        .PIPE_STAGE  (SRAM_DELAY_TOTAL), // must upper than 1
        .VT_TYPE     (0) // 0: LVT, 1: SVT, 2: ULVT, 7: LVTLL, 8: ULVTLL
    ) u_sram_sel_pipe(
        .clk         (clk  ),
        .rst_n       (rst_n),
        .d           (sram_read_sel),
        .q           (sram_read_sel_delay)
    );

/*========================================*/
/*                SRAM MUX                */
/*========================================*/

logic [SRAM_GROUP_NUM-1:0]      sram_read_sel_delay_en;
logic [DATA_WIDTH-1:0]          mem_data_sel;
logic [MEM_SIDEBAND_WIDTH-1:0]  mem_rsp_sideband_sel;

assign sram_read_sel_delay_en = {SRAM_GROUP_NUM{sram_read_en_delay}} & sram_read_sel_delay;

fcip_real_mux_onehot #(
    .WIDTH     (SRAM_GROUP_NUM),
    .PLD_WIDTH (DATA_WIDTH)
)u_sram_data_mux(
    .select_onehot  (sram_read_sel_delay_en),
    .v_pld          (mem_rsp_data),
    .select_pld     (mem_data_sel)
);

fcip_real_mux_onehot #(
    .WIDTH     (SRAM_GROUP_NUM),
    .PLD_WIDTH (MEM_SIDEBAND_WIDTH)
)u_sram_sideband_mux(
    .select_onehot  (sram_read_sel_delay_en),
    .v_pld          (mem_rsp_sideband),
    .select_pld     (mem_rsp_sideband_sel)
);

assign sram_req_vld = |mem_rsp_en;
assign sram_req_pld = mem_data_sel;
assign sram_req_id  = mem_rsp_sideband_sel;

endmodule