module ocm_rob_arbiter
import ocm_package::*;
(
    input  logic                                clk                                                 ,
    input  logic                                rst_n                                               ,
    input  logic [OCM_ROB_ENTRY_NUM-1:0]        v_arb_req                                           ,
    output logic [OCM_ROB_ENTRY_NUM-1:0]        v_arb_ack                                           ,
    input  logic [OCM_ROB_ENTRY_NUM-1:0]        v_arb_req_is_rd                                     ,  
    input  pack_ocm_arb_req_pld                 v_req_pld                  [OCM_ROB_ENTRY_NUM-1:0]  ,
    //#TODO:update credit
    input  logic                                credit                                              ,
    output logic                                ack_read_data_buf_vld                               ,
    output logic                                ack_read_data_ram_vld                               ,
    output pack_ocm_arb_ack_pld                 ack_read_data_buf_pld                               ,
    output pack_ocm_arb_ack_pld                 ack_read_data_ram_pld                               ,
    
    input  logic [OCM_ROB_ENTRY_NUM-1:0] [OCM_ROB_ENTRY_NUM-1:0]    v_age                                       
); 

//========================================================
//========= internal signals
//========================================================
logic [OCM_DATA_RAM_DEPTH-1:0]      past_wr_num  [OCM_READ_BUFFER_CYCLE-1:0]    ; 
logic [OCM_READ_BUFFER_CYCLE-1:0]   past_wr_vld                                 ;
logic [OCM_DATA_RAM_DEPTH-1:0]      past_rd_num                                 ;
logic                               past_rd_vld                                 ;

logic [OCM_ROB_ENTRY_NUM-1:0]       arb_req_wr_en                               ;
logic [OCM_ROB_ENTRY_NUM-1:0]       arb_req_rd_en                               ;
logic [OCM_ROB_ENTRY_NUM-1:0]       arb_req_rd_mask                             ;
logic [OCM_ROB_ENTRY_NUM-1:0]       arb_req_rd_mask_rd                          ;
logic [OCM_ROB_ENTRY_NUM-1:0]       arb_req_rd_mask_wr                          ;
logic [OCM_DATA_RAM_NUM-1:0]        v_arb_req_num [OCM_ROB_ENTRY_NUM-1:0]       ;
logic [OCM_ROB_ENTRY_WIDTH-1:0]     ack_read_data_buf_id                        ;
logic [OCM_ROB_ENTRY_WIDTH-1:0]     ack_read_data_ram_id                        ;

logic [OCM_ROB_ENTRY_NUM-1:0] [OCM_ROB_ENTRY_NUM-1:0] v_age_tsp                 ;
logic [OCM_ROB_ENTRY_NUM-1:0]                         age_cal_rd                ;
logic [OCM_ROB_ENTRY_NUM-1:0]                         age_cal_wr                ;

logic [OCM_PACK_FIFO_WIDTH-1:0]     credit_cnt                                  ;
//========================================================
//========= mask 
//========================================================
//if read num equals last read num or oldest and write num in past_num,it should be masked
//if request is write, it wouldn't be masked

assign arb_req_wr_en   = (~v_arb_req_is_rd) & v_arb_req   ;

genvar i ;
generate for(i=0;i<OCM_READ_BUFFER_CYCLE;i++) begin
    assign v_arb_req_num[i] = v_req_pld[i].num            ;
end
endgenerate

generate for(i=0;i<OCM_READ_BUFFER_CYCLE;i++) begin
    assign arb_req_rd_mask_rd[i] = ~((v_arb_req_num[i] == past_rd_num) & past_rd_vld)   ;
end
endgenerate

generate for(i=0;i<OCM_READ_BUFFER_CYCLE;i++) begin
    assign arb_req_rd_mask_wr[i] = ~(((v_arb_req_num[i] == past_wr_num[OCM_READ_BUFFER_CYCLE-1]) & past_wr_vld[OCM_READ_BUFFER_CYCLE-1])|((v_arb_req_num[i] == past_wr_num[OCM_READ_BUFFER_CYCLE-2]) & past_wr_vld[OCM_READ_BUFFER_CYCLE-2]));
end
endgenerate

assign arb_req_rd_mask = arb_req_rd_mask_rd          & arb_req_rd_mask_wr   ;
assign arb_req_rd_en   = v_arb_req_is_rd & v_arb_req & arb_req_rd_mask      ;

//========================================================
//========= arbitrate through age matix 
//======================================================== 
integer j;
generate for(i=0;i<OCM_READ_BUFFER_CYCLE;i++) begin
    for(j=0;i<OCM_READ_BUFFER_CYCLE;j++) begin
        assign v_age_tsp[i][j] = v_age[j][i]  ;
    end
end
endgenerate

generate for(i=0;i<OCM_READ_BUFFER_CYCLE;i++) begin
    assign age_cal_rd[i] = arb_req_rd_en[i] ? ~|(v_age_tsp[i] & arb_req_rd_en) : 1'b0;
end
endgenerate

generate for(i=0;i<OCM_READ_BUFFER_CYCLE;i++) begin
    assign age_cal_wr[i] = arb_req_wr_en[i] ? ~|(v_age_tsp[i] & arb_req_wr_en) : 1'b0;
end
endgenerate

assign v_arb_ack             = age_cal_rd | age_cal_wr ;
assign ack_read_data_buf_vld = |age_cal_rd             ;
assign ack_read_data_ram_vld = |age_cal_wr             ;

cmn_onehot2bin #(
    .ONEHOT_WIDTH(OCM_ROB_ENTRY_NUM)
)u_ohot2bin_ack_wr(
    .onehot_in(age_cal_rd           ),
    .bin_out  (ack_read_data_ram_id )
);

cmn_onehot2bin #(
    .ONEHOT_WIDTH(OCM_ROB_ENTRY_NUM)
)u_ohot2bin_ack_rd(
    .onehot_in(age_cal_wr           ),
    .bin_out  (ack_read_data_buf_id )
);

always_comb begin
    ack_read_data_ram_pld[$bits(v_req_pld)-1:0] = v_req_pld[0];
    for(int i=0;i<OCM_ROB_ENTRY_NUM;i++) begin
        if(age_cal_rd[i]) begin
            ack_read_data_ram_pld= v_req_pld[i];
        end
    end
end

cmn_onehot2bin #(
    .ONEHOT_WIDTH(OCM_ROB_ENTRY_NUM)
)u_read_data_ram_id(
    .onehot_in(age_cal_rd                ),
    .bin_out  (ack_read_data_ram_pld.axid)
);

always_comb begin
    ack_read_data_buf_pld[$bits(v_req_pld)-1:0] = v_req_pld[0];
    for(int i=0;i<OCM_ROB_ENTRY_NUM;i++) begin
        if(age_cal_wr[i]) begin
            ack_read_data_buf_pld= v_req_pld[i];
        end
    end
end

cmn_onehot2bin #(
    .ONEHOT_WIDTH(OCM_ROB_ENTRY_NUM)
)u_read_data_buf_id(
    .onehot_in(age_cal_wr                ),
    .bin_out  (ack_read_data_buf_pld.axid)
);
//========================================================
//========= update register
//======================================================== 
generate for(i=0;i<OCM_READ_BUFFER_CYCLE;i++) begin
    if(i==0) begin
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n)                  past_wr_vld[i] <= 1'b0;
        else if(|arb_req_wr_en)     past_wr_vld[i] <= 1'b1;
    end
    end
    else begin
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n)                  past_wr_vld[i] <= 1'b0                  ;
        else                        past_wr_vld[i] <= past_wr_vld[i-1]      ;
    end
    end
end
endgenerate

generate for(i=0;i<OCM_READ_BUFFER_CYCLE;i++) begin
    if(i==0) begin
    always@(posedge clk) begin
        past_wr_num[i] <= ack_read_data_buf_id  ;
    end
    end
    else begin
    always@(posedge clk) begin
        past_wr_num[i] <= past_wr_num[i-1]      ;
    end
    end
end
endgenerate

always@(posedge clk or negedge rst_n) begin
    if(~rst_n)                  past_rd_vld<= 1'b0;
    else if(|arb_req_rd_en)     past_rd_vld<= 1'b1;
end

always@(posedge clk) begin
    past_rd_num <= ack_read_data_ram_id;
end

endmodule