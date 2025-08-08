`define LVT 0
`define SVT 1
`define ULVT 2
`define LVTLL 7
`define ULVTLL 8

module cmn_sync_cell #(
    parameter integer unsigned SYN_BITS = 4,
    parameter integer unsigned SYN_NUM = 2, // must upper than 1
    parameter integer unsigned VT_TYPE = `LVT,
    parameter logic [SYN_BITS-1:0] SYNC_RST_INIT = {SYN_BITS{1'b0}} // 0: sync_arst, 1: sync_aset

) (
    input logic [SYN_BITS-1     :0] v_sync_d    ,
    input logic                     dft_si      ,
    input logic                     dft_se      ,
    input logic                     clk         ,
    input logic                     rst_n       ,
    output logic [SYN_BITS-1    :0] v_sync_q
);
    

    generate
        for(genvar i = 0; i < SYN_BITS; i=i+1) begin : gen_sync_cell
            if (SYNC_RST_INIT[i]) begin
                bydlib_sync_aset #(
                    .SYN_NUM(SYN_NUM            ),
                    .VT_TYPE(VT_TYPE            )
                ) sync_aset (
                    .D      (v_sync_d[i]        ),
                    .SI     (dft_si             ),
                    .SE     (dft_se             ),   
                    .CP     (clk                ),
                    .SDN    (rst_n              ),
                    .Q      (v_sync_q[i]        )
                );
            end else begin
                bydlib_sync_arst #(
                    .SYN_NUM(SYN_NUM            ),
                    .VT_TYPE(VT_TYPE            )
                ) sync_arst (
                    .D      (v_sync_d[i]        ),
                    .SI     (dft_si             ),
                    .SE     (dft_se             ),
                    .CP     (clk                ),
                    .CDN    (rst_n              ),
                    .Q      (v_sync_q[i]        )
                );
            end 
        end
    endgenerate











endmodule