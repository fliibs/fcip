module fcip_ecc_dec_dcls_pipe #(
    parameter  integer unsigned DATA_WIDTH  = 1024,
    localparam integer unsigned CODE_WIDTH  =
        (($clog2(DATA_WIDTH) + DATA_WIDTH + 1 <= 2**$clog2(DATA_WIDTH)) ?
          $clog2(DATA_WIDTH) : $clog2(DATA_WIDTH) + 1),
    localparam integer unsigned TOTAL_WIDTH = DATA_WIDTH + CODE_WIDTH + 1
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic [TOTAL_WIDTH-1:0] encode_data,
    output logic [DATA_WIDTH-1:0]  data,
    output logic                   sb_err,
    output logic                   db_err,
    output logic                   comp_err
);

logic [DATA_WIDTH-1:0] data_1;
logic                  sb_err_1;
logic                  db_err_1;

logic [DATA_WIDTH-1:0] data_2;
logic                  sb_err_2;
logic                  db_err_2;

logic [TOTAL_WIDTH-1:0] inj_enc_data;
logic [TOTAL_WIDTH-1:0] inj_enc_data0;
logic [TOTAL_WIDTH-1:0] inj_enc_data1;

`ifdef DFV_FUSA

ecc_enc_inject_sim #(
    .INPUT_WIDTH   (TOTAL_WIDTH),
    .INVALID_START (0),
    .INVALID_END   (0)
) u_ecc_dec_inject_core (
    .enc_post_data   (encode_data),
    .ecc_inject_data (inj_enc_data)
);

ecc_dec_inject_sim #(
    .INPUT_WIDTH (TOTAL_WIDTH)
) u_ecc_dec_inject (
    .encode_src   (inj_enc_data),
    .encode_tgt_1 (inj_enc_data0),
    .encode_tgt_2 (inj_enc_data1)
);

`else

assign inj_enc_data0 = encode_data;
assign inj_enc_data1 = encode_data;

`endif

fcip_ecc_dec_pipe #(
    .DATA_WIDTH (DATA_WIDTH)
) u_ecc_dec1 (
    .clk         (clk),
    .rst_n       (rst_n),
    .encode_data (inj_enc_data0),
    .data        (data_1),
    .sb_err      (sb_err_1),
    .db_err      (db_err_1)
);

fcip_ecc_dec_pipe #(
    .DATA_WIDTH (DATA_WIDTH)
) u_ecc_dec2 (
    .clk         (clk),
    .rst_n       (rst_n),
    .encode_data (inj_enc_data1),
    .data        (data_2),
    .sb_err      (sb_err_2),
    .db_err      (db_err_2)
);

assign comp_err = (sb_err_1 ^ sb_err_2) || (db_err_1 ^ db_err_2);
assign data     = data_1;
assign sb_err   = sb_err_1;
assign db_err   = db_err_1;

endmodule
