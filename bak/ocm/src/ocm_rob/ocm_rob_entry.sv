module ocm_rob_entry
import ocm_package::*;
(       
    input  logic                                    clk                      ,
    input  logic                                    rst_n                    ,

    input  pack_ocm_rob_req_pld                     rob_req_pld              ,
    input  logic                                    v_rob_req_en             ,

    input  logic [OCM_ROB_ENTRY_DEPTH-1:0]          id_hzd                   ,
    input  logic [OCM_ROB_ENTRY_DEPTH-1:0]          addr_hzd                 ,
    output logic                                    v_hzd_addr_en            ,
    output logic                                    v_hzd_id_en              ,
    output logic [OCM_ROB_ENTRY_WIDTH-1:0]          v_hzd_id                 ,
    output logic [OCM_DATA_RAM_BANK_NUM_WIDTH-1:0]  v_hzd_num                ,
    output logic [OCM_DATA_RAM_ADDR_WIDTH-1:0]      v_hzd_addr               ,

    input  logic                                    v_wr_data_buf_done       ,
    input  logic                                    v_wr_data_ram_done       ,
    input  logic                                    v_rd_data_ram_done       ,

    output logic                                    v_pre_alloc_vld          ,
    input  logic                                    v_pre_alloc_rdy          ,
    output logic                                    v_b_vld                  ,
    input  logic                                    v_b_rdy                  ,
    output pack_ocm_b_pld                           v_b_pld                  ,

    output logic                                    v_arb_req_wr_vld         ,
    input  logic                                    v_arb_req_wr_rdy         ,
    output pack_ocm_rob_ack_pld                     v_arb_req_wr_pld         ,

    output logic                                    v_arb_req_rd_vld         ,
    input  logic                                    v_arb_req_rd_rdy         ,
    output pack_ocm_rob_ack_pld                     v_arb_req_rd_pld         ,

    output logic                                    v_release_en             ,
    input  logic [OCM_ROB_ENTRY_DEPTH-1:0]          release_en                
);  
//===============================
//=========internal signals
//===============================
logic                               idle                ;
logic                               active              ;
logic                               wr_buf_done         ;
logic                               rw_ram_done         ;
logic [OCM_AXI_LEN_MAX-1:0]         rw_ram_sent         ;


logic                               b_hsk               ;
logic                               pre_alloc_hsk       ;
logic                               rob_arb_rd_hsk      ;
logic                               rob_arb_wr_hsk      ;
logic                               rob_arb_hsk         ;
logic                               v_rw_data_ram_done  ;
logic                               v_rw_ram_done       ;
logic [OCM_AXI_LEN_MAX-1:0]         v_rw_ram_sent_done  ;
logic [OCM_AXI_LEN_MAX-2:0]         v_rw_ram_sent_vld   ;
logic [OCM_AXI_LEN_MAX-1:0]         v_rw_ram_bank_done  ;

logic [OCM_ROB_ENTRY_DEPTH-1:0]     hzd_id_regfile                           ;
logic [OCM_ROB_ENTRY_DEPTH-1:0]     hzd_addr_regfile                         ;
pack_ocm_rob_ack_pld                pld_regfile        [OCM_AXI_LEN_MAX-1:0] ;
logic [OCM_DATA_RAM_MASK_WIDTH-1:0] pld_mask_buf       [OCM_AXI_LEN_MAX-2:0] ;
logic                               hzd_pass                                 ;

logic [OCM_AXI_LEN_MAX-1:0]         v_rw_ram_sent_msk                        ;
logic [OCM_AXI_LEN_MAX-1:0]         v_rw_ram_sent_sel                        ;
pack_ocm_rob_ack_pld                v_arb_req_pld                            ;
logic [OCM_AXI_LEN_MAX-1:0]         v_len_vld                                ;
logic [OCM_AXI_LEN_MAX-1:0]         v_len_vld_msk                            ;
logic [OCM_AXI_LEN_MAX-1:0]         v_len_vld_msk_buf                        ;

//==================================================
//========state 
//==================================================

assign v_pre_alloc_vld    = !idle                                                      ;
assign pre_alloc_hsk      = v_pre_alloc_vld  && v_pre_alloc_rdy                        ;
assign b_hsk              = v_b_vld          && v_b_rdy                                ;
assign rob_arb_rd_hsk     = v_arb_req_rd_vld && v_arb_req_rd_rdy                       ;
assign rob_arb_wr_hsk     = v_arb_req_wr_vld && v_arb_req_wr_rdy                       ;
assign rob_arb_hsk        = rob_arb_rd_hsk   || rob_arb_wr_hsk                         ;
assign v_rw_data_ram_done = (v_wr_data_ram_done || v_rd_data_ram_done)                 ;
assign v_rw_ram_done      = &v_rw_ram_bank_done                                        ;

genvar i;
generate for(i=0;i<OCM_AXI_LEN_MAX;i++) begin
    if(i==0) begin    
        assign v_rw_ram_sent_done[i] = rob_arb_hsk  ;
    end
    else begin          
        assign v_rw_ram_sent_vld [i-1] = |rob_req_pld.len_msk[(i*OCM_DATA_RAM_MASK_WIDTH):(i-1)*OCM_DATA_RAM_MASK_WIDTH]                                ;
        assign v_rw_ram_sent_done[i]   = (rob_arb_hsk && !v_rw_ram_sent_vld [i-1] && !(rob_req_pld.resp==2'b10)) || (rw_ram_sent[i-1] && rob_arb_hsk )  ;
    end
end
endgenerate

generate for(i=0;i<OCM_AXI_LEN_MAX;i++) begin
    if(i==0) begin    
        assign v_rw_ram_bank_done[i] = (v_rw_data_ram_done )                                      ;
    end
    else begin
        assign v_rw_ram_bank_done[i] = (v_rw_data_ram_done && rw_ram_sent[i-1]) || rw_ram_sent[i] ;
    end
end
endgenerate

always_ff@(posedge clk or negedge rst_n) begin          
    if(~rst_n)                 idle <= 1'b1    ;
    else if(pre_alloc_hsk)     idle <= 1'b0    ;
    else if(b_hsk)             idle <= 1'b1    ;
end

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)                 active <= 1'b0  ;
    else if(v_rob_req_en)      active <= 1'b1  ;
    else if(b_hsk)             active <= 1'b0  ;
end

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)                                                                  wr_buf_done     <= 1'b1 ;
    else if(pre_alloc_hsk)                                                      wr_buf_done     <= 1'b0 ;
    else if(v_wr_data_buf_done||(v_rob_req_en &&rob_req_pld.opcode != 2'b10))   wr_buf_done     <= 1'b1 ;
end    

generate for(i=0;i<OCM_AXI_LEN_MAX;i++) begin
    always_ff@(posedge clk or negedge rst_n) begin    
        if(~rst_n)                       rw_ram_sent[i]  <= 1'b1 ;
        else if(pre_alloc_hsk)           rw_ram_sent[i]  <= 1'b0 ;
        else if(v_rw_ram_sent_done[i])     rw_ram_sent[i]  <= 1'b1 ;
    end   
end
endgenerate

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)                           rw_ram_done     <= 1'b1 ;
    else if(pre_alloc_hsk)               rw_ram_done     <= 1'b0 ;
    else if(v_rw_ram_done)               rw_ram_done     <= 1'b1 ;
end

//==================================================
//========reg file 
//==================================================

always_ff@(posedge clk) begin
    if(v_rob_req_en) begin
        pld_regfile[0].opcode               <= rob_req_pld.opcode                                                  ;
        pld_regfile[0].ram_addr             <= rob_req_pld.ram_addr                                                ;
        pld_regfile[0].ram_num              <= rob_req_pld.ram_num                                                 ;
        pld_regfile[0].rob_id               <= {{1'b0}}                                                            ;                                             
        pld_regfile[0].ram_bps_pld.data_msk <= rob_req_pld.len_msk[OCM_DATA_RAM_MASK_WIDTH-1:0]                    ;
        pld_regfile[0].ram_bps_pld.last     <= v_len_vld_msk[0]                                                    ;
        pld_regfile[0].ram_bps_pld.resp     <= rob_req_pld.resp                                                    ;
        pld_regfile[0].ram_bps_pld.id       <= rob_req_pld.id                                                      ;
    end
end

generate for(i=0;i<OCM_AXI_LEN_MAX-1;i++) begin
    always_ff@(posedge clk) begin
        pld_mask_buf[i]     <= rob_req_pld.len_msk[OCM_DATA_RAM_MASK_WIDTH*(i+1)+1:OCM_DATA_RAM_MASK_WIDTH*(i+1)]         ;
    end
    assign pld_regfile[i+1].opcode               = pld_regfile[0].opcode                    ;
    assign pld_regfile[i+1].ram_addr             = pld_regfile[0].ram_addr                  ;
    assign pld_regfile[i+1].ram_num              = pld_regfile[0].ram_num + (i+1)           ;
    assign pld_regfile[i+1].rob_id               = pld_regfile[0].rob_id                    ;
    assign pld_regfile[i+1].ram_bps_pld.data_msk = pld_mask_buf[i]                          ;
    assign pld_regfile[i+1].ram_bps_pld.last     = v_len_vld_msk_buf[i+1]                   ;
    assign pld_regfile[i+1].ram_bps_pld.resp     = pld_regfile[0].ram_bps_pld.resp          ;
    assign pld_regfile[i+1].ram_bps_pld.id       = pld_regfile[0].ram_bps_pld.id            ;
end
endgenerate

generate for(i=0;i<OCM_AXI_LEN_MAX;i++) begin
always_ff@(posedge clk)begin
    if(v_rob_req_en)             hzd_id_regfile[i] <= id_hzd[i]      ;
    else if (release_en[i])      hzd_id_regfile[i] <= 1'b0           ;
end
end
endgenerate

generate for(i=0;i<OCM_AXI_LEN_MAX;i++) begin
always_ff@(posedge clk)begin
    if(v_rob_req_en)            hzd_addr_regfile[i] <= addr_hzd[i]   ;
    else if (release_en[i])     hzd_addr_regfile[i] <= 1'b0          ;
end
end
endgenerate

generate for(i=0;i<OCM_AXI_LEN_MAX;i++) begin
                             assign v_len_vld[i]     = rob_req_pld.len_msk[i*2]                                            ; 
    if(i==OCM_AXI_LEN_MAX-1) assign v_len_vld_msk[i] = v_rob_req_en ? v_len_vld[i] : v_len_vld_msk[i]                      ;
    else                     assign v_len_vld_msk[i] = v_rob_req_en ? (~v_len_vld[i+1] &&  v_len_vld[i]) : v_len_vld_msk[i];
end
endgenerate

always_ff@(posedge clk) begin
    v_len_vld_msk_buf <= v_len_vld_msk;
end
    
//==================================================
//========Behavior
//==================================================
assign v_hzd_addr_en    = active                                 ;
assign v_hzd_id_en      = active && |pld_regfile[0].opcode       ;
assign v_hzd_id         = pld_regfile[0].ram_bps_pld.id          ;
assign v_hzd_num        = pld_regfile[0].ram_num                 ;
assign v_hzd_addr       = pld_regfile[0].ram_addr                ;
assign hzd_pass         = ~|(hzd_id_regfile || hzd_addr_regfile) ;

assign v_arb_req_wr_vld = hzd_pass && wr_buf_done && (|(~rw_ram_sent)) && (pld_regfile[0].opcode==2'b10)        ;
assign v_arb_req_rd_vld = hzd_pass && wr_buf_done && (|(~rw_ram_sent)) && !(pld_regfile[0].opcode==2'b01)       ;

assign v_b_vld          = (v_wr_data_buf_done || (rw_ram_done && !active)) && (pld_regfile[0].opcode==2'b10)    ;
assign v_b_pld.bid      = pld_regfile[0].ram_bps_pld.id                                                         ;
assign v_b_pld.bresp    = pld_regfile[0].ram_bps_pld.resp                                                       ;
assign v_release_en     = v_rw_ram_done                                                                         ;

generate for(i=0;i<OCM_AXI_LEN_MAX;i++) begin
    if(i==0)    assign v_rw_ram_sent_msk[0] = 1'b0                                      ;
    else        assign v_rw_ram_sent_msk[i] = v_rw_ram_sent_msk[i-1] || ~rw_ram_sent[i-1] ;
    end
endgenerate

assign v_rw_ram_sent_sel = ~(v_rw_ram_sent_msk | rw_ram_sent);

always_comb begin
    v_arb_req_pld = pld_regfile[0]                       ;
    for (int i=0; i<OCM_AXI_LEN_MAX; i++) begin
        if (v_rw_ram_sent_sel[i]) begin
            v_arb_req_pld = pld_regfile[i]               ;
        end
    end
end

assign v_arb_req_wr_pld = v_arb_req_pld                  ;
assign v_arb_req_rd_pld = v_arb_req_pld                  ;

endmodule