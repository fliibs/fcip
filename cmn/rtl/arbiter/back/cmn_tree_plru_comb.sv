module cmn_tree_plru_comb #(
    parameter WIDTH = 4,
    parameter DEPTH = $clog2(WIDTH)
)(
    input                     alloc_en,
    input        [WIDTH-2:0]  node,
    input        [WIDTH-1:0]  v_alloc,
    output logic [WIDTH-2:0]  update_node,
    output logic [WIDTH-1:0]  vv_matrix [WIDTH-1:0]
);

// update node
for(genvar i = 0; i < DEPTH; i=i+1) begin: level_wr
    for(genvar j = 0;j < 2**i;j=j+1) begin: offset_wr
        if(i==DEPTH-1) begin
            assign update_node[2**i+j-1] = alloc_en ? (node[2**i+j-1]||v_alloc[2*j])&&~v_alloc[2*j+1] : node[2**i+j-1];
        end
        else begin
            assign update_node[2**i+j-1] = alloc_en ? (node[2**i+j-1]||(|v_alloc[j*2**(DEPTH-i)+2**(DEPTH-i-1)-1:j*2**(DEPTH-i)]))&&~(|v_alloc[(j+1)*2**(DEPTH-i)-1:j*2**(DEPTH-i)+2**(DEPTH-i-1)]) : node[2**i+j-1];
        end
    end
end

// convert node to vv_matrix
for(genvar l = 0; l < DEPTH; l=l+1) begin: level
    for(genvar k = 0; k < 2**(DEPTH-1-l); k=k+1) begin: offset
        for(genvar m = 0; m < 2**l; m=m+1) begin: row
            for(genvar n = 0; n < 2**l; n=n+1) begin: colunm
                assign vv_matrix[m+k*2**(l+1)][n+2**l+k*2**(l+1)]=node[2**(DEPTH-1-l)+k-1];
            end
        end
    end
end

for(genvar i = 0; i < WIDTH; i=i+1) begin: row_
    for(genvar j = 0; j < WIDTH; j=j+1) begin: column_
        if(i>j) begin
            assign vv_matrix[i][j] = ~vv_matrix[j][i];
        end
        else if(i==j) begin
            assign vv_matrix[i][j] = 1'b0;
        end
    end
end


endmodule
