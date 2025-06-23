module cmn_bin2onehot#(
    parameter   BIN_WIDTH       = 5,

    //do NOT change below parameter, or use localparam at new version tools
    parameter   ONEHOT_WIDTH    = 2**BIN_WIDTH
)(
    input [BIN_WIDTH-1 : 0]         bin_in,
    output [ONEHOT_WIDTH-1 : 0]     onehot_out
);

    genvar i;

    generate
        for(i=0;i<ONEHOT_WIDTH;i=i+1)begin : BIN2OH
            assign onehot_out[i]    =   (bin_in == i[BIN_WIDTH-1:0]);
        end
    endgenerate

endmodule