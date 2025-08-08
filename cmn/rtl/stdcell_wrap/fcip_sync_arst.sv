module fcip_sync_arst #(
    parameter integer unsigned SYN_NUM = 2,// must upper than 1
    parameter integer unsigned VT_TYPE = 0 // 0: LVT, 1: SVT, 2: ULVT, 7: LVTLL, 8: ULVTLL
) (
    input logic D,
    input logic SI,
    input logic SE,
    input logic CP,
    input logic CDN,
    output logic Q
);

    logic [SYN_NUM-1:0] meta;

    assign Q = meta[SYN_NUM-1];

    always_ff @(posedge CP or negedge CDN) begin
        if (~CDN) begin
            meta <= {SYN_NUM{1'b0}};
        end else if (SE) begin
            meta[0] <= SI;
            meta[SYN_NUM-1:1] <= meta[SYN_NUM-2:0];
        end else begin
            meta[0] <= D;
            meta[SYN_NUM-1:1] <= meta[SYN_NUM-2:0];
        end
        
    end
    

    
endmodule