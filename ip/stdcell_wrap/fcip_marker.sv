
// Marker with a buffer cell
module fcip_marker #(
    parameter integer unsigned DATA_WIDTH = 1
)(
    input   logic [DATA_WIDTH-1:0] I      ,
    output  logic [DATA_WIDTH-1:0] Z
);

generate for(genvar i=0; i<DATA_WIDTH; i=i+1) begin : u_marker
    `ifdef ASIC_SIM
        assign Z[i] = I[i];
    `else 
        `ifdef FCIP_TSMC_N4P_H210
            BUFFMZD4BWP210H6P51CNODLVT SIZE_ONLY(.I(I[i]), .Z(Z[i]));
        `elsif FCIP_STMC_N4P_H280
            BUFFKBD5BWP280H6P57CNODLVT SIZE_ONLY(.I(I[i]), .Z(Z[i]));
        `elsif FCIP_TSMC_N4A_H210
            //todo SIZE_ONLY(.I(I[i]), .Z(Z[i]));
        `elsif FCIP_TSMC_N4A_H280
            //todo SIZE_ONLY(.I(I[i]), .Z(Z[i]));
        `elsif FCIP_TSMC_N5A_H210
            //todo SIZE_ONLY(.I(I[i]), .Z(Z[i]));
        `elsif FCIP_TSMC_N5A_H280
            //todo SIZE_ONLY(.I(I[i]), .Z(Z[i]));
        `elsif FCIP_TSMC_N12_6T
            //todo SIZE_ONLY(.I(I[i]), .Z(Z[i]));
        `else
            //BUFFMZD4BWP210H6P51CNODSVT SIZE_ONLY(.I(I[i]), .Z(Z[i]));
        `endif
    `endif
    end 
endgenerate

endmodule
