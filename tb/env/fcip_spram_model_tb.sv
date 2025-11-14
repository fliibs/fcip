// fcip_spram_model_tb.sv
// Testbench for fcip_spram_model

`timescale 1ns/1ps

module fcip_spram_model_tb;
    parameter ADDR_WIDTH = 10;
    parameter DATA_WIDTH = 32;
    localparam DEPTH = 1 << ADDR_WIDTH;
    localparam TEST_NUM = 10000;

    reg clk;
    reg en;
    reg [ADDR_WIDTH-1:0] addr;
    reg [DATA_WIDTH-1:0] wr_data;
    reg [DATA_WIDTH-1:0] wr_bit_en;
    reg wr_en;
    wire [DATA_WIDTH-1:0] rd_data;

    // reference model
    reg [DATA_WIDTH-1:0] ref_mem [0:DEPTH-1];

    // DUT
    fcip_spram_model #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .en(en),
        .addr(addr),
        .rd_data(rd_data),
        .wr_data(wr_data),
        .wr_bit_en(wr_bit_en),
        .wr_en(wr_en)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    integer i;
    reg [DATA_WIDTH-1:0] exp_data;
    reg [ADDR_WIDTH-1:0] rand_addr;
    reg [DATA_WIDTH-1:0] rand_data;
    reg [DATA_WIDTH-1:0] rand_bit_en;

    initial begin
        en = 1;
        wr_en = 0;
        addr = 0;
        wr_data = 0;
        wr_bit_en = 0;
        // 初始化参考模型
        for (i = 0; i < DEPTH; i = i + 1) begin
            ref_mem[i] = 0;
        end
        #20;

        // 大规模随机写
        for (i = 0; i < TEST_NUM; i = i + 1) begin
            rand_addr = $urandom_range(0, DEPTH-1);
            rand_data = $urandom();
            rand_bit_en = $urandom();
            addr = rand_addr;
            wr_data = rand_data;
            wr_bit_en = rand_bit_en;
            wr_en = 1;
            #10;
            wr_en = 0;
            // 参考模型写
            ref_mem[rand_addr] = (ref_mem[rand_addr] & ~rand_bit_en) | (rand_data & rand_bit_en);
            #10;
        end

        // 随机读并校验
        for (i = 0; i < TEST_NUM; i = i + 1) begin
            rand_addr = $urandom_range(0, DEPTH-1);
            addr = rand_addr;
            #10;
            exp_data = ref_mem[rand_addr];
            if (rd_data !== exp_data) begin
                $display("[ERROR] Addr=%0d, expect=%h, got=%h", rand_addr, exp_data, rd_data);
            end
        end
        $display("Random test finished.");
        $finish;
    end
endmodule
