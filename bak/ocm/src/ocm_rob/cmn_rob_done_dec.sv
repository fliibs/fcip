module cmn_rob_id_dec#(
    parameter integer unsigned BIN_WIDTH=4,
    localparam integer unsigned OH_WIDTH=1<<BIN_WIDTH
)(
    input  logic                  in_en   ,
    input  logic [BIN_WIDTH-1:0]  in_index,
    output logic [OH_WIDTH-1:0]   v_out_en
);

logic [OH_WIDTH-1:0] in_index_oh; 

cmn_bin2onehot#(
    .BIN_WIDTH    (BIN_WIDTH   ),
    .ONEHOT_WIDTH (OH_WIDTH    )
)u_bin2oh(
    .bin_in       (in_index    ),
    .onehot_out   (in_index_oh )
);

assign v_out_en = {OH_WIDTH{in_en}} & in_index_oh;
endmodule
