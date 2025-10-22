
// Marker with a buffer cell
module fcip_clk_marker #(
    parameter string VT_TYPE = "LVT" // LVT, SVT, ULVT, LVTLL,  ULVTLL
)(
    input   logic  I,
    output  logic  Z
);

`ifndef SYNTHESIS
        assign Z = I;
`else 
    `ifdef FPGA_SIM
        assign Z = I;
    `elsif FCIP_STMC_N4A_H280
        generate begin
            if(VT_TYPE == "SVT")begin:u_clk_marker_SVT_H280
                //todo SIZE_ONLY(.I(I), .Z(Z));
            end
            else if(VT_TYPE == "LVT")begin:u_clk_marker_LVT_H280
                //todo SIZE_ONLY(.I(I), .Z(Z));
            end
            else if(VT_TYPE == "ULVT")begin:u_clk_marker_ULVT_H280
                //todo SIZE_ONLY(.I(I), .Z(Z));
            end
            else if(VT_TYPE == "LVTLL")begin:u_clk_marker_LVTLL_H280
                //todo SIZE_ONLY(.I(I), .Z(Z));
            end
            else if(VT_TYPE == "ULVTLL")begin:u_clk_marker_ULVTLL_H280
                //todo SIZE_ONLY(.I(I), .Z(Z));
            end
            else begin:u_clk_marker_LVT_H280
                CKBMZD4BWP210H6P51CNODLVT SIZE_ONLY(.I(I[i]), .Z(Z[i]));
            end
        end
        endgenerate
    `else
        generate begin
            if(VT_TYPE == "SVT")begin:u_clk_marker_SVT_H210
                //todo SIZE_ONLY(.I(I), .Z(Z));
            end
            else if(VT_TYPE == "LVT")begin:u_clk_marker_LVT_H210
                //todo SIZE_ONLY(.I(I), .Z(Z));
            end
            else if(VT_TYPE == "ULVT")begin:u_clk_marker_ULVT_H210
                //todo SIZE_ONLY(.I(I), .Z(Z));
            end
            else if(VT_TYPE == "LVTLL")begin:u_clk_marker_LVTLL_H210
                //todo SIZE_ONLY(.I(I), .Z(Z));
            end
            else if(VT_TYPE == "ULVTLL")begin:u_clk_marker_ULVTLL_H210
                //todo SIZE_ONLY(.I(I), .Z(Z));
            end
            else begin:u_clk_marker_LVT_H210
                CKBMZD4BWP210H6P51CNODLVT SIZE_ONLY (.I(I[i]),.Z(Z[i]));
            end 
        end
        endgenerate
    `endif
`endif

endmodule
