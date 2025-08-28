module fcip_sync_cell #(
    parameter integer unsigned          DATA_WIDTH  = 1,
    parameter integer unsigned          SYN_STAGE   = 2, // must upper than 1
    parameter integer unsigned          VT_TYPE     = 0, // 0: LVT, 1: SVT, 2: ULVT, 7: LVTLL, 8: ULVTLL
    parameter logic [DATA_WIDTH-1:0]    RST_VALUE   = {DATA_WIDTH{1'b0}} // 0: sync_arst, 1: sync_aset
) (
    input  logic                     clk         ,
    input  logic                     rst_n       ,
    input  logic [DATA_WIDTH-1  :0]  d           ,
    output logic [DATA_WIDTH-1  :0]  q
);
    
    generate
        for(genvar i = 0; i < DATA_WIDTH; i=i+1) begin : gen_sync_cell
            if (RST_VALUE[i]==0) begin
                `ifdef FCIP_SYNC_CELL_ARST_MODULE_NAME
                    `FCIP_SYNC_CELL_ARST_MODULE_NAME #(
                        .VT_TYPE(VT_TYPE            ),
                        .SYN_NUM(SYN_STAGE          )
                    ) u_sync_arst (
                        .D      (d[i]               ),
                        .SI     (1'b0               ),
                        .SE     (1'b0               ),
                        .CP     (clk                ),
                        .CDN    (rst_n              ),
                        .Q      (q[i]               )
                    );
                `else
                    fcip_sync_arst #(
                        .VT_TYPE(VT_TYPE            ),
                        .SYN_NUM(SYN_STAGE          )
                    ) u_sync_arst (
                        .D      (d[i]               ),
                        .SI     (1'b0               ),
                        .SE     (1'b0               ),
                        .CP     (clk                ),
                        .CDN    (rst_n              ),
                        .Q      (q[i]               )
                    );
                `endif
            end else begin
                `ifdef FCIP_SYNC_CELL_ASET_MODULE_NAME
                    `FCIP_SYNC_CELL_ASET_MODULE_NAME #(
                        .VT_TYPE(VT_TYPE            ),
                        .SYN_NUM(SYN_STAGE          )
                    ) u_sync_aset (
                        .D      (d[i]               ),
                        .SI     (1'b0               ),
                        .SE     (1'b0               ),
                        .CP     (clk                ),
                        .SDN    (rst_n              ),
                        .Q      (q[i]               )
                    );
                `else
                    fcip_sync_aset #(
                        .VT_TYPE(VT_TYPE            ),
                        .SYN_NUM(SYN_STAGE          )
                    ) u_sync_aset (
                        .D      (d[i]               ),
                        .SI     (1'b0               ),
                        .SE     (1'b0               ),
                        .CP     (clk                ),
                        .SDN    (rst_n              ),
                        .Q      (q[i]               )
                    );
                `endif
            end 
        end
    endgenerate

endmodule