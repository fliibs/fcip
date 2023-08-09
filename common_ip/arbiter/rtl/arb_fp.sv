module arb_fp #(
    parameter WIDTH=4
)(
    input  [WIDTH-1:0] v_vld,
    input  [WIDTH-1:0] v_priority,
    output [WIDTH-1:0] v_grant
);

    wire [WIDTH*2-1:0] double_vld;
    wire [WIDTH*2-1:0] double_priority;
    wire [WIDTH*2-1:0] double_grant;

    assign double_vld       = {v_vld, v_vld};
    assign double_priority  = double_vld - {{WIDTH{1'b0}},v_priority};
    assign double_grant     = double_vld & (~double_priority);
    assign v_grant          = double_grant[WIDTH*2-1:WIDTH] | double_grant[WIDTH-1:0];


endmodule 