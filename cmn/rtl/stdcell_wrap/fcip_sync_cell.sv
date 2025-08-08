

`define FCIP_SYNC_CELL_ARST_MODULE_NAME bydlib_cdc_demet_arst

module fcip_sync_cell #(
    parameter integer unsigned          DATA_WIDTH   = 1,
    parameter integer unsigned          SYNC_STAGES  = 2,
    parameter logic [DATA_WIDTH-1:0]    RESET_VALUE  = 'b0,
    parameter integer unsigned          VT_TYPE      = 2   
    // SVT:1 ULVT:2 LVT:0 ELVT:6 LVTLL:7 ULVTLL:8
)(
    input  logic                    clk     ,
    input  logic                    rst_n   ,
    input  logic [DATA_WIDTH-1:0]   din     ,
    output logic [DATA_WIDTH-1:0]   dout
);

    generate for(genvar i=0; i<DATA_WIDTH; i=i+1) begin : u_sync
        if(RESET_VALUE[i] == 1'b0) begin : u_sync_rst0
            `ifdef FCIP_SYNC_CELL_ARST_MODULE_NAME
                `FCIP_SYNC_CELL_ARST_MODULE_NAME #(
                    .VT_TYPE    (VT_TYPE        ),
                    .SYNC_NUM   (SYNC_STAGES    )
                ) sync_ff (
                    .D      (din[i]     ),
                    .CP     (clk        ),
                    .CDN    (rst_n      ),
                    .Q      (dout[i]    ),
                    .SI     (1'b0       ),
                    .SE     (1'b0       )
                );
            `else
                logic [SYNC_STAGES-1:0] sync_ff;
                always_ff @(posedge clk or negedge rst_n) begin
                    if(!rst_n) begin
                        sync_ff <= '0;
                    end
                    else begin
                        sync_ff[0] <= din[i];
                        for(int j=1; j<SYNC_STAGES; j=j+1) begin
                            sync_ff[j] <= sync_ff[j-1];
                        end
                    end
                end
            `endif
        end
        else begin
            `ifdef FCIP_SYNC_CELL_ASET_MODULE_NAME
                `FCIP_SYNC_CELL_ASET_MODULE_NAME #(
                    .VT_TYPE    (VT_TYPE        ),
                    .SYNC_NUM   (SYNC_STAGES    )
                ) sync_ff (
                    .D      (din[i]     ),
                    .CP     (clk        ),
                    .SDN    (rst_n      ),
                    .Q      (dout[i]    ),
                    .SI     (1'b0       ),
                    .SE     (1'b0       )
                );
            `else
                logic [SYNC_STAGES-1:0] sync_ff;
                always_ff @(posedge clk or posedge rst_n) begin
                    if(rst_n) begin
                        sync_ff <= '1;
                    end
                    else begin
                        sync_ff[0] <= din[i];
                        for(int j=1; j<SYNC_STAGES; j=j+1) begin
                            sync_ff[j] <= sync_ff[j-1];
                        end
                    end
                end
            `endif
        end
    end endgenerate

endmodule