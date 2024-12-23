module cmn_real_mux_onehot #(
    parameter WIDTH     =4,
    parameter PLD_WIDTH =32
)(
    input  [WIDTH-1:0]       select_onehot,
    input  [PLD_WIDTH-1:0]   v_pld [WIDTH-1:0],
    output [PLD_WIDTH-1:0]   select_pld
);

logic [WIDTH-1:0]       v_pld_rev         [PLD_WIDTH-1:0];
logic [WIDTH-1:0]       v_pld_rev_select  [PLD_WIDTH-1:0]; 
logic [PLD_WIDTH-1:0]   pld_rev_select;

genvar i,j;
generate
    for(i=0;i<WIDTH;i=i+1) begin: row
        for(j=0;j<PLD_WIDTH;j=j+1) begin: col 
            assign v_pld_rev[j][i] = v_pld[i][j];
        end 
    end
endgenerate

genvar k;
generate
    for(k=0;k<PLD_WIDTH;k=k+1) begin: PLD_WIDTH_ 
        assign v_pld_rev_select[k] = v_pld_rev[k] & select_onehot;
    end
endgenerate

genvar l;
generate
    for(l=0;l<PLD_WIDTH;l=l+1) begin: select_
        assign pld_rev_select[l] = |v_pld_rev_select[l];
    end 
endgenerate

assign select_pld = pld_rev_select;


endmodule 