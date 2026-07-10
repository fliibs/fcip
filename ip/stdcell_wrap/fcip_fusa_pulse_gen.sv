// Pulse generator for safety interrupt output.
// When err_in goes high, intr_out goes high and stays high for
// CNT_WIDTH+1 clock cycles (counter overflows to all-1s then clears).
// CNT_WIDTH should be chosen based on the frequency ratio between
// the error-sampling domain and the error-collecting domain.
// Default CNT_WIDTH=4 → 16-cycle pulse.
module fcip_fusa_pulse_gen #(
    parameter integer unsigned CNT_WIDTH = 4
) (
    input  logic               clk     ,
    input  logic               rst_n   ,
    input  logic               err_in  ,
    output logic               intr_out
);

    logic [CNT_WIDTH-1:0]       cnt;
    logic                       cnt_max;

    assign cnt_max = &cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            intr_out <= 1'b0;
        end
        else if (err_in) begin
            intr_out <= 1'b1;
        end
        else if (cnt_max) begin
            intr_out <= 1'b0;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= '0;
        end
        else if (err_in) begin
            cnt <= '0;
        end
        else if (intr_out && !cnt_max) begin
            cnt <= cnt + 1'b1;
        end
    end

endmodule
