`timescale 1ns/1ps
module arb_matrix_tb;

parameter WIDTH = 4;
logic clk, rst_n;
logic [WIDTH-1:0] v_vld;
logic [WIDTH-1:0] v_grant;

initial begin
    clk=0;
    forever #5 clk=~clk;
end 

initial begin
    v_vld = {WIDTH{1'b1}};
    rst_n = 0;
    #10
    rst_n = 1;
    #100
    v_vld = {$random}%16;
    #10
    v_vld = {$random}%16;
    #100
    $finish;
end

logic               alloc_en;
logic [WIDTH-1:0]   v_alloc;
logic [WIDTH-1:0]   vv_matrix [WIDTH-1:0];

assign alloc_en = |v_grant;
assign v_alloc  = v_grant;

age_matrix #(
    .WIDTH(WIDTH)
) u_matrix (
    .clk(clk),
    .rst_n(rst_n),
    .alloc_en(alloc_en),
    .v_alloc(v_alloc),
    .vv_matrix(vv_matrix)
);

arb_matrix #(
    .WIDTH(WIDTH)
) u_arb (
    .clk(clk),
    .rst_n(rst_n),
    .vv_matrix(vv_matrix),
    .v_vld(v_vld),
    .v_grant(v_grant)
);

initial begin 
    $fsdbDumpfile("tb_top.fsdb");
    $fsdbDumpvars(0);
    // $fsdbDumpMem(0);
    $fsdbDumpMDA();
end


endmodule