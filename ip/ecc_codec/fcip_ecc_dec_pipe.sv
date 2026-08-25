module fcip_ecc_dec_pipe #(
    parameter integer unsigned DATA_WIDTH    = 1024,
    localparam integer unsigned CODE_WIDTH   = ($clog2(DATA_WIDTH) + DATA_WIDTH + 1 <= 2**$clog2(DATA_WIDTH)) ? $clog2(DATA_WIDTH) : $clog2(DATA_WIDTH) + 1,
    localparam integer unsigned TOTAL_WIDTH  = DATA_WIDTH + CODE_WIDTH + 1
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic [TOTAL_WIDTH-1:0] encode_data,
    output logic [DATA_WIDTH-1:0]  data,
    output logic                   sb_err,
    output logic                   db_err
);

logic [TOTAL_WIDTH-1:0] encode_data_r;

always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        encode_data_r <= '0;
    else
        encode_data_r <= encode_data;
end

fcip_ecc_dec #(
    .DATA_WIDTH (DATA_WIDTH)
) u_ecc_dec (
    .encode_data (encode_data_r),
    .data        (data),
    .sb_err      (sb_err),
    .db_err      (db_err)
);

endmodule
