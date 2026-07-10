
// Marker with a buffer cell
module fcip_marker #(
    parameter integer unsigned DATA_WIDTH = 1,
    parameter integer unsigned VT_TYPE    = 1 // 0: SVT, 1: LVT, 2: ULVT, 3: ELVT, 4: LVTLL, 5: ULVTLL
)(
    input   logic [DATA_WIDTH-1:0] I      ,
    output  logic [DATA_WIDTH-1:0] Z
);

`ifndef SYNTHESIS
    generate for(genvar i=0;i<DATA_WIDTH;i++)begin: u_marker
        assign Z[i] = I[i];
    end
    endgenerate
`else 
    `ifdef FPGA_SIM
        generate for(genvar i=0;i<DATA_WIDTH;i++)begin: u_marker
            assign Z[i] = I[i];
        end
        endgenerate
    `elsif FCIP_STMC_N4A_H280
        generate for(genvar i=0;i<DATA_WIDTH;i++)begin
            if(VT_TYPE == 0)begin:u_marker_SVT_H280
                BUFFKBD5BWP280H6P57CNODSVT SIZE_ONLY(.I(I[i]), .Z(Z[i]));
            end
            else if(VT_TYPE == 1)begin:u_marker_LVT_H280
                BUFFKBD5BWP280H6P57CNODLVT SIZE_ONLY(.I(I[i]), .Z(Z[i]));
            end
            else if(VT_TYPE == 2)begin:u_marker_ULVT_H280
                BUFFKBD5BWP280H6P57CNODULVT SIZE_ONLY(.I(I[i]), .Z(Z[i]));
            end
            else if(VT_TYPE == 3)begin:u_marker_ELVT_H280
                BUFFKBD5BWP280H6P57CNODELVT SIZE_ONLY(.I(I[i]), .Z(Z[i]));
            end
            else if(VT_TYPE == 4)begin:u_marker_LVTLL_H280
                BUFFKBD5BWP280H6P57CNODLVTLL SIZE_ONLY(.I(I[i]), .Z(Z[i]));
            end
            else if(VT_TYPE == 5)begin:u_marker_ULVTLL_H280
                BUFFKBD5BWP280H6P57CNODULVTLL SIZE_ONLY(.I(I[i]), .Z(Z[i]));
            end
        end
        endgenerate
    `else
        generate for(genvar i=0;i<DATA_WIDTH;i++)begin
            if(VT_TYPE == 0)begin:u_marker_SVT_H210
                BUFFMZD4BWP210H6P51CNODSVT SIZE_ONLY (.I(I[i]),.Z(Z[i]));
            end
            else if(VT_TYPE == 1)begin:u_marker_LVT_H210
                BUFFMZD4BWP210H6P51CNODLVT SIZE_ONLY (.I(I[i]),.Z(Z[i]));
            end
            else if(VT_TYPE == 2)begin:u_marker_ULVT_H210
                BUFFMZD4BWP210H6P51CNODULVT SIZE_ONLY (.I(I[i]),.Z(Z[i]));
            end
            else if(VT_TYPE == 3)begin:u_marker_ELVT_H210
                BUFFMZD4BWP210H6P51CNODELVT SIZE_ONLY (.I(I[i]),.Z(Z[i]));
            end
            else if(VT_TYPE == 4)begin:u_marker_LVTLL_H210
                BUFFMZD4BWP210H6P51CNODLVTLL SIZE_ONLY (.I(I[i]),.Z(Z[i]));
            end
            else if(VT_TYPE == 5)begin:u_marker_ULVTLL_H210
                BUFFMZD4BWP210H6P51CNODULVTLL SIZE_ONLY (.I(I[i]),.Z(Z[i]));
            end 
        end
        endgenerate
    `endif
`endif

endmodule
