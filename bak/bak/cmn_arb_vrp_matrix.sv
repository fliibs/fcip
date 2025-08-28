module cmn_arb_vrp_matrix #(
    parameter WIDTH=4,
    parameter PLD_WIDTH=32
)(
    input                       clk,
    input                       rst_n,

    input   [WIDTH-1:0]         vv_matrix [WIDTH-1:0],

    input   [WIDTH-1:0]         v_vld_s,
    output  [WIDTH-1:0]         v_rdy_s,
    input   [PLD_WIDTH-1:0]     v_pld_s   [WIDTH-1:0],
    
    output                      vld_m,
    input                       rdy_m,
    output  [PLD_WIDTH-1:0]     pld_m
);


logic [WIDTH-1:0]       select_onehot;
logic [PLD_WIDTH-1:0]   select_pld;

genvar i;
generate
    for(i=0;i<WIDTH;i=i+1) begin: select_onehot_
        assign select_onehot[i] =  (~|(v_vld_s&vv_matrix[i])) && (rdy_m && v_vld_s[i]); 
    end 
endgenerate


cmn_real_mux_onehot #(
    .WIDTH(WIDTH),
    .PLD_WIDTH(PLD_WIDTH)
) u_mux (
    .select_onehot  (select_onehot),
    .v_pld          (v_pld_s),
    .select_pld     (select_pld)
);


assign vld_m = |v_vld_s;
assign pld_m = select_pld;
assign v_rdy_s = select_onehot;

endmodule