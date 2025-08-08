`define LVT 0
`define SVT 1
`define ULVT 2
`define LVTLL 7
`define ULVTLL 8


module bydlib_sync_aset #(
    parameter integer unsigned SYN_NUM = 2,// must upper than 1
    parameter integer unsigned VT_TYPE = `LVT
) (
    input logic D,
    input logic SI,
    input logic SE,
    input logic CP,
    input logic SDN,
    output logic Q
);

    logic [SYN_NUM-1:0] meta;
    
    assign Q = meta[SYN_NUM-1];
    
    always_ff @(posedge CP or negedge SDN) begin
        if (~SDN) begin
            meta <= {SYN_NUM{1'b1}};
        end else if (SE) begin
            meta[0] <= SI;
            meta[SYN_NUM-1:1] <= meta[SYN_NUM-2:0];
        end else begin
            meta[0] <= D;
            meta[SYN_NUM-1:1] <= meta[SYN_NUM-2:0];
        end
        
    end


    
endmodule