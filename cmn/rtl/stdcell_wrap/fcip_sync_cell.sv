`define FCIP_SYNC_CELL_ARST_MODULE_NAME fcip_sync_arst
`define FCIP_SYNC_CELL_ASET_MODULE_NAME fcip_sync_aset

`define LVT 0
`define SVT 1
`define ULVT 2
`define LVTLL 7
`define ULVTLL 8
module fcip_sync_cell #(
    parameter integer unsigned SYNC_WIDTH = 4,
    parameter integer unsigned SYN_NUM = 2, // must upper than 1
    parameter integer unsigned VT_TYPE = `LVT,
    parameter logic [SYNC_WIDTH-1:0] SYNC_RST_INIT = {SYNC_WIDTH{1'b0}} // 0: sync_arst, 1: sync_aset

) (
    input logic [SYNC_WIDTH-1   :0] v_sync_d    ,
    input logic                     dft_si      ,
    input logic                     dft_se      ,
    input logic                     clk         ,
    input logic                     rst_n       ,
    output logic [SYNC_WIDTH-1  :0] v_sync_q
);
    

    generate
        for(genvar i = 0; i < SYNC_WIDTH; i=i+1) begin : gen_sync_cell
            if (SYNC_RST_INIT[i]) begin
                `FCIP_SYNC_CELL_ARST_MODULE_NAME #(
                    .VT_TYPE(VT_TYPE            ),
                    .SYN_NUM(SYN_NUM            )
                ) u_sync_arst (
                    .D      (v_sync_d[i]        ),
                    .SI     (dft_si             ),
                    .SE     (dft_se             ),
                    .CP     (clk                ),
                    .CDN    (rst_n              ),
                    .Q      (v_sync_q[i]        )
                );
            end else begin
                `FCIP_SYNC_CELL_ASET_MODULE_NAME #(
                    .VT_TYPE(VT_TYPE            ),
                    .SYN_NUM(SYN_NUM            )
                ) u_sync_aset (
                    .D      (v_sync_d[i]        ),
                    .SI     (dft_si             ),
                    .SE     (dft_se             ),
                    .CP     (clk                ),
                    .SDN    (rst_n              ),
                    .Q      (v_sync_q[i]        )
                );

            end 
        end
    endgenerate











endmodule