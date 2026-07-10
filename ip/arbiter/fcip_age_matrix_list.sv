module fcip_age_matrix_list #(
    parameter WIDTH = 4,
    parameter LIST_DEPTH = 2
)(
    input                     clk,
    input                     rst_n,
    input   [LIST_DEPTH-1:0]  v_alloc_en,
    input        [WIDTH-1:0]  v_alloc   [LIST_DEPTH-1:0],
    output logic [WIDTH-1:0]  vv_matrix [WIDTH-1:0]
);

logic [LIST_DEPTH-1:0][WIDTH-1:0][WIDTH-1:0] vv_matrix_tmp ;

genvar i,j,k;

generate
    for(k=0;k<LIST_DEPTH;k=k+1) begin: list
        for(i=0;i<WIDTH;i=i+1) begin: row
            for(j=0;j<WIDTH;j=j+1) begin: column 
                if(i==j) begin 
                    assign vv_matrix_tmp[k][i][j]  = 1'b0;
                end else if(i<j) begin 
                    if(k==0)begin
                        assign vv_matrix_tmp[k][i][j]  = (v_alloc[k][j] && v_alloc_en[k]) ? 1'b0 : ((v_alloc[k][i] && v_alloc_en[k]) ? 1'b1 : vv_matrix[i][j]);
                    end
                    else begin
                        assign vv_matrix_tmp[k][i][j]  = (v_alloc[k][j] && v_alloc_en[k]) ? 1'b0 : ((v_alloc[k][i] && v_alloc_en[k]) ? 1'b1 : vv_matrix_tmp[k-1][i][j]);
                    end
                end else begin 
                    assign vv_matrix_tmp[k][i][j]  = ~vv_matrix_tmp[k][j][i];
                end 
            end
        end 
    end
endgenerate


generate
    for(k=0;k<WIDTH;k=k+1) begin: row_ 
        for(j=0;j<WIDTH;j=j+1) begin: column 
            always @(posedge clk or negedge rst_n) begin 
                if(~rst_n) vv_matrix[k][j] <= 1'b0;
                else vv_matrix[k][j] <= vv_matrix_tmp[LIST_DEPTH-1][k][j];
            end 
        end
    end 

endgenerate


endmodule