module ocm_data_buffer
import ocm_package::*;
(
    input  logic                               clk              ,
    input  logic                               rst_n            ,
    //upstream w channel signals    
    input  logic                               wvld             ,
    input  pack_ocm_w_pld                      wpld             ,
    //req_arbiter signals   
    input  logic                               wrdy             ,
    input  logic [OCM_ROB_ENTRY_WIDTH-1:0]     w_rob_id         ,
    //init signals
    input  logic                               init_start       ,
    output logic [OCM_AXI_ADDR_WIDTH-1:0]      init_rgn         ,
    //rob signals
    input  logic                               read_data_buf_en ,
    input  pack_ocm_arb_ack_pld                read_data_buf_pld,
    output logic                               wr_data_buf_done ,
    output logic [OCM_ROB_ENTRY_WIDTH-1:0]     wr_data_buf_id   ,
    //xbar signals
    output logic                               wr_data_ram_en   ,
    output pack_ocm_data_ram_wr_pld            wr_data_ram_pld  

);
//================================================================
//===========================internal signals
//================================================================ 
//===============init 
logic                                       init_rgn_meet       ;
logic                                       init_addr_meet      ;
logic                                       init_num_meet       ;
logic [OCM_L_DATA_RAM_ADDR_WIDTH-1:0]       init_addr           ;
logic [OCM_DATA_RAM_DEPTH-1:0]              init_num            ;
logic                                       init_done           ;

//===============decoder
logic [OCM_ROB_ENTRY_WIDTH-1:0]             w_rob_id_buf        ;
logic [OCM_AXI_DATA_WIDTH-1:0]              w_data_buf          ;
logic                                       w_chl_hsk           ;
logic                                       w_chl_hsk_last      ;
logic [OCM_AXI_DATA_WIDTH-1:0]              w_buf_vld           ;
// logic                                       w_pld_cnt           ;

//===============dual port sram 
logic                                       upper_ram_wr_en           ;
logic [OCM_L_DATA_RAM_ADDR_WIDTH-1:0]       upper_ram_wr_addr         ;
logic [OCM_L_DATA_RAM_DATA_WIDTH-1:0]       upper_ram_wr_din          ;
logic                                       upper_ram_rd_en           ;
logic [OCM_L_DATA_RAM_ADDR_WIDTH-1:0]       upper_ram_rd_addr         ;
logic [OCM_L_DATA_RAM_DATA_WIDTH-1:0]       upper_ram_rd_dout         ;

logic                                       lower_ram_wr_en           ;
logic [OCM_L_DATA_RAM_ADDR_WIDTH-1:0]       lower_ram_wr_addr         ;
logic [OCM_L_DATA_RAM_DATA_WIDTH-1:0]       lower_ram_wr_din          ;
logic                                       lower_ram_rd_en           ;
logic [OCM_L_DATA_RAM_ADDR_WIDTH-1:0]       lower_ram_rd_addr         ;
logic [OCM_L_DATA_RAM_DATA_WIDTH-1:0]       lower_ram_rd_dout         ;

//===============buffer to xbar
logic                                       read_data_buf_en_buf      ;


//================================================================
//===========================initialization
//================================================================ 
assign init_addr_meet = init_addr== OCM_L_DATA_RAM_ADDR_DEPTH-1 ;
assign init_num_meet  = init_num == OCM_DATA_RAM_NUM-1          ;
assign init_rgn_meet  = init_addr_meet && init_num_meet         ;

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)                                  init_done <= 1'b0               ;
    else if(init_rgn_meet && !read_data_buf_en) init_done <= 1'b1               ;
end

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)                                                  init_num <= {OCM_DATA_RAM_DEPTH{1'b0}}                          ;
    else if(init_start && init_addr_meet && !read_data_buf_en)  init_num <= init_num + {{(OCM_DATA_RAM_DEPTH-1){1'b0}},{1'b1}}  ;                  
end

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)                                                  init_addr <= {OCM_L_DATA_RAM_ADDR_WIDTH{1'b0}}                          ;
    else if(init_start && !init_addr_meet && !read_data_buf_en) init_addr <= init_addr + {{(OCM_L_DATA_RAM_ADDR_WIDTH-1){1'b0}},1'b1}   ;           
end

assign init_rgn = init_done ? {init_num,init_addr} : OCM_DATA_RAM_DEPTH*OCM_L_DATA_RAM_ADDR_WIDTH-1 ;

//================================================================
//===========================Dec
//================================================================
assign w_chl_hsk        = wrdy && wvld              ;
assign w_chl_hsk_last   = w_chl_hsk & wpld.wlast    ;

always@(posedge clk) begin
    if(w_chl_hsk)  w_rob_id_buf <= w_rob_id ;
end

always@(posedge clk) begin
    if(w_chl_hsk)  w_data_buf <= wpld.wdata ;
end

always@(posedge clk or negedge rst_n) begin
    if(~rst_n)              w_buf_vld <= 1'b0   ;
    else if(w_chl_hsk_last) w_buf_vld <= 1'b0   ;
    else if(w_chl_hsk)      w_buf_vld <= 1'b1   ;
end

//#TODO:w_pld_cnt needs to change but burst length is always 1'b1

//================================================================
//===========================Data Buffer Dp Sram
//================================================================ 
assign upper_ram_wr_din  = w_data_buf                    ;
assign upper_ram_wr_en   = w_chl_hsk_last && w_buf_vld   ;
assign upper_ram_wr_addr = w_rob_id_buf                  ;
assign upper_ram_rd_en   = read_data_buf_en              ;
assign upper_ram_rd_addr = read_data_buf_pld.rob_id      ;

cmn_dp_sram#(
    .DATA_WIDTH(OCM_L_DATA_RAM_DATA_WIDTH),   
    .ADDR_WIDTH(OCM_ROB_ENTRY_WIDTH      )
)u_cmn_dp_sram_upper(
    .clk   (clk                 ),
    .din   (upper_ram_wr_din    ),
    .dout  (upper_ram_rd_dout   ),
    .wren  (upper_ram_wr_en     ),
    .wraddr(upper_ram_wr_addr   ),  
    .rden  (upper_ram_rd_en     ),
    .rdaddr(upper_ram_rd_addr   )                  
);

assign lower_ram_wr_din  = wr_data_ram_pld.data                         ;
assign lower_ram_wr_en   = w_chl_hsk_last                               ;
assign lower_ram_wr_addr = w_buf_vld ? w_rob_id_buf : wr_data_buf_id    ;
assign lower_ram_rd_en   = read_data_buf_en                             ;
assign lower_ram_rd_addr = read_data_buf_pld.rob_id                     ;

cmn_dp_sram#(
    .DATA_WIDTH(OCM_L_DATA_RAM_DATA_WIDTH),   
    .ADDR_WIDTH(OCM_ROB_ENTRY_WIDTH      )
)u_cmn_dp_sram_lower(
    .clk   (clk                 ),
    .din   (lower_ram_wr_din    ),
    .dout  (lower_ram_rd_dout   ),
    .wren  (lower_ram_wr_en     ),
    .wraddr(lower_ram_wr_addr   ),  
    .rden  (lower_ram_rd_en     ),
    .rdaddr(lower_ram_rd_addr   )                  
);


assign wr_data_buf_done = w_chl_hsk_last                        ;   
assign wr_data_buf_id   = w_buf_vld ? w_rob_id_buf : w_rob_id   ;


//================================================================
//===========================Behavior
//================================================================ 
always@(posedge clk) begin
    read_data_buf_en_buf  <= read_data_buf_en           ;
end

always@(posedge clk) begin
    wr_data_ram_pld.awid  <= read_data_buf_pld.axid      ;
end

always@(posedge clk) begin
    wr_data_ram_pld.data_msk <= read_data_buf_pld.len || (init_start && !init_done) ? {2'b11}: read_data_buf_pld.len                    ;
end
assign wr_data_ram_en               = read_data_buf_en_buf || (init_start && !init_done)                                                ;
assign wr_data_ram_pld.data_ram_num = read_data_buf_en_buf ? read_data_buf_pld.data_ram_num         : init_num                          ;
assign wr_data_ram_pld.data_ram_addr= read_data_buf_en_buf ? read_data_buf_pld.data_ram_addr        : init_addr                         ;
assign wr_data_ram_pld.data         = read_data_buf_en_buf ? {upper_ram_rd_dout,lower_ram_rd_dout}  : {OCM_L_DATA_RAM_DATA_WIDTH{1'b0}} ;

endmodule