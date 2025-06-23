module cmn_lfsr4 (
              input  logic       clk,       
              input  logic       rst_n,       
              output logic [3:0] out  
             );

    logic feedback;

    assign feedback = out[3] ^ out[0]; // x^4 + x + 1

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out <= 4'b0001;    
        end 
        else begin
            out <= {out[2:0], feedback};
        end
    end


    // reg [15:0] lfsr; // 16-bit LFSR for generating randomness
    // wire feedback;

    // // 反馈多项式选择
    // assign feedback = lfsr[15] ^ lfsr[14] ^ lfsr[12] ^ lfsr[3];

    // always @(posedge clk or negedge rst_n) begin
    //     if (rst_n) begin
    //         lfsr <= 16'h1; // 初始化LFSR种子值
    //     end else begin
    //         lfsr <= {lfsr[14:0], feedback}; // 反馈值的计算和移位
    //     end
    // end

    // // 生成4-bit随机数，每个bit的概率递减
    // assign out[0] = lfsr[0];    // 最高概率
    // assign out[1] = lfsr[1] & lfsr[2]; // 较低概率
    // assign out[2] = lfsr[3] & lfsr[4] & lfsr[5]; // 更低概率
    // assign out[3] = lfsr[6] & lfsr[7] & lfsr[8] & lfsr[9]; // 最低概率

endmodule
