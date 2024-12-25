module ocm_rob_entry
import ocm_package::*;
(       
    input  logic                                    clk                      ,
    input  logic                                    rst_n                    ,

    input  pack_ocm_rob_pld                         axpld                    ,
    input  logic                                    v_update_en              ,
    input  logic [OCM_ROB_ENTRY_NUM-1:0]            hzd_id_en                ,
    input  logic [OCM_ROB_ENTRY_NUM-1:0]            hzd_addr_en              ,
    output logic                                    v_en                     ,
    output logic [OCM_ROB_ENTRY_WIDTH-1:0]          v_hzd_id                 ,
    output logic [OCM_DATA_RAM_NUM-1:0]             v_hzd_num                ,
    output logic [OCM_L_DATA_RAM_ADDR_WIDTH-1:0]    v_hzd_addr               ,

    input  logic                                    v_wr_data_buf_done       ,
    input  logic                                    v_wr_data_ram_done       ,
    input  logic                                    v_rd_data_ram_done       ,

    output logic                                    v_pre_alloc_vld          ,
    input  logic                                    v_pre_alloc_rdy          ,

    output logic                                    v_b_vld                  ,
    input  logic                                    v_b_rdy                  ,
    output pack_ocm_b_pld                           v_b_pld                  ,

    output logic                                    v_arb_req                ,
    output logic                                    v_arb_op_is_rd           ,
    output pack_ocm_arb_req_pld                     v_arb_req_pld            ,
    input  logic                                    v_arb_ack                ,

    output logic                                    v_release_en             ,
    input  logic [OCM_ROB_ENTRY_NUM-1:0]            release_en                
);  
//===============================
//=========internal signals
//===============================
logic       idle                ;
logic       active              ;
logic       wr_buf_done         ;
logic       arb_ack             ;
logic       rw_data_ram_done    ;

logic       b_chl_hsk           ;
logic       pre_alloc_hsk       ;
logic       rd_data_ram_done    ;
logic       wr_data_ram_done    ;


logic [OCM_ROB_ENTRY_NUM-1:0]       hzd_id_regfile                  ;
logic [OCM_ROB_ENTRY_NUM-1:0]       hzd_addr_regfile                ;
pack_ocm_rob_pld                    pld_regfile                     ;


//==============================
//========reg file 
//==============================
assign b_chl_hsk = v_b_vld && v_b_rdy                               ;

always_ff@(posedge clk or negedge rst_n) begin          
    if(~rst_n)                 idle <= 1'b1    ;
    else if(pre_alloc_hsk)     idle <= 1'b0    ;
    else if(b_chl_hsk)         idle <= 1'b1    ;
    end

assign v_pre_alloc_vld = !idle;
assign pre_alloc_hsk   = v_pre_alloc_vld && v_pre_alloc_rdy ;

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)                 active <= 1'b0   ;
    else if(v_update_en)       active <= 1'b1   ;
    else if(b_chl_hsk)         active <= 1'b0   ;
end


always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)                                                    wr_buf_done <= 1'b1 ;
    else if(pre_alloc_hsk)                                        wr_buf_done <= 1'b0 ;
    else if(v_wr_data_buf_done||(v_update_en &&axpld.op_is_rd))   wr_buf_done <= 1'b1 ;
end

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)                 arb_ack <= 1'b1     ;
    else if(v_update_en)       arb_ack <= 1'b0     ;
    else if(v_arb_ack)         arb_ack <= 1'b1     ;
end

assign rd_data_ram_done = pld_regfile.op_is_rd && v_rd_data_ram_done ;
assign wr_data_ram_done = !pld_regfile.op_is_rd && v_wr_data_ram_done;

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)                                      rw_data_ram_done <= 1'b1;
    else if(v_update_en)                            rw_data_ram_done <= 1'b0;
    else if(rd_data_ram_done || wr_data_ram_done)   rw_data_ram_done <= 1'b1;
end

assign v_en          = active                                                                                                                       ;
assign v_b_vld       = (((rd_data_ram_done || wr_data_ram_done) && (!rw_data_ram_done)) || (rw_data_ram_done && active)) && (!pld_regfile.op_is_rd) ; 
assign v_release_en  = rw_data_ram_done                                                                                                             ; 
//==============================
//========reg file 
//==============================
always_ff@(posedge clk) begin
    if(v_update_en)     pld_regfile <= axpld    ;
end

genvar i;
generate for(i=0;i<OCM_ROB_ENTRY_NUM;i++) begin
always_ff@(posedge clk)begin
    if(v_update_en)             hzd_id_regfile[i] <= hzd_id_en[i]       ;
    else if (release_en[i])     hzd_id_regfile[i] <= 1'b0               ;
end
end
endgenerate

generate for(i=0;i<OCM_ROB_ENTRY_NUM;i++) begin
always_ff@(posedge clk)begin
    if(v_update_en)             hzd_addr_regfile[i] <= hzd_addr_en[i]   ;
    else if (release_en[i])     hzd_addr_regfile[i] <= 1'b0             ;
end
end
endgenerate

assign v_hzd_id     = pld_regfile.axid          ;
assign v_hzd_num    = pld_regfile.data_ram_num  ;
assign v_hzd_addr   = pld_regfile.data_ram_addr ;

//==============================
//========behavior
//==============================
assign v_arb_req                    = (|hzd_addr_regfile && |hzd_id_regfile) && (!arb_ack) && (wr_buf_done) ;
assign v_b_pld.bid                  = pld_regfile.axid                                                      ;
assign v_b_pld.bresp                = pld_regfile.addr_range_error ? 2'b10 : 2'b00                          ;  
assign v_arb_op_is_rd               = pld_regfile.op_is_rd                                                  ;

assign v_arb_req_pld.axid           = pld_regfile.axid                                                      ;
assign v_arb_req_pld.len            = pld_regfile.axlen                                                     ;
assign v_arb_req_pld.data_ram_addr  = pld_regfile.data_ram_addr                                             ;
assign v_arb_req_pld.data_ram_num   = pld_regfile.data_ram_num                                              ;

endmodule