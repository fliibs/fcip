module plru_update #(
    parameter WIDTH = 4,
    parameter DEPTH = $clog2(WIDTH)
)(
    input                     clk,
    input                     rst_n,
    input                     alloc_en,
    input        [WIDTH-1:0]  v_alloc
);

logic [WIDTH-2:0] node;

genvar i,j;
generate
    for(i=0;i<DEPTH;i=i+1) begin: level_
        for(j=0;j<2**i;j=j+1) begin: offset_
            if(i==DEPTH-1) begin
                always @(posedge clk or negedge rst_n) 
                    if(~rst_n)        node <= 1'b0;
                    else if(alloc_en) node[2**i+j-1] <= (node[2**i+j-1]||v_alloc[2*j])&&~v_alloc[2*j+1];
            end else begin
                always @(posedge clk or negedge rst_n) 
                    if(~rst_n)        node <= 1'b0;    
                    else if(alloc_en) node[2**i+j-1] <= (node[2**i+j-1]||(|v_alloc[j*2**(DEPTH-i)+2**(DEPTH-i-1)-1:j*2**(DEPTH-i)]))&&~(|v_alloc[(j+1)*2**(DEPTH-i)-1:j*2**(DEPTH-i)+2**(DEPTH-i-1)]);
            end
        end 
    end 
endgenerate



endmodule