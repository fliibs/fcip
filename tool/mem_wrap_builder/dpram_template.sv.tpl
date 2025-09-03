module `_PREFIX_({{module_name}}) #(
    parameter integer unsigned CTRL_BUS_IN_WIDTH     = 16,
    parameter integer unsigned CTRL_BUS_OUT_WIDTH    = 16
)(
    input  logic {{paddings.logic}}            clk,
    // Port A
    input  logic {{paddings.logic}}            wr_en,
    input  logic {{paddings.logic}}            wr_biten,
    input  logic {{addr_range}}{{paddings.addr}}             wr_addr,
    input  logic {{data_range}}{{paddings.data}}             wr_data,

    // Port B
    input  logic {{paddings.logic}}            rd_en,
    input  logic {{addr_range}}{{paddings.addr}}             rd_addr,
    output logic {{data_range}}{{paddings.data}}             rd_data,


    // Control Signal
    input  logic [CTRL_BUS_IN_WIDTH  -1:0]     ctrl_bus_in    ,
    output logic [CTRL_BUS_OUT_WIDTH -1:0]     ctrl_bus_out   
);

    localparam integer unsigned ADDR_WIDTH = {{addr_width}}   ;
    localparam integer unsigned DATA_WIDTH = {{sram_width}}   ;

    `ifdef USE_CUST_MEM
        // Users can instantiate their own memory here and define the macro above to enable it.
    `else
        `ifdef {{type_upper}}_INST
            `{{type_upper}}_INST
        `else
            fcip_dpram_model #(
                .ADDR_WIDTH(ADDR_WIDTH),
                .DATA_WIDTH(DATA_WIDTH)
            ) u_fcip_dpram_model (
                // Port A
                .clka           (clk        ),
                .ena            (wr_en      ),
                .addra          (wr_addr    ),
                .rd_dataa       (           ),
                .wr_dataa       (wr_data    ),
                .wr_ena         (wr_en      ),

                // Port B
                .clkb           (clk        ),
                .enb            (rd_en      ),
                .addrb          (rd_addr    ),
                .rd_datab       (rd_data    ),
                .wr_datab       ('b0        ),
                .wr_enb         (1'b0       )
            );
        `endif
    `endif

endmodule
