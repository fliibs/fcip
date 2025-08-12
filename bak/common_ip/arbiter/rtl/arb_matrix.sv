module arb_matrix #(
    parameter WIDTH=4
)(
    input   [WIDTH-1:0]   vv_matrix [WIDTH-1:0],
    input   [WIDTH-1:0]   v_vld,
    
    output  [WIDTH-1:0]   v_grant
);


logic [WIDTH-1:0] select_onehot;

genvar i;
generate
    for(i=0;i<WIDTH;i=i+1) begin: select_onehot_
        assign select_onehot[i] =  (~|(v_vld&vv_matrix[i])) && v_vld[i]; 
    end 
endgenerate

assign v_grant = select_onehot;

endmodule