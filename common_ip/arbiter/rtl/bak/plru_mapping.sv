module plru_mapping #(
    parameter WIDTH=4
)(
    input  [WIDTH-2:0] v_grant,
    output [WIDTH-1:0] matrix [WIDTH-1:0]
);

genvar i,j,k,l;

generate
    for(l=0;l<$clog2(WIDTH);l=l+1) begin: level
        for(k=0;k<2**($clog2(WIDTH)-1-l);k=k+1) begin: node_
            for(i=0;i<2**l;i=i+1) begin: row
                for(j=0;j<2**l;j=j+1) begin: colunm
                        assign matrix[i+k*2**(l+1)][j+2**l+k*2**(l+1)]=v_grant[2**($clog2(WIDTH)-1-l)+k-1];
                end 
            end 
        end
    end

endgenerate

generate
    for(i=0;i<WIDTH;i=i+1) begin: row_ 
        for(j=0;j<WIDTH;j=j+1) begin: column_ 
            if(i>j) begin 
                assign matrix[i][j] = ~matrix[j][i];
            end else if(i==j) begin 
                assign matrix[i][j] = 1'b0;
            end 
        end 
    end 
endgenerate

endmodule