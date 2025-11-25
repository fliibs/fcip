

`ifndef _PREFIX_
    `define _PREFIX_(x) x
`endif

module `_PREFIX_({{module_name}}) #(
    parameter integer unsigned CTRL_BUS_IN_WIDTH     = 16    ,
    parameter integer unsigned CTRL_BUS_OUT_WIDTH    = 16
)(
    input  logic {{paddings.logic}}             clk,
    input  logic {{paddings.logic}}             en,
    input  logic {{addr_range}}{{paddings.addr}}              addr,
    output logic {{data_range}}{{paddings.data}}              rd_data,
    input  logic {{data_range}}{{paddings.data}}              wr_data,
    input  logic {{data_range}}{{paddings.data}}              wr_bit_en,
    input  logic {{paddings.logic}}             wr_en,

    // Control Signal
    input  logic [CTRL_BUS_IN_WIDTH  -1:0]      ctrl_bus_in    ,
    output logic [CTRL_BUS_OUT_WIDTH -1:0]      ctrl_bus_out
);

    localparam integer unsigned ADDR_WIDTH = {{addr_width}}   ;
    localparam integer unsigned DATA_WIDTH = {{sram_width}}   ;

    `ifdef USE_CUST_MEM
        // Users can instantiate their own memory here and define the macro above to enable it.
    `else
        `ifdef {{type_upper}}_INST
            `{{type_upper}}_INST
        `else
            fcip_spram_model #(
                .ARGPARSE_KEY({{argparse_key}}),
                .ALLOW_NO_HEX(1),
                .ADDR_WIDTH(ADDR_WIDTH),
                .DATA_WIDTH(DATA_WIDTH)
            ) u_fcip_spram_model (
                .clk(clk),
                .en(en),
                .addr(addr),
                .rd_data(rd_data),
                .wr_data(wr_data),
                .wr_bit_en(wr_bit_en),
                .wr_en(wr_en)
            );

        `endif
    `endif

endmodule
