module cmn_arb_vr_matrix #(
    parameter WIDTH=4
)(
    input   [WIDTH-1:0]         vv_matrix [WIDTH-1:0],

    input   [WIDTH-1:0]         v_vld_s,
    output  [WIDTH-1:0]         v_rdy_s,
    
    output                      vld_m,
    input                       rdy_m
);


logic [WIDTH-1:0]       select_onehot;

genvar i;
generate
    for(i=0;i<WIDTH;i=i+1) begin: select_onehot_
        assign select_onehot[i] =  (~|(v_vld_s&vv_matrix[i])) && (rdy_m && v_vld_s[i]); 
    end 
endgenerate


assign vld_m = |v_vld_s;
assign v_rdy_s = select_onehot;

endmodule