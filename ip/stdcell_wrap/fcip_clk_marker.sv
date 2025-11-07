
// Marker with a buffer cell
module fcip_clk_marker #(
    parameter integer unsigned VT_TYPE = 1 // 0: SVT, 1: LVT, 2: ULVT, 3: ELVT, 4: LVTLL, 5: ULVTLL
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
            if(VT_TYPE == 0)begin:u_clk_marker_SVT_H280
                CKBKBD4BWP280H6P57CNODSVT SIZE_ONLY(.I(I), .Z(Z));
            end
            else if(VT_TYPE == 1)begin:u_clk_marker_LVT_H280
                CKBKBD4BWP280H6P57CNODLVT SIZE_ONLY(.I(I), .Z(Z));
            end
            else if(VT_TYPE == 2)begin:u_clk_marker_ULVT_H280
                CKBKBD4BWP280H6P57CNODULVT SIZE_ONLY(.I(I), .Z(Z));
            end
            else if(VT_TYPE == 3)begin:u_clk_marker_ELVT_H280
                CKBKBD4BWP280H6P57CNODELVT SIZE_ONLY(.I(I), .Z(Z));
            end
            else if(VT_TYPE == 4)begin:u_clk_marker_LVTLL_H280
                CKBKBD4BWP280H6P57CNODLVTLL SIZE_ONLY(.I(I), .Z(Z));
            end
            else if(VT_TYPE == 5)begin:u_clk_marker_ULVTLL_H280
                CKBKBD4BWP280H6P57CNODULVTLL SIZE_ONLY(.I(I), .Z(Z));
            end
        end
        endgenerate
    `else
        generate begin
            if(VT_TYPE == 0)begin:u_clk_marker_SVT_H210
                CKBMZD4BWP210H6P51CNODSVT SIZE_ONLY (.I(I),.Z(Z));
            end
            else if(VT_TYPE == 1)begin:u_clk_marker_LVT_H210
                CKBMZD4BWP210H6P51CNODLVT SIZE_ONLY (.I(I),.Z(Z));
            end
            else if(VT_TYPE == 2)begin:u_clk_marker_ULVT_H210
                CKBMZD4BWP210H6P51CNODULVT SIZE_ONLY (.I(I),.Z(Z));
            end
            else if(VT_TYPE == 3)begin:u_clk_marker_ELVT_H210
                CKBMZD4BWP210H6P51CNODELVT SIZE_ONLY (.I(I),.Z(Z));
            end
            else if(VT_TYPE == 4)begin:u_clk_marker_LVTLL_H210
                CKBMZD4BWP210H6P51CNODLVTLL SIZE_ONLY (.I(I),.Z(Z));
            end
            else if(VT_TYPE == 5)begin:u_clk_marker_ULVTLL_H210
                CKBMZD4BWP210H6P51CNODULVTLL SIZE_ONLY (.I(I),.Z(Z));
            end 
        end
        endgenerate
    `endif
`endif

endmodule
