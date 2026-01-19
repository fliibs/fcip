module fcip_grant_gen_fp #(
    parameter WIDTH=4
)(
    input  [WIDTH-1:0] v_vld,
    input  [WIDTH-1:0] v_priority,
    output [WIDTH-1:0] v_grant
);

    // Priority rule:
    // 1. v_priority[i]==1 has higher priority than v_priority[j]==0
    // 2. Within same priority group, lower bit index has higher priority
    
    wire [WIDTH-1:0] high_pri_vld;  // valid requests with priority==1
    wire [WIDTH-1:0] low_pri_vld;   // valid requests with priority==0
    wire [WIDTH-1:0] high_pri_grant;
    wire [WIDTH-1:0] low_pri_grant;
    wire             has_high_pri;
    
    // Separate valid requests by priority
    assign high_pri_vld = v_vld & v_priority;
    assign low_pri_vld  = v_vld & ~v_priority;
    assign has_high_pri = |high_pri_vld;
    
    // Fixed priority arbiter for high priority group (bit 0 highest)
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_high_pri
            if (i == 0) begin
                assign high_pri_grant[i] = high_pri_vld[i];
            end else begin
                assign high_pri_grant[i] = high_pri_vld[i] & ~(|high_pri_vld[i-1:0]);
            end
        end
    endgenerate
    
    // Fixed priority arbiter for low priority group (bit 0 highest)
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_low_pri
            if (i == 0) begin
                assign low_pri_grant[i] = low_pri_vld[i];
            end else begin
                assign low_pri_grant[i] = low_pri_vld[i] & ~(|low_pri_vld[i-1:0]);
            end
        end
    endgenerate
    
    // Select high priority grant if any high priority request exists
    assign v_grant = has_high_pri ? high_pri_grant : low_pri_grant;

endmodule 