module fcip_mem_ctrl_wrap #(
    parameter integer unsigned SRAM_ACCESS_LATENCY = 1,
    parameter integer unsigned SRAM_REQ_PIPE_STAGE = 0,
    parameter integer unsigned SRAM_RSP_PIPE_STAGE = 0,
    parameter integer unsigned SIDEBAND_WIDTH = 1,
    parameter integer unsigned DATA_WIDTH = 32,
    parameter integer unsigned ADDR_WIDTH = 10,
    parameter integer unsigned MCP_CYCLE = 1
)(
    input logic                         clk,
    input logic                         rst_n,

    input   logic                       mem_req_vld,
    output  logic                       mem_req_rdy,
    input   logic                       mem_req_opcode,
    input   logic [ADDR_WIDTH-1:0]      mem_req_addr,
    input   logic [DATA_WIDTH-1:0]      mem_req_data,
    input   logic [DATA_WIDTH-1:0]      mem_req_bit_en,
    input   logic [SIDEBAND_WIDTH-1:0]  mem_req_sideband,

    output  logic                       mem_rsp_en,
    output  logic [SIDEBAND_WIDTH-1:0]  mem_rsp_sideband,
    output  logic [DATA_WIDTH-1:0]      mem_rsp_data,
    
    //memory port
    output logic [ADDR_WIDTH -1 : 0]    spram_addr,
    output logic [DATA_WIDTH -1 : 0]    spram_din,
    input  logic [DATA_WIDTH -1 : 0]    spram_dout,
    output logic [DATA_WIDTH -1 : 0]    spram_bit_en,
    output logic                        spram_en,
    output logic                        spram_wren
);

logic mem_req_handshake;
logic ram_read_en;

// flow control

localparam integer unsigned DATA_PIPE_LATENCY = SRAM_ACCESS_LATENCY + SRAM_REQ_PIPE_STAGE +SRAM_RSP_PIPE_STAGE;
localparam integer unsigned MCP_LATENCY_WIDTH = $clog2(MCP_CYCLE);

generate 
    if(MCP_CYCLE==1)begin
        
        assign mem_req_rdy = 1'b1;
        assign mem_req_handshake    = mem_req_vld && mem_req_rdy;

    end else begin
        logic [MCP_LATENCY_WIDTH-1:0] mcp_cnt;

        assign mem_req_rdy          = (mcp_cnt == 0);
        assign mem_req_handshake    = mem_req_vld && mem_req_rdy;

        always @(posedge clk or negedge rst_n) begin
            if(~rst_n)
                mcp_cnt <= 'b0;
            else if(mcp_cnt == (MCP_CYCLE-1))
                mcp_cnt <= 'b0;
            else if(mem_req_handshake)
                mcp_cnt <= mcp_cnt + 1'b1;
        end
    end
endgenerate

//memory_wrap

assign spram_addr   = mem_req_addr;
assign spram_din    = mem_req_data;
assign spram_en     = mem_req_handshake;
assign spram_wren   = mem_req_opcode==1;
assign spram_bit_en = (mem_req_opcode==1) ? mem_req_bit_en : {(DATA_WIDTH){1'b1}};

//sram_marker

fcip_marker #(
    .DATA_WIDTH(DATA_WIDTH)
)u_memory_ctrl_marker(
    .I  (spram_dout),
    .Z  (mem_rsp_data)
);

//resp en/sideband pipeline

assign ram_read_en = mem_req_handshake && (mem_req_opcode==0);

//data pipe
    
    fcip_data_pipe #(
        .DATA_WIDTH  (1),
        .PIPE_STAGE  (DATA_PIPE_LATENCY), // must upper than 1
        .VT_TYPE     (0) // 0: LVT, 1: SVT, 2: ULVT, 7: LVTLL, 8: ULVTLL
    ) u_sram_read_en_sync(
        .clk         (clk  ),
        .rst_n       (rst_n),
        .d           (ram_read_en),
        .q           (mem_rsp_en)
    );

    fcip_data_pipe #(
        .DATA_WIDTH  (SIDEBAND_WIDTH),
        .PIPE_STAGE  (DATA_PIPE_LATENCY), // must upper than 1
        .VT_TYPE     (0) // 0: LVT, 1: SVT, 2: ULVT, 7: LVTLL, 8: ULVTLL
    ) u_sram_sideband_sync(
        .clk         (clk  ),
        .rst_n       (rst_n),
        .d           (mem_req_sideband),
        .q           (mem_rsp_sideband)
    );

endmodule