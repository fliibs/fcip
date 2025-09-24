module fcip_data_pipe #(
    parameter integer unsigned DATA_WIDTH = 1,
    parameter integer unsigned PIPE_STAGE = 2,
    parameter integer unsigned VT_TYPE    = 0 // 0: LVT, 1: SVT, 2: ULVT, 7: LVTLL, 8: ULVTLL
)(
    input  logic         clk,
    input  logic         rst_n,

    input  logic [DATA_WIDTH-1:0] d,
    output logic [DATA_WIDTH-1:0] q
);

generate
    if(PIPE_STAGE >=2 )begin
        for(genvar i=0;i<DATA_WIDTH;i++)begin
            fcip_sync_arst #(
                .VT_TYPE(VT_TYPE            ),
                .SYN_NUM(PIPE_STAGE         )
            ) u_sync_arst (
                .D      (d[i]               ),
                .SI     (1'b0               ),
                .SE     (1'b0               ),
                .CP     (clk                ),
                .CDN    (rst_n              ),
                .Q      (q[i]               )
            );
        end
    end else begin
        
        always_ff @( posedge clk or negedge rst_n ) begin
            if(~rst_n)
                q <= 'b0;
            else 
                q <= d;
        end
        
    end
endgenerate

endmodule