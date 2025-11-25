// Simple DPRAM test - dual-port RAM with independent read/write
`timescale 1ns/1ps

module fcip_dpram_simple_tb;
    parameter ADDR_WIDTH = 10;
    parameter DATA_WIDTH = 32;

    reg clk;
    reg rd_en;
    reg [ADDR_WIDTH-1:0] rd_addr;
    wire [DATA_WIDTH-1:0] rd_data;
    
    reg wr_en;
    reg [DATA_WIDTH-1:0] wr_bit_en;
    reg [ADDR_WIDTH-1:0] wr_addr;
    reg [DATA_WIDTH-1:0] wr_data;
    
    integer errors = 0;

    // DUT - with ARGPARSE_KEY parameter for hex loading
    fcip_dpram_model #(
        .ARGPARSE_KEY("DPRAM_HEX"),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ALLOW_NO_HEX(1)
    ) dut (
        .clk(clk),
        .rd_en(rd_en),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .wr_en(wr_en),
        .wr_bit_en(wr_bit_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data)
    );

    initial begin
        rd_en = 1;
        wr_en = 0;
        rd_addr = 0;
        wr_addr = 0;
        wr_data = 0;
        wr_bit_en = 0;

        repeat (2) @(posedge clk);

        $display("\n=== Phase 0: HEX File Load Test ===");
        
        // Expected hex file values at addresses 0-9
        // @0: 11111111, 22222222, 33333333, 44444444, 55555555, 66666666, 77777777, 88888888, 99999999, AAAAAAAA
        
        for (int i = 0; i < 10; i = i + 1) begin
            @(negedge clk);
            rd_addr = i;
            @(negedge clk);
            @(posedge clk);
            case(i)
                0: if (rd_data === 32'h11111111) begin
                    $display("[PASS] HEX[%0d]=0x%h", i, rd_data);
                end else begin
                    $display("[ERROR] HEX[%0d] expected=0x11111111, got=0x%h", i, rd_data);
                    errors = errors + 1;
                end
                1: if (rd_data === 32'h22222222) begin
                    $display("[PASS] HEX[%0d]=0x%h", i, rd_data);
                end else begin
                    $display("[ERROR] HEX[%0d] expected=0x22222222, got=0x%h", i, rd_data);
                    errors = errors + 1;
                end
                2: if (rd_data === 32'h33333333) begin
                    $display("[PASS] HEX[%0d]=0x%h", i, rd_data);
                end else begin
                    $display("[ERROR] HEX[%0d] expected=0x33333333, got=0x%h", i, rd_data);
                    errors = errors + 1;
                end
                3: if (rd_data === 32'h44444444) begin
                    $display("[PASS] HEX[%0d]=0x%h", i, rd_data);
                end else begin
                    $display("[ERROR] HEX[%0d] expected=0x44444444, got=0x%h", i, rd_data);
                    errors = errors + 1;
                end
                4: if (rd_data === 32'h55555555) begin
                    $display("[PASS] HEX[%0d]=0x%h", i, rd_data);
                end else begin
                    $display("[ERROR] HEX[%0d] expected=0x55555555, got=0x%h", i, rd_data);
                    errors = errors + 1;
                end
                5: if (rd_data === 32'h66666666) begin
                    $display("[PASS] HEX[%0d]=0x%h", i, rd_data);
                end else begin
                    $display("[ERROR] HEX[%0d] expected=0x66666666, got=0x%h", i, rd_data);
                    errors = errors + 1;
                end
                6: if (rd_data === 32'h77777777) begin
                    $display("[PASS] HEX[%0d]=0x%h", i, rd_data);
                end else begin
                    $display("[ERROR] HEX[%0d] expected=0x77777777, got=0x%h", i, rd_data);
                    errors = errors + 1;
                end
                7: if (rd_data === 32'h88888888) begin
                    $display("[PASS] HEX[%0d]=0x%h", i, rd_data);
                end else begin
                    $display("[ERROR] HEX[%0d] expected=0x88888888, got=0x%h", i, rd_data);
                    errors = errors + 1;
                end
                8: if (rd_data === 32'h99999999) begin
                    $display("[PASS] HEX[%0d]=0x%h", i, rd_data);
                end else begin
                    $display("[ERROR] HEX[%0d] expected=0x99999999, got=0x%h", i, rd_data);
                    errors = errors + 1;
                end
                9: if (rd_data === 32'hAAAAAAAA) begin
                    $display("[PASS] HEX[%0d]=0x%h", i, rd_data);
                end else begin
                    $display("[ERROR] HEX[%0d] expected=0xAAAAAAAA, got=0x%h", i, rd_data);
                    errors = errors + 1;
                end
            endcase
        end

        $display("\n=== Phase 1: Independent Read/Write Test ===");
        
        // While reading from addr 100, write to addr 200
        @(negedge clk);
        rd_addr = 100;
        wr_addr = 200;
        wr_data = 32'hFEDCBA98;
        wr_bit_en = 32'hFFFFFFFF;
        wr_en = 1;
        
        @(negedge clk);
        wr_en = 0;
        
        @(negedge clk);
        // Read from 200 after write
        rd_addr = 200;
        
        @(negedge clk);
        @(posedge clk);
        if (rd_data === 32'hFEDCBA98) begin
            $display("[PASS] Independent R/W: wr_addr=200, rd_addr=200, data=0x%h", rd_data);
        end else begin
            $display("[ERROR] Independent R/W: wr_addr=200, rd_addr=200, expected=0xFEDCBA98, got=0x%h", rd_data);
            errors = errors + 1;
        end

        $display("\n=== Phase 2: Mask Write Test ===");
        
        // Initialize addr 300
        @(negedge clk);
        wr_addr = 300;
        wr_data = 32'hFFFFFFFF;
        wr_bit_en = 32'hFFFFFFFF;
        wr_en = 1;
        
        @(negedge clk);
        wr_en = 0;
        
        @(negedge clk);
        // Mask write - low word only
        wr_addr = 300;
        wr_data = 32'hBEEFCAFE;
        wr_bit_en = 32'h0000FFFF;
        wr_en = 1;
        
        @(negedge clk);
        wr_en = 0;
        
        @(negedge clk);
        rd_addr = 300;
        
        @(negedge clk);
        @(posedge clk);
        if (rd_data === 32'hFFFFCAFE) begin
            $display("[PASS] Mask write (low word): addr=300, data=0x%h", rd_data);
        end else begin
            $display("[ERROR] Mask write (low word): addr=300, expected=0xFFFFCAFE, got=0x%h", rd_data);
            errors = errors + 1;
        end

        $display("\n=== Phase 3: Simultaneous Read/Write ===");
        
        // Write to one address while reading from another
        for (int i = 10; i < 15; i = i + 1) begin
            @(negedge clk);
            rd_addr = i - 1;      // Read from previous address
            wr_addr = i;          // Write to current address
            wr_data = {8'hCC, i[7:0], 8'hDD, i[7:0]};
            wr_bit_en = 32'hFFFFFFFF;
            wr_en = 1;
            @(negedge clk);
            wr_en = 0;
            @(negedge clk);
        end

        // Now read back all written addresses
        for (int i = 10; i < 15; i = i + 1) begin
            @(negedge clk);
            rd_addr = i;
            @(negedge clk);
            @(posedge clk);
            if (rd_data === {8'hCC, i[7:0], 8'hDD, i[7:0]}) begin
                $display("[PASS] Sim R/W read addr=%0d, data=0x%h", i, rd_data);
            end else begin
                $display("[ERROR] Sim R/W read addr=%0d, expected=0x%h, got=0x%h", i, {8'hCC, i[7:0], 8'hDD, i[7:0]}, rd_data);
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
