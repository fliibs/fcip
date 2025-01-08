module ocm_req_init_agt
import ocm_package::*;
(
    input   logic                               clk             ,
    input   logic                               rst_n           ,
    input   logic                               init            ,
    input   logic [OCM_ROB_ENTRY_WIDTH-1:0]     rob_ar_out_id   ,
    output  logic                               init_vld        ,
    input   logic                               init_rdy        ,
    output  pack_ocm_ax_pld                     init_pld        ,
    output  logic                               init_done       ,
    output  logic [OCM_INIT_ADDR_WIDTH:0]       init_rgn        
);
    logic                               init_hsk        ;
assign init_hsk = init_vld && init_rdy                  ;

always_ff@(posedge clk or negedge rst_n) begin
    if(rst_n)                                   init_rgn <= {(OCM_INIT_ADDR_WIDTH+1){1'b0}}                     ;
    else if(init && (~init_done) && init_hsk)   init_rgn <= init_rgn + {{(OCM_INIT_ADDR_WIDTH){1'b0}},1'b1}     ;            
end 
assign init_vld  = init && (~init_done)             ;   
assign init_done = init_rgn[OCM_INIT_ADDR_WIDTH]    ;

assign init_pld.addr   = init_rgn                ;
assign init_pld.burst  = 2'b01                   ;
assign init_pld.id     = rob_ar_out_id           ;
assign init_pld.len    = OCM_DATA_RAM_SPLIT_NUM-1;
assign init_pld.size   = 3'b110                  ;

endmodule