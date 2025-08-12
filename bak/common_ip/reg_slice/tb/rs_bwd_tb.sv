`timescale 1ns/1ps
module rs_bwd_tb;

parameter PLD_WIDTH = 32;

logic clk, rst_n;
logic s_vld;
logic [PLD_WIDTH-1:0] s_pld;

logic m_rdy;

initial begin
    clk=0;
    forever #5 clk=~clk;
end 

initial begin 
    s_pld = {PLD_WIDTH{1'b0}};
    forever #10 s_pld = {$random}%32;
end 

initial begin
    s_vld <= 1'b0;
    rst_n <= 0;
    #5
    rst_n <= 1;
    repeat(12) @(posedge clk)
    s_vld <= 1'b1;
    repeat(1) @(posedge clk)
    s_vld <= {$random}%1;
    repeat(1) @(posedge clk)
    s_vld <= {$random}%1;
    repeat(1) @(posedge clk)
    s_vld <= {$random}%1;
    repeat(2) @(posedge clk)
    s_vld <= 1'b0;
    repeat(1) @(posedge clk)
    s_vld <= 1'b1;
    #100
    $finish;
end

initial begin
    m_rdy <= 1'b1; 
    repeat(10) @(posedge clk)
    m_rdy <= 1'b1;
    repeat(3) @(posedge clk)
    m_rdy <= 1'b0;
    repeat(1) @(posedge clk)
    m_rdy <= 1'b1;

end

reg_slice_backward #(
    .PLD_WIDTH(PLD_WIDTH)
) u_rs (
    .clk(clk),
    .rst_n(rst_n),
    .s_vld(s_vld),
    .s_pld(s_pld),
    .m_rdy(m_rdy)

);


initial begin 
    $fsdbDumpfile("tb_top.fsdb");
    $fsdbDumpvars(0);
end


endmodule 