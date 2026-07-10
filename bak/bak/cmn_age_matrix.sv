module cmn_age_matrix #(
    parameter WIDTH = 4
)(
    input                     clk,
    input                     rst_n,
    input                     alloc_en,
    input        [WIDTH-1:0]  v_alloc,
    output logic [WIDTH-1:0]  vv_matrix [WIDTH-1:0]
);

logic [WIDTH-1:0] vv_matrix_tmp [WIDTH-1:0];

genvar i,j;

generate
    for(i=0;i<WIDTH;i=i+1) begin: row
        for(j=0;j<WIDTH;j=j+1) begin: column 
            if(i==j) begin 
                assign vv_matrix_tmp[i][j]  = 1'b0;
            end else if(i<j) begin 
                assign vv_matrix_tmp[i][j]  = (v_alloc[j] && alloc_en) ? 1'b0 : ((v_alloc[i] && alloc_en) ? 1'b1 : vv_matrix[i][j]);
            end else begin 
                assign vv_matrix_tmp[i][j]  = ~vv_matrix_tmp[j][i];
            end 
        end
    end 
endgenerate

genvar k;

generate
    for(k=0;k<WIDTH;k=k+1) begin: row_ 
        always @(posedge clk or negedge rst_n) begin 
            if(~rst_n) vv_matrix[k] <= {WIDTH{1'b0}};
            else vv_matrix[k] <= vv_matrix_tmp[k];
        end 
    end 

endgenerate


endmodule