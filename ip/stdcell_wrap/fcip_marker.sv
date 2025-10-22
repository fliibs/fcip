
// Marker with a buffer cell
module fcip_marker #(
    parameter integer unsigned DATA_WIDTH = 1,
    parameter integer unsigned VT_TYPE    = "LVT" // 0: LVT, 1: SVT, 2: ULVT, 7: LVTLL, 8: ULVTLL
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
            if(VT_TYPE == "SVT")begin:u_marker_SVT_H280
                //todo SIZE_ONLY(.I(I), .Z(Z));
            end
            else if(VT_TYPE == "LVT")begin:u_marker_LVT_H280
                //todo SIZE_ONLY(.I(I), .Z(Z));
            end
            else if(VT_TYPE == "ULVT")begin:u_marker_ULVT_H280
                //todo SIZE_ONLY(.I(I), .Z(Z));
            end
            else if(VT_TYPE == "LVTLL")begin:u_marker_LVTLL_H280
                //todo SIZE_ONLY(.I(I), .Z(Z));
            end
            else if(VT_TYPE == "ULVTLL")begin:u_marker_ULVTLL_H280
                //todo SIZE_ONLY(.I(I), .Z(Z));
            end
            else begin:u_marker_LVT_H280
                BUFFKBD5BWP280H6P57CNODLVT SIZE_ONLY(.I(I[i]), .Z(Z[i]));
            end
        end
        endgenerate
    `else
        generate for(genvar i=0;i<DATA_WIDTH;i++)begin
            if(VT_TYPE == "SVT")begin:u_marker_SVT_H210
                //todo SIZE_ONLY(.I(I), .Z(Z));
            end
            else if(VT_TYPE == "LVT")begin:u_marker_LVT_H210
                //todo SIZE_ONLY(.I(I), .Z(Z));
            end
            else if(VT_TYPE == "ULVT")begin:u_marker_ULVT_H210
                //todo SIZE_ONLY(.I(I), .Z(Z));
            end
            else if(VT_TYPE == "LVTLL")begin:u_marker_LVTLL_H210
                //todo SIZE_ONLY(.I(I), .Z(Z));
            end
            else if(VT_TYPE == "ULVTLL")begin:u_marker_ULVTLL_H210
                //todo SIZE_ONLY(.I(I), .Z(Z));
            end
            else begin:u_marker_ULVT_H210
                BUFFMZD4BWP210H6P51CNODLVT SIZE_ONLY (.I(I[i]),.Z(Z[i]));
            end 
        end
        endgenerate
    `endif
`endif

endmodule
