module cmn_plru_node #(
    parameter WIDTH = 4,
    parameter DEPTH = $clog2(WIDTH)
)(
    input                     clk,
    input                     rst_n,
    input                     alloc_en,
    input        [WIDTH-1:0]  v_alloc,
    output logic [WIDTH-1:0]  vv_matrix [WIDTH-1:0],
    input        [WIDTH-2:0]  node_i,
    output logic [WIDTH-2:0]  node_o
);


genvar i,j;
generate
    for(i=0;i<DEPTH;i=i+1) begin: level_
        for(j=0;j<2**i;j=j+1) begin: offset_
            if(i==DEPTH-1) begin
                always @(posedge clk or negedge rst_n) 
                    if(~rst_n)        node_o[2**i+j-1] <= 1'b0;
                    else if(alloc_en) node_o[2**i+j-1] <= (node_i[2**i+j-1]||v_alloc[2*j])&&~v_alloc[2*j+1];
            end else begin
                always @(posedge clk or negedge rst_n) 
                    if(~rst_n)        node_o[2**i+j-1] <= 1'b0;    
                    else if(alloc_en) node_o[2**i+j-1] <= (node_i[2**i+j-1]||(|v_alloc[j*2**(DEPTH-i)+2**(DEPTH-i-1)-1:j*2**(DEPTH-i)]))&&~(|v_alloc[(j+1)*2**(DEPTH-i)-1:j*2**(DEPTH-i)+2**(DEPTH-i-1)]);
            end
        end 
    end 
endgenerate

genvar k,l;

generate
    for(l=0;l<$clog2(WIDTH);l=l+1) begin: level
        for(k=0;k<2**($clog2(WIDTH)-1-l);k=k+1) begin: offset
            for(i=0;i<2**l;i=i+1) begin: row
                for(j=0;j<2**l;j=j+1) begin: colunm
                        assign vv_matrix[i+k*2**(l+1)][j+2**l+k*2**(l+1)]=node_i[2**($clog2(WIDTH)-1-l)+k-1];
                end 
            end 
        end
    end

endgenerate

generate
    for(i=0;i<WIDTH;i=i+1) begin: row_ 
        for(j=0;j<WIDTH;j=j+1) begin: column_ 
            if(i>j) begin 
                assign vv_matrix[i][j] = ~vv_matrix[j][i];
            end else if(i==j) begin 
                assign vv_matrix[i][j] = 1'b0;
            end 
        end 
    end 
endgenerate


endmodule