module ecc_enc_inject_sim #(
    parameter INPUT_WIDTH   = 1024,
    parameter INVALID_START = 0,
    parameter INVALID_END   = 0
)
(
    input  clk,
    input  rst_n,
    input  [INPUT_WIDTH-1:0] enc_post_data,
    output [INPUT_WIDTH-1:0] ecc_inject_data
);

reg [INPUT_WIDTH-1:0] DATA_OUT_REG;
reg err_enject_en = 0;

`ifdef ONE_BIT_RING_ECC_RANDOM_INJECT

always @(*) begin
    integer err_bit_1;

    err_bit_1 = ($urandom_range(0, INPUT_WIDTH-1));

    if (($test$plusargs("TEST_MASTER_ECC")) ||
        ($test$plusargs("TEST_SLAVE_ECC"))  ||
        ($test$plusargs("TEST_COMP_ECC"))) begin

        while (((err_bit_1 <= (INVALID_END-1)) &&
                (err_bit_1 >= (INVALID_START-1))) ||
               ((err_bit_1 <= (INPUT_WIDTH-7-1)) &&
                (err_bit_1 >= (INPUT_WIDTH-10-1)))) begin
            err_bit_1 = ($urandom_range(0, INPUT_WIDTH-1));
        end
    end
    // end else if ($test$plusargs("TEST_TGTID_ECC")) begin
    //     while (((err_bit_1 <= (INVALID_END-1)) &&
    //             (err_bit_1 >= (INVALID_START-1))) ||
    //            ((err_bit_1 > (INPUT_WIDTH-7-1)) ||
    //             (err_bit_1 < (INPUT_WIDTH-11-1)))) begin
    //         err_bit_1 = ($urandom_range(0, INPUT_WIDTH-1));
    //     end
    // end else if ($test$plusargs("ECC_TEST")) begin
    //     // err_bit_1 = ($urandom_range(0, INPUT_WIDTH-1));
    //     err_bit_1 = 16;
    // end
    else begin
        while ((err_bit_1 <= (INVALID_END-1)) &&
               (err_bit_1 >= (INVALID_START-1))) begin
            err_bit_1 = ($urandom_range(0, INPUT_WIDTH-1));
        end
    end

    DATA_OUT_REG = enc_post_data;
    DATA_OUT_REG[err_bit_1] = ~DATA_OUT_REG[err_bit_1];
end

assign ecc_inject_data = err_enject_en ? DATA_OUT_REG : enc_post_data;

`elsif TWO_BIT_RING_ECC_RANDOM_INJECT

always @(*) begin
    integer err_bit_1, err_bit_2, err_bit_3;

    err_bit_1 = ($urandom_range(0, INPUT_WIDTH-1));
    err_bit_2 = ($urandom_range(0, INPUT_WIDTH-1));
    err_bit_3 = ($urandom_range(0, INPUT_WIDTH-1));

    if (($test$plusargs("TEST_MASTER_ECC")) ||
        ($test$plusargs("TEST_SLAVE_ECC"))  ||
        ($test$plusargs("TEST_COMP_ECC"))) begin

        while (((err_bit_1 <= (INVALID_END-1)) &&
                (err_bit_1 >= (INVALID_START-1))) ||
               ((err_bit_1 <= (INPUT_WIDTH-7-1)) &&
                (err_bit_1 >= (INPUT_WIDTH-10-1)))) begin
            err_bit_1 = ($urandom_range(0, INPUT_WIDTH-1));
        end

        while (((err_bit_2 <= (INVALID_END-1)) &&
                (err_bit_2 >= (INVALID_START-1))) ||
               (err_bit_1 == err_bit_2) ||
               ((err_bit_2 <= (INPUT_WIDTH-7-1)) &&
                (err_bit_2 >= (INPUT_WIDTH-10-1)))) begin
            err_bit_2 = ($urandom_range(0, INPUT_WIDTH-1));
        end
    end
    else begin
        while ((err_bit_1 <= (INVALID_END-1)) &&
               (err_bit_1 >= (INVALID_START-1))) begin
            err_bit_1 = ($urandom_range(0, INPUT_WIDTH-1));
        end

        while (((err_bit_2 <= (INVALID_END-1)) &&
                (err_bit_2 >= (INVALID_START-1))) ||
               (err_bit_1 == err_bit_2)) begin
            err_bit_2 = ($urandom_range(0, INPUT_WIDTH-1));
        end
    end

    DATA_OUT_REG = enc_post_data;
    DATA_OUT_REG[err_bit_1] = ~DATA_OUT_REG[err_bit_1];
    DATA_OUT_REG[err_bit_2] = ~DATA_OUT_REG[err_bit_2];
end

assign ecc_inject_data = err_enject_en ? DATA_OUT_REG : enc_post_data;

`elsif ONE_BIT_RING_ECC_TRAVERSE_INJECT

reg [31:0] count;

// if($test$plusargs("TEST_ECC_COV"))begin
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count <= 'h0;
    end
    else begin
        if ($test$plusargs("TEST_ECC_COV")) begin
            if (count == INPUT_WIDTH) begin
                count <= 'h0;
            end
            else if (count == INVALID_START) begin
                count <= INVALID_END;
            end
            else if (count == INPUT_WIDTH-12-1) begin
                count <= INPUT_WIDTH - 6 - 1;
            end
            else begin
                count <= count + 1;
            end
        end
        else if ($test$plusargs("MEM_ECC_COV")) begin
            if (count == INPUT_WIDTH) begin
                count <= 'h0;
            end
            else begin
                count <= count + 1;
            end
        end
        else begin
            if (count == INPUT_WIDTH) begin
                count <= 'h0;
            end
            else if (count == INVALID_START) begin
                count <= INVALID_END + 1;
            end
            else begin
                count <= count + 1;
            end
        end
    end
end

always @(*) begin
    integer err_bit_1;

    err_bit_1 = count;
    DATA_OUT_REG = enc_post_data;
    DATA_OUT_REG[err_bit_1] = ~DATA_OUT_REG[err_bit_1];
end

assign ecc_inject_data = err_enject_en ? DATA_OUT_REG : enc_post_data;

`else

assign ecc_inject_data = enc_post_data;

`endif

endmodule
