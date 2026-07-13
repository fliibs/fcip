module fcip_mem_ctrl_wrap #(
    parameter integer unsigned SRAM_ACCESS_LATENCY = 1,
    parameter integer unsigned SRAM_REQ_PIPE_STAGE = 0,
    parameter integer unsigned SRAM_RSP_PIPE_STAGE = 0,
    parameter integer unsigned SIDEBAND_WIDTH = 1,
    parameter integer unsigned DATA_WIDTH = 32,
    parameter integer unsigned ADDR_WIDTH = 10,
    parameter integer unsigned MCP_CYCLE = 1,
    parameter integer unsigned ECC_EN = 0,
    localparam integer unsigned MEM_CODE_WIDTH = ($clog2(DATA_WIDTH)+DATA_WIDTH+1 <= 2**$clog2(DATA_WIDTH))? $clog2(DATA_WIDTH) : $clog2(DATA_WIDTH) + 1,
    localparam integer unsigned MEM_TOTAL_WIDTH = DATA_WIDTH + MEM_CODE_WIDTH + 1
)(
    input logic                                                     clk,
    input logic                                                     rst_n,

    input   logic                                                   mem_req_vld,
    output  logic                                                   mem_req_rdy,
    input   logic                                                   mem_req_opcode,
    input   logic [ADDR_WIDTH-1:0]                                  mem_req_addr,
    input   logic [DATA_WIDTH-1:0]                                  mem_req_data,
    input   logic [DATA_WIDTH-1:0]                                  mem_req_bit_en,
    input   logic [SIDEBAND_WIDTH-1:0]                              mem_req_sideband,

    output  logic                                                   mem_rsp_en,
    output  logic [SIDEBAND_WIDTH-1:0]                              mem_rsp_sideband,
    output  logic [DATA_WIDTH-1:0]                                  mem_rsp_data,
    
    //memory port
    output logic [ADDR_WIDTH -1 : 0]                                spram_addr,
    output logic [(ECC_EN ? MEM_TOTAL_WIDTH-1 : DATA_WIDTH-1):0]    spram_din,
    input  logic [(ECC_EN ? MEM_TOTAL_WIDTH-1 : DATA_WIDTH-1):0]    spram_dout,
    output logic [(ECC_EN ? MEM_TOTAL_WIDTH-1 : DATA_WIDTH-1):0]    spram_bit_en,
    output logic                                                    spram_en,
    output logic                                                    spram_wren,

    output logic                                                    ecc_sb_err,
    output logic                                                    ecc_db_err,
    output logic                                                    ecc_comp_err
);

logic mem_req_handshake;
logic ram_read_en;

// flow control

localparam integer unsigned DATA_PIPE_LATENCY = ECC_EN ? SRAM_ACCESS_LATENCY + SRAM_REQ_PIPE_STAGE +SRAM_RSP_PIPE_STAGE + 2
                                                            : SRAM_ACCESS_LATENCY + SRAM_REQ_PIPE_STAGE +SRAM_RSP_PIPE_STAGE;
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
            else if( mcp_cnt != 0)
                mcp_cnt <= mcp_cnt + 1'b1;
        end
    end
endgenerate

//memory_wrap

//sram_marker

generate 
    if(ECC_EN==1)begin

        logic [MEM_TOTAL_WIDTH-1 : 0] mem_req_data_ecc;
        logic [MEM_TOTAL_WIDTH-1 : 0] mem_req_data_ecc_1d;
        logic [ADDR_WIDTH-1:0]        mem_req_addr_1d     ;
        logic                         mem_req_handshake_1d;
        logic                         mem_req_wren_1d     ;
        logic [MEM_TOTAL_WIDTH-1 : 0] mem_req_bit_en_1d   ;

        fcip_ecc_enc #(
            .DATA_WIDTH(DATA_WIDTH)
        ) u_fcip_ecc_enc(
            .data       (mem_req_data),
            .encode_data(mem_req_data_ecc)
        );

        always @(posedge clk or negedge rst_n) begin
            if(~rst_n) begin
                mem_req_addr_1d      <= 'b0;
                mem_req_data_ecc_1d  <= 'b0;
                mem_req_handshake_1d <= 'b0;
                mem_req_wren_1d      <= 'b0;
                mem_req_bit_en_1d    <= 'b0;
            end else begin
                mem_req_addr_1d      <= mem_req_addr;
                mem_req_data_ecc_1d  <= mem_req_data_ecc;
                mem_req_handshake_1d <= mem_req_handshake;
                mem_req_wren_1d      <= mem_req_opcode==1;
                mem_req_bit_en_1d    <= (mem_req_opcode==1) ? {mem_req_bit_en,{(MEM_TOTAL_WIDTH-DATA_WIDTH){1'b1}}} : {(DATA_WIDTH){1'b1}};
            end
        end

        assign spram_din    = mem_req_data_ecc_1d;
        assign spram_addr   = mem_req_addr_1d;
        assign spram_en     = mem_req_handshake_1d;
        assign spram_wren   = mem_req_wren_1d;
        assign spram_bit_en = mem_req_bit_en_1d;

    end else begin

        assign spram_din    = mem_req_data;
        assign spram_addr   = mem_req_addr;
        assign spram_en     = mem_req_handshake;
        assign spram_wren   = mem_req_opcode==1;
        assign spram_bit_en = (mem_req_opcode==1) ? mem_req_bit_en : {(DATA_WIDTH){1'b1}};

    end
endgenerate


generate 
    if(ECC_EN==1)begin

        logic [DATA_WIDTH-1 : 0] spram_dout_decc;
        logic [DATA_WIDTH-1 : 0] spram_dout_decc_1d;
        logic                    ecc_sb_err_decc;
        logic                    ecc_db_err_decc;
        logic                    ecc_comp_err_decc;
        logic                    ecc_sb_err_1d;
        logic                    ecc_db_err_1d;
        logic                    ecc_comp_err_1d;

        fcip_ecc_dec_dcls #(
            .DATA_WIDTH  (DATA_WIDTH)
        ) u_fcip_ecc_dec_dcls(
            .encode_data(spram_dout),
            .data       (spram_dout_decc),
            .sb_err     (ecc_sb_err_decc),
            .db_err     (ecc_db_err_decc),
            .comp_err   (ecc_comp_err_decc)
        );

        always @(posedge clk or negedge rst_n) begin
            if(~rst_n) begin
                spram_dout_decc_1d      <= 'b0;
                ecc_sb_err_1d           <= 'b0;
                ecc_db_err_1d           <= 'b0;
                ecc_comp_err_1d         <= 'b0;
            end else begin
                spram_dout_decc_1d      <= spram_dout_decc;
                ecc_sb_err_1d           <= ecc_sb_err_decc;
                ecc_db_err_1d           <= ecc_db_err_decc;
                ecc_comp_err_1d         <= ecc_comp_err_decc;
            end
        end

        assign ecc_sb_err   = ecc_sb_err_1d   && mem_rsp_en;
        assign ecc_db_err   = ecc_db_err_1d   && mem_rsp_en;
        assign ecc_comp_err = ecc_comp_err_1d && mem_rsp_en;

        fcip_marker #(
            .DATA_WIDTH(DATA_WIDTH)
        )u_memory_ctrl_marker(
            .I  (spram_dout_decc_1d),
            .Z  (mem_rsp_data)
        );

    end else begin

        fcip_marker #(
            .DATA_WIDTH(DATA_WIDTH)
        )u_memory_ctrl_marker(
            .I  (spram_dout),
            .Z  (mem_rsp_data)
        );

        assign ecc_sb_err   = 1'b0;
        assign ecc_db_err   = 1'b0;
        assign ecc_comp_err = 1'b0;

    end
endgenerate

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
