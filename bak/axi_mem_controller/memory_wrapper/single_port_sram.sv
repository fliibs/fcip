module single_port_sram #(
    parameter AW = 32,
    parameter DW = 64,
    parameter DEPTH = 1024
) (
    input  logic              clk,
    input  logic              ce,
    input  logic              we,
    input  logic [AW-1:0]     addr,
    input  logic [DW-1:0]     din,
    output logic [DW-1:0]     dout
);
    
    logic [DW-1:0] mem[DEPTH-1:0];

    integer i;
    initial begin
        for (i=0; i<DEPTH; i=i+1) begin
            mem[i] = {DW{1'b0}};
        end
    end

    // read
    always @(posedge clk) begin
        if (ce && ~we) begin
            dout <= mem[addr];
        end else begin
            dout <= {DW{1'b0}};
        end
    end
    
    // write
    always @(posedge clk) begin
        if (ce && we) begin
            mem[addr] <= din;
        end
    end

endmodule