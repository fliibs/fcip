module cmn_onehot2bin #(
    parameter integer unsigned  ONEHOT_WIDTH = 4,
    localparam integer unsigned BIN_WIDTH    = $clog2(ONEHOT_WIDTH)
) (
    input  logic [ONEHOT_WIDTH-1:0] onehot_in,
    output logic [BIN_WIDTH   -1:0] bin_out 
);
    always_comb begin
        bin_out = {BIN_WIDTH{1'b0}};
        for (int i=0; i<ONEHOT_WIDTH; i++) begin
            if (onehot_in[i]) begin
                bin_out = BIN_WIDTH'(i);
            end
        end
    end

    
endmodule