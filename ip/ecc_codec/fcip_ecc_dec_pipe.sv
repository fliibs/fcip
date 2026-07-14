module fcip_ecc_dec_pipe #(
    parameter integer unsigned DATA_WIDTH    = 1024,
    localparam integer unsigned CODE_WIDTH   = ($clog2(DATA_WIDTH) + DATA_WIDTH + 1 <= 2**$clog2(DATA_WIDTH)) ? $clog2(DATA_WIDTH) : $clog2(DATA_WIDTH) + 1,
    localparam integer unsigned TOTAL_WIDTH  = DATA_WIDTH + CODE_WIDTH + 1,
    localparam integer unsigned CODE_WIDTH_OH = 2**CODE_WIDTH
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic [TOTAL_WIDTH-1:0] encode_data,
    output logic [DATA_WIDTH-1:0]  data,
    output logic                   sb_err,
    output logic                   db_err
);

logic [TOTAL_WIDTH-1:1] dec_check_bits_array [CODE_WIDTH-1:0];
logic [CODE_WIDTH-1:0]  dec_check_bits;
logic                   dec_parity_bit;
logic [TOTAL_WIDTH-1:1] dec_data_extend_msk;

logic                   enc_parity_bit;
logic [CODE_WIDTH-1:0]  enc_check_bits;
logic [DATA_WIDTH-1:0]  enc_data;
logic [TOTAL_WIDTH-1:1] enc_data_extend;

logic [CODE_WIDTH-1:0]    check_bits_rst;
logic [CODE_WIDTH-1:0]    check_bits_rst_r;
logic [CODE_WIDTH_OH-1:0] check_bits_rst_ohot;

logic                   dec_parity_bit_r;
logic [TOTAL_WIDTH-1:1] enc_data_extend_r;

assign {enc_data, enc_check_bits, enc_parity_bit} = encode_data;

genvar i, j;
generate
    for(i=1; i<TOTAL_WIDTH; i=i+1) begin : GEN_ENC_DATA_EXTEND
        if(2**$clog2(i) == i) begin : GEN_CHECK_BIT_POS
            assign enc_data_extend[i] = 1'b0;
        end
        else begin : GEN_DATA_BIT_POS
            assign enc_data_extend[i] = enc_data[i-$clog2(i)-1];
        end
    end
endgenerate

generate
    for(i=0; i<CODE_WIDTH; i=i+1) begin : GEN_DEC_CHECK_BITS
        for(j=1; j<TOTAL_WIDTH; j=j+1) begin : GEN_DEC_CHECK_BITS_ARRAY
            if(j & (2**i)) begin : GEN_CHECK_BIT_INCLUDE
                assign dec_check_bits_array[i][j] = enc_data_extend[j];
            end
            else begin : GEN_CHECK_BIT_EXCLUDE
                assign dec_check_bits_array[i][j] = 1'b0;
            end
        end
        assign dec_check_bits[i] = ^dec_check_bits_array[i];
    end
endgenerate

assign dec_parity_bit = ^encode_data;
assign check_bits_rst = dec_check_bits ^ enc_check_bits;

always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        check_bits_rst_r  <= {CODE_WIDTH{1'b0}};
        dec_parity_bit_r  <= 1'b0;
        enc_data_extend_r <= '0;
    end
    else begin
        check_bits_rst_r  <= check_bits_rst;
        dec_parity_bit_r  <= dec_parity_bit;
        enc_data_extend_r <= enc_data_extend;
    end
end

assign sb_err =  dec_parity_bit_r && (check_bits_rst_r <= TOTAL_WIDTH-1);
assign db_err = (~dec_parity_bit_r && (|check_bits_rst_r)) || (check_bits_rst_r > TOTAL_WIDTH-1);

fcip_bin2onehot #(
    .BIN_WIDTH    (CODE_WIDTH),
    .ONEHOT_WIDTH (CODE_WIDTH_OH)
) u_fcip_bin2onehot (
    .bin_in     (check_bits_rst_r),
    .onehot_out (check_bits_rst_ohot)
);

assign dec_data_extend_msk = check_bits_rst_ohot[TOTAL_WIDTH-1:1] ^ enc_data_extend_r;

generate
    for(i=1; i<TOTAL_WIDTH; i=i+1) begin : GEN_DEC_DATA
        if(2**$clog2(i) != i) begin : GEN_DATA_OUT
            assign data[i-$clog2(i)-1] = dec_data_extend_msk[i];
        end
    end
endgenerate

endmodule
