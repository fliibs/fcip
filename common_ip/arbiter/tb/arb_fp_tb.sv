`timescale 1ns/1ps
module arb_fp_tb;

parameter WIDTH = 4;
logic [WIDTH-1:0] v_vld;
logic [WIDTH-1:0] v_grant;
logic [WIDTH-1:0] v_priority;


initial begin
    v_vld <= {WIDTH{1'b1}};
    v_priority <= {{(WIDTH-1){1'b0}}, 1'b1};
    #10
    v_vld <= {$random}%16;
    #10
    v_vld <= {$random}%16;
    #100
    $finish;
end


arb_fp #(
    .WIDTH(WIDTH)
) u_arb (
    .v_vld(v_vld),
    .v_priority(v_priority),
    .v_grant(v_grant)
);

initial begin 
    $fsdbDumpfile("tb_top.fsdb");
    $fsdbDumpvars(0);
end


endmodule