module memory_wrapper #(
    parameter ADDR_WIDTH      = 32,
    parameter DATA_WIDTH      = 64
) (
    input  logic                           clk,
    input  logic                           rstn,
    // memory in
    input  logic                           mi_ce,
    input  logic                           mi_we,
    input  logic [ADDR_WIDTH-1:0]          mi_addr,
    input  logic [DATA_WIDTH-1:0]          mi_data,
    // memory out
    output logic [DATA_WIDTH-1:0]          mo_data
);
    
    single_port_sram #( 
        .AW    ( ADDR_WIDTH ),
        .DW    ( DATA_WIDTH ),
        .DEPTH ( 1024       )
    ) u_single_port_sram(
        .clk  ( clk        ),  
        .ce   ( mi_ce      ),  
        .we   ( mi_we      ),  
        .addr ( mi_addr    ),   
        .din  ( mi_data    ), 
        .dout ( mo_data    )  
    );

endmodule