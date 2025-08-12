`timescale 1ns/1ps
module arb_rr_tb;

parameter WIDTH = 4;
logic clk, rst_n;
logic [WIDTH-1:0] v_vld;
logic [WIDTH-1:0] v_grant;

initial begin
    clk=0;
    forever #5 clk=~clk;
end 

initial begin
    v_vld <= {WIDTH{1'b1}};
    rst_n <= 0;
    #10
    rst_n <= 1;
    // #10
    // v_vld = {$random}%16;
    // #10
    // v_vld = {$random}%16;
    #100
    v_vld <= {$random}%16;
    #10
    v_vld <= {$random}%16;
    #100
    $finish;
end


arb_rr #(
    .WIDTH(WIDTH)
) u_arb (
    .clk(clk),
    .rst_n(rst_n),
    .v_vld(v_vld),
    .v_grant(v_grant)
);

initial begin 
    $fsdbDumpfile("tb_top.fsdb");
    $fsdbDumpvars(0);
end


endmodule