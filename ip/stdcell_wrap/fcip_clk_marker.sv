
// Marker with a buffer cell
module fcip_clk_marker #(
    parameter string VT_TYPE = "LVT" // LVT, SVT, ULVT, LVTLL,  ULVTLL
)(
    input   logic  I,
    output  logic  Z
);

    `ifdef ASIC_SIM
        assign Z = I;
    `elsif  FCIP_STMC_N4P_H280
        generate 
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
        endgenerate
    `else
        generate 
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
            else begin
                CKBMZD4BWP210H6P51CNODLVT SIZE_ONLY (.I(I),.Z(Z));
            end
        endgenerate
    `endif

endmodule
