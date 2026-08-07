module fcip_rob_id_dec_exact #(
    parameter integer unsigned ENTRY_NUM = 16,
    localparam integer unsigned BIN_WIDTH = $clog2(ENTRY_NUM)
)(
    input  logic                 in_en    ,
    input  logic [BIN_WIDTH-1:0] in_index ,
    output logic [ENTRY_NUM-1:0] v_out_en
);

    logic [ENTRY_NUM-1:0] in_index_oh;

    fcip_bin2onehot #(
        .BIN_WIDTH    (BIN_WIDTH),
        .ONEHOT_WIDTH (ENTRY_NUM)
    ) u_bin2oh (
        .bin_in     (in_index   ),
        .onehot_out (in_index_oh)
    );

    assign v_out_en = {ENTRY_NUM{in_en}} & in_index_oh;
endmodule
