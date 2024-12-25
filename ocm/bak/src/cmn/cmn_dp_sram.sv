module cmn_dp_sram#(
    parameter integer unsigned  DATA_WIDTH = 8,   
    parameter integer unsigned  ADDR_WIDTH = 8
)(
    input  logic                    clk         ,
    input  logic [DATA_WIDTH-1:0]   din         ,
    output logic [DATA_WIDTH-1:0]   dout        ,
    input  logic                    wren        ,
    input  logic [ADDR_WIDTH-1:0]   wraddr      ,  
    input  logic                    rden        ,
    input  logic [ADDR_WIDTH-1:0]   rdaddr                  
);
    logic [DATA_WIDTH-1:0] mem [(2**ADDR_WIDTH)-1:0];
    always_ff@(posedge clk) begin
        if(wren) mem[wraddr] <= din             ;
    end

always_ff@(posedge clk) begin
        if(rden) dout        <= mem[rdaddr]     ;    
    end
endmodule