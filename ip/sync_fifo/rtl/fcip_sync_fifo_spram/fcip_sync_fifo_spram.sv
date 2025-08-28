module fcip_sync_fifo_spram #(
    parameter  integer unsigned FIFO_DEPTH_PER_GROUP = 64,
    parameter  integer unsigned SRAM_GROUP_NUM = 2,
    parameter  integer unsigned DATA_WIDTH = 16,
    parameter  integer unsigned ALMOST_FULL_THRESHOLD = 2,
    parameter  integer unsigned ALMOST_EMPTY_THRESHOLD= 2,
    parameter  integer unsigned FORWARD_EN = 1,
    parameter  integer unsigned ROB_DEPTH = 16, 
    parameter  integer unsigned MEM_SIDEBAND_WIDTH =1,
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

localparam int unsigned ROB_PTR_WIDTH = $clog2(ROB_DEPTH);

logic                       sram_empty;
logic                       rob_write_vld;
logic [DATA_WIDTH-1:0]      rob_write_pld;
logic                       rob_write_rdy;
logic [ROB_PTR_WIDTH-1:0]   rob_prealloc_id;
logic                       ram_req_vld;
logic [DATA_WIDTH-1:0]      ram_req_pld;
logic                       ram_req_rdy;
logic                       read_vld;
logic [DATA_WIDTH-1:0]      read_pld;
logic                       read_rdy;
logic                       rob_empty;
logic                       rob_full;
logic                       sram_pre_winc;

logic   spram_ctrl_empty;
logic   spram_ctrl_full;
logic   sel_ram_en;
logic   sel_rob_en;
logic   rob_forward_en;
logic   spram_ctrl_almost_full;
logic   spram_ctrl_almost_empty;


logic                   ram_write_vld;
logic [DATA_WIDTH-1:0]  ram_write_pld;
logic                   ram_write_rdy;

assign empty        = spram_ctrl_empty;
assign full         = spram_ctrl_full;
assign almost_full  = spram_ctrl_almost_full;
assign almost_empty = spram_ctrl_almost_empty;

/*========================================*/
/*                 Decode                 */
/*========================================*/

assign write_req_rdy    = ram_write_rdy;

assign rob_forward_en   = (FORWARD_EN==1) && rob_empty && spram_ctrl_empty;

assign sel_ram_en       = ram_write_rdy && ~rob_forward_en;
assign sel_rob_en       = rob_forward_en;

assign ram_write_vld    = write_req_vld && sel_ram_en;
assign ram_write_pld    = write_req_pld;
assign rob_write_vld    = write_req_vld && sel_rob_en;
assign rob_write_pld    = write_req_pld;

/*========================================*/
/*              SRAM R/W Ctrl             */
/*========================================*/
logic                       ram_read_en;
logic [SRAM_GROUP_NUM-1:0]  ram_read_sel;

logic [SRAM_GROUP_NUM-1:0]   mem_req_vld;
logic [SRAM_GROUP_NUM-1:0]   mem_req_rdy;
logic [SRAM_GROUP_NUM-1:0]   mem_req_opcode;
logic [ADDR_WIDTH-1:0]       mem_req_addr[SRAM_GROUP_NUM-1:0];
logic [DATA_WIDTH-1:0]       mem_req_data[SRAM_GROUP_NUM-1:0];
logic [DATA_WIDTH-1:0]       mem_req_bit_en[SRAM_GROUP_NUM-1:0];
logic [MEM_SIDEBAND_WIDTH-1:0]mem_req_sideband[SRAM_GROUP_NUM-1:0];

fcip_sfifo_spram_ctrl #(
    .FIFO_DEPTH_PER_GROUP(FIFO_DEPTH_PER_GROUP),
    .SRAM_GROUP_NUM (SRAM_GROUP_NUM),
    .DATA_WIDTH(DATA_WIDTH),
    .ALMOST_FULL_THRESHOLD (FIFO_DEPTH_PER_GROUP/2),
    .ALMOST_EMPTY_THRESHOLD(FIFO_DEPTH_PER_GROUP/4),
    .FORWARD_EN(0),
    .SIDEBAND_WIDTH(MEM_SIDEBAND_WIDTH)
)u_sfifo_spram_ctrl(
    .clk                    (clk             ),
    .rst_n                  (rst_n           ),
    .write_vld              (ram_write_vld   ),
    .write_pld              (ram_write_pld   ),
    .write_rdy              (ram_write_rdy   ),
    .ram_read_en            (ram_read_en     ),
    .ram_read_sel           (ram_read_sel    ),
    .spram_ctrl_empty       (spram_ctrl_empty),
    .spram_ctrl_full        (spram_ctrl_full ),
    .spram_ctrl_almost_full (spram_ctrl_almost_full),
    .spram_ctrl_almost_empty(spram_ctrl_almost_empty),
    .rob_empty              (rob_empty       ),
    .rob_full               (rob_full        ),

    .mem_req_vld            (mem_req_vld     ),
    .mem_req_rdy            (mem_req_rdy     ),
    .mem_req_opcode         (mem_req_opcode  ),
    .mem_req_addr           (mem_req_addr    ),
    .mem_req_data           (mem_req_data    ),
    .mem_req_bit_en         (mem_req_bit_en  ),
    .mem_req_sideband       (mem_req_sideband)
);

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
    .FORWARD_EN(FORWARD_EN)
)u_sfifo_spram_rob(
    .clk                (clk            ),
    .rst_n              (rst_n          ),
    .rob_req_vld        (rob_write_vld  ),
    .rob_req_pld        (rob_write_pld  ),
    .rob_req_rdy        (rob_write_rdy  ),
    .rob_prealloc_id    (rob_prealloc_id),
    .ram_req_vld        (ram_req_vld    ),
    .ram_req_pld        (ram_req_pld    ),
    .ram_req_rdy        (ram_req_rdy    ),
    .read_vld           (read_resp_vld  ),
    .read_pld           (read_resp_pld  ),
    .read_rdy           (read_resp_rdy  ),
    .rob_empty          (rob_empty      ),
    .rob_full           (rob_full       ),
    .sram_pre_winc      (sram_pre_winc  )
    );

/*========================================*/
/*             Delay control              */
/*========================================*/

localparam integer unsigned SRAM_DELAY_TOTAL = SRAM_ACCESS_LATENCY + SRAM_REQ_PIPE_STAGE + SRAM_RSP_PIPE_STAGE;
logic                       ram_read_en_delay;
logic [SRAM_GROUP_NUM-1:0]  ram_read_sel_delay;

generate 
    if(SRAM_DELAY_TOTAL ==1)begin
        always_ff @(posedge clk or negedge rst_n) begin
            if (~rst_n) begin
                ram_read_en_delay <= 'b0;
            end else begin
                ram_read_en_delay <= ram_read_en;
            end
        end

        always_ff @(posedge clk or negedge rst_n) begin
            if (~rst_n) begin
                ram_read_sel_delay <= 'b0;
            end else begin
                ram_read_sel_delay <= ram_read_sel;
            end
        end
    end else begin
        fcip_sync_cell #(
        .DATA_WIDTH  (1),
        .SYN_STAGE   (SRAM_DELAY_TOTAL), // must upper than 1
        .VT_TYPE     (1), // 0: LVT, 1: SVT, 2: ULVT, 7: LVTLL, 8: ULVTLL
        .RST_VALUE   (0)// 0: sync_arst, 1: sync_aset
    ) u_sram_en_sync(
        .clk         (clk  ),
        .rst_n       (rst_n),
        .d           (ram_read_en),
        .q           (ram_read_en_delay)
    );

    fcip_sync_cell #(
        .DATA_WIDTH  (SRAM_GROUP_NUM),
        .SYN_STAGE   (SRAM_DELAY_TOTAL), // must upper than 1
        .VT_TYPE     (1), // 0: LVT, 1: SVT, 2: ULVT, 7: LVTLL, 8: ULVTLL
        .RST_VALUE   (0)// 0: sync_arst, 1: sync_aset
    ) u_sram_sel_sync(
        .clk         (clk  ),
        .rst_n       (rst_n),
        .d           (ram_read_sel),
        .q           (ram_read_sel_delay)
    );
    end
endgenerate

/*========================================*/
/*                SRAM MUX                */
/*========================================*/

logic [SRAM_GROUP_NUM-1:0]  ram_read_sel_delay_en;
logic [DATA_WIDTH-1:0]      mem_data_sel;

assign ram_read_sel_delay_en = {SRAM_GROUP_NUM{ram_read_en_delay}} & ram_read_sel_delay;

fcip_real_mux_onehot #(
    .WIDTH     (SRAM_GROUP_NUM),
    .PLD_WIDTH (DATA_WIDTH)
)u_sram_data_mux(
    .select_onehot  (ram_read_sel_delay_en),
    .v_pld          (mem_rsp_data),
    .select_pld     (mem_data_sel)
);

assign ram_req_vld = |mem_rsp_en;
assign ram_req_pld = mem_data_sel;

endmodule