module plru_matrix #(
    parameter WIDTH = 4,
    parameter DEPTH = $clog2(WIDTH)
)(
    input                     clk,
    input                     rst_n,
    input                     alloc_en,
    input        [WIDTH-1:0]  v_alloc,
    output logic [WIDTH-1:0]  vv_matrix [WIDTH-1:0]
);

logic [WIDTH-2:0] v_matrix_tmp;

// genvar i,j;

// generate
//     for(i=0;i<DEPTH;i=i+1) begin: row
//         for(j=0;j<i**2;j=j+1) begin: column 
            

//         end 
//     end
// endgenerate

endmodule