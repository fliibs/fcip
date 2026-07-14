module ecc_dec_inject_sim #(
    parameter INPUT_WIDTH = 1024
)
(
    input                           clk,
    input                           rst_n,
    input  [INPUT_WIDTH-1:0]        encode_src,
    output [INPUT_WIDTH-1:0]        encode_tgt_1,
    output [INPUT_WIDTH-1:0]        encode_tgt_2
);

reg [INPUT_WIDTH-1:0] DATA_OUT_REG;
reg err_inject_en = 0;

`ifdef COMPARE_RING_ECC_RANDOM_INJECT

always @(*) begin
    integer err_bit_1;

    err_bit_1 = ($urandom_range(0, INPUT_WIDTH-1));

    // while((err_bit_1 < INVALID_END) &&
    //       (err_bit_1 > INVALID_START)) begin
    //     err_bit_1 = ($urandom_range(0, INPUT_WIDTH-1));
    // end

    DATA_OUT_REG = encode_src;
    DATA_OUT_REG[err_bit_1] = ~DATA_OUT_REG[err_bit_1];
end

assign encode_tgt_1 = encode_src;
assign encode_tgt_2 = err_inject_en ? DATA_OUT_REG : encode_src;

`elsif COMPARE_RING_ECC_DEC1_TRAVERSE_INJECT

reg [31:0] count;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count <= 'h0;
    end
    else begin
        if (count == INPUT_WIDTH) begin
            count <= 'h0;
        end
        else begin
            count <= count + 1;
        end
    end
end

always @(*) begin
    integer err_bit_1;

    err_bit_1 = count;
    DATA_OUT_REG = encode_src;
    DATA_OUT_REG[err_bit_1] = ~DATA_OUT_REG[err_bit_1];
end

assign encode_tgt_1 = err_inject_en ? DATA_OUT_REG : encode_src;
assign encode_tgt_2 = encode_src;

`elsif COMPARE_RING_ECC_DEC2_TRAVERSE_INJECT

reg [31:0] count;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count <= 'h0;
    end
    else begin
        if (count == INPUT_WIDTH) begin
            count <= 'h0;
        end
        else begin
            count <= count + 1;
        end
    end
end

always @(*) begin
    integer err_bit_1;

    err_bit_1 = count;
    DATA_OUT_REG = encode_src;
    DATA_OUT_REG[err_bit_1] = ~DATA_OUT_REG[err_bit_1];
end

assign encode_tgt_1 = encode_src;
assign encode_tgt_2 = err_inject_en ? DATA_OUT_REG : encode_src;

`else

assign encode_tgt_1 = encode_src;
assign encode_tgt_2 = encode_src;

`endif

endmodule
