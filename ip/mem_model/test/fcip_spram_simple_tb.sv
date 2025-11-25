// Simple SPRAM test without PLI - tests basic functionality
`timescale 1ns/1ps

module fcip_spram_simple_tb;
    parameter ADDR_WIDTH = 10;
    parameter DATA_WIDTH = 32;

    reg clk;
    reg en;
    reg [ADDR_WIDTH-1:0] addr;
    reg [DATA_WIDTH-1:0] wr_data;
    reg [DATA_WIDTH-1:0] wr_bit_en;
    reg wr_en;
    wire [DATA_WIDTH-1:0] rd_data;
    integer errors = 0;

    // Simple combinational memory for reference
    reg [DATA_WIDTH-1:0] ref_mem [0:1023];

    // DUT - with ARGPARSE_KEY parameter for hex loading
    fcip_spram_model #(
        .ARGPARSE_KEY("SPRAM_HEX"),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ALLOW_NO_HEX(1)
    ) dut (
        .clk(clk),
        .en(en),
        .addr(addr),
        .rd_data(rd_data),
        .wr_data(wr_data),
        .wr_bit_en(wr_bit_en),
        .wr_en(wr_en)
    );

    initial begin
        en = 1;
        wr_en = 0;
        addr = 0;
        wr_data = 0;
        wr_bit_en = 0;
        
        // Initialize ref_mem
        for (int i = 0; i < 1024; i = i + 1)
            ref_mem[i] = 0;

        repeat (2) @(posedge clk);

        $display("\n=== Phase 0: HEX File Load Test ===");
        
        // Expected hex file values at addresses 0-9
        // @0: DEADBEEF, CAFEBABE, 12345678, ABCDEF00, FEEDFACE, 11111111, 22222222, 33333333, FFFFFFFF, 00000000
        
        // Test reading addresses 0-9 that should be loaded from hex file
        for (int i = 0; i < 10; i = i + 1) begin
            @(negedge clk);
            addr = i;
            @(negedge clk);
            @(posedge clk);
            case(i)
                0: begin
                    if (rd_data === 32'hDEADBEEF) begin
                        $display("[PASS] HEX[%0d]=0x%h", i, rd_data);
                    end else begin
                        $display("[ERROR] HEX[%0d] expected=0xDEADBEEF, got=0x%h", i, rd_data);
                        errors = errors + 1;
                    end
                end
                1: begin
                    if (rd_data === 32'hCAFEBABE) begin
                        $display("[PASS] HEX[%0d]=0x%h", i, rd_data);
                    end else begin
                        $display("[ERROR] HEX[%0d] expected=0xCAFEBABE, got=0x%h", i, rd_data);
                        errors = errors + 1;
                    end
                end
                2: begin
                    if (rd_data === 32'h12345678) begin
                        $display("[PASS] HEX[%0d]=0x%h", i, rd_data);
                    end else begin
                        $display("[ERROR] HEX[%0d] expected=0x12345678, got=0x%h", i, rd_data);
                        errors = errors + 1;
                    end
                end
                3: begin
                    if (rd_data === 32'hABCDEF00) begin
                        $display("[PASS] HEX[%0d]=0x%h", i, rd_data);
                    end else begin
                        $display("[ERROR] HEX[%0d] expected=0xABCDEF00, got=0x%h", i, rd_data);
                        errors = errors + 1;
                    end
                end
                4: begin
                    if (rd_data === 32'hFEEDFACE) begin
                        $display("[PASS] HEX[%0d]=0x%h", i, rd_data);
                    end else begin
                        $display("[ERROR] HEX[%0d] expected=0xFEEDFACE, got=0x%h", i, rd_data);
                        errors = errors + 1;
                    end
                end
                5: begin
                    if (rd_data === 32'h11111111) begin
                        $display("[PASS] HEX[%0d]=0x%h", i, rd_data);
                    end else begin
                        $display("[ERROR] HEX[%0d] expected=0x11111111, got=0x%h", i, rd_data);
                        errors = errors + 1;
                    end
                end
                6: begin
                    if (rd_data === 32'h22222222) begin
                        $display("[PASS] HEX[%0d]=0x%h", i, rd_data);
                    end else begin
                        $display("[ERROR] HEX[%0d] expected=0x22222222, got=0x%h", i, rd_data);
                        errors = errors + 1;
                    end
                end
                7: begin
                    if (rd_data === 32'h33333333) begin
                        $display("[PASS] HEX[%0d]=0x%h", i, rd_data);
                    end else begin
                        $display("[ERROR] HEX[%0d] expected=0x33333333, got=0x%h", i, rd_data);
                        errors = errors + 1;
                    end
                end
                8: begin
                    if (rd_data === 32'hFFFFFFFF) begin
                        $display("[PASS] HEX[%0d]=0x%h", i, rd_data);
                    end else begin
                        $display("[ERROR] HEX[%0d] expected=0xFFFFFFFF, got=0x%h", i, rd_data);
                        errors = errors + 1;
                    end
                end
                9: begin
                    if (rd_data === 32'h00000000) begin
                        $display("[PASS] HEX[%0d]=0x%h", i, rd_data);
                    end else begin
                        $display("[ERROR] HEX[%0d] expected=0x00000000, got=0x%h", i, rd_data);
                        errors = errors + 1;
                    end
                end
            endcase
        end

        $display("\n=== Phase 1: Write and Read Test ===");
        
        // Write test
        @(negedge clk);
        addr = 100;
        wr_data = 32'hDEADBEEF;
        wr_bit_en = 32'hFFFFFFFF;
        wr_en = 1;
        ref_mem[100] = 32'hDEADBEEF;
        
        @(negedge clk);
        wr_en = 0;
        
        @(negedge clk);
        // Read test
        addr = 100;
        
        @(posedge clk);
        if (rd_data === 32'hDEADBEEF) begin
            $display("[PASS] Write/Read: addr=100, data=0x%h", rd_data);
        end else begin
            $display("[ERROR] Write/Read: addr=100, expected=0xDEADBEEF, got=0x%h", rd_data);
            errors = errors + 1;
        end

        $display("\n=== Phase 2: Mask Write Test ===");
        
        // Initialize addr 200
        @(negedge clk);
        addr = 200;
        wr_data = 32'hFFFFFFFF;
        wr_bit_en = 32'hFFFFFFFF;
        wr_en = 1;
        ref_mem[200] = 32'hFFFFFFFF;
        
        @(negedge clk);
        wr_en = 0;
        
        @(negedge clk);
        // Mask write - low byte only
        addr = 200;
        wr_data = 32'h12345678;
        wr_bit_en = 32'h000000FF;
        wr_en = 1;
        ref_mem[200] = (32'hFFFFFFFF & ~32'h000000FF) | (32'h12345678 & 32'h000000FF);
        
        @(negedge clk);
        wr_en = 0;
        
        @(negedge clk);
        addr = 200;
        
        @(posedge clk);
        if (rd_data === 32'hFFFFFF78) begin
            $display("[PASS] Mask write (low byte): addr=200, data=0x%h", rd_data);
        end else begin
            $display("[ERROR] Mask write (low byte): addr=200, expected=0xFFFFFF78, got=0x%h", rd_data);
            errors = errors + 1;
        end

        // Mask write - high word
        @(negedge clk);
        addr = 200;
        wr_data = 32'hAABBCCDD;
        wr_bit_en = 32'hFFFF0000;
        wr_en = 1;
        ref_mem[200] = (ref_mem[200] & ~32'hFFFF0000) | (32'hAABBCCDD & 32'hFFFF0000);
        
        @(negedge clk);
        wr_en = 0;
        
        @(negedge clk);
        addr = 200;
        
        @(posedge clk);
        if (rd_data === 32'hAABBFF78) begin
            $display("[PASS] Mask write (high word): addr=200, data=0x%h", rd_data);
        end else begin
            $display("[ERROR] Mask write (high word): addr=200, expected=0xAABBFF78, got=0x%h", rd_data);
            errors = errors + 1;
        end

        $display("\n=== Phase 3: Multiple Read/Write ===");
        
        for (int i = 50; i < 55; i = i + 1) begin
            @(negedge clk);
            addr = i;
            wr_data = {8'hAA, i[7:0], 8'hBB, i[7:0]};
            wr_bit_en = 32'hFFFFFFFF;
            wr_en = 1;
            ref_mem[i] = wr_data;
            @(negedge clk);
            wr_en = 0;
            @(negedge clk);
        end

        for (int i = 50; i < 55; i = i + 1) begin
            @(negedge clk);
            addr = i;
            @(negedge clk);
            @(posedge clk);
            if (rd_data === ref_mem[i]) begin
                $display("[PASS] Multi read addr=%0d, data=0x%h", i, rd_data);
            end else begin
                $display("[ERROR] Multi read addr=%0d, expected=0x%h, got=0x%h", i, ref_mem[i], rd_data);
                errors = errors + 1;
            end
        end

        repeat (2) @(posedge clk);
        if (errors == 0) begin
            $display("\n========== All Tests PASSED! ==========");
        end else begin
            $display("\n========== %0d Errors Found ==========", errors);
        end
        
        $finish;
    end
endmodule
