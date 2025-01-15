module ocm_req_arb
    import ocm_package::*;
(   
    input  logic                                clk                 ,
    input  logic                                rst_n               ,
    //ar
    input  logic                                arvld               ,
    output logic                                arrdy               ,
    input  pack_ocm_ar_pld                      arpld               ,
    //aw
    input  logic                                awvld               ,
    output logic                                awrdy               ,
    input  pack_ocm_aw_pld                      awpld               ,
    //rob
    input  logic [OCM_ROB_ENTRY_WIDTH-1:0]      rob_id              ,
    input  logic                                rob_id_vld          ,
    output logic                                rob_id_rdy          , 
    //w
    input  logic                                wvld                ,
    input  logic                                wlast               ,
    output logic                                wrdy                ,
    output logic [OCM_ROB_ENTRY_WIDTH-1:0]      w_rob_id            ,
    //output to hzd check and behavior map
    output pack_ocm_ax_pld                      axpld               ,
    output logic                                axvld               ,
    //init
    // input  logic                               init              ,
    input  logic [OCM_AXI_ADDR_WIDTH-1:0]      init_rgn 
);
//==================================================
//=============internal signals=====================
//==================================================
//---------fifo signals 
    logic                               w_idle                  ;
    logic                               id_fifo_axi_w_chl_en    ;

    logic                               id_fifo_empty           ;
    logic                               id_fifo_full            ;
    logic                               id_fifo_wr_en           ;
    logic                               id_fifo_rd_en           ;
    logic [OCM_ROB_ENTRY_WIDTH-1:0]     id_fifo_wr_data         ;
    logic [OCM_ROB_ENTRY_WIDTH-1:0]     id_fifo_rd_data         ;

//---------fifo signals 
    logic                               w_chl_fifo_empty        ;
    logic                               w_chl_fifo_wr_en        ;
    logic                               w_chl_fifo_rd_en        ;
    logic [OCM_ROB_ENTRY_WIDTH-1:0]     w_chl_fifo_wr_data      ;
    logic [OCM_ROB_ENTRY_WIDTH-1:0]     w_chl_fifo_rd_data      ;
//--------arbiter signals
//--------behavior
    logic                               aw_under_init_rgn       ;
    logic                               ar_under_init_rgn       ;
//==================================================
//=============FIFO=================================
//==================================================
    assign rob_id_rdy           = !id_fifo_full                             ;
    assign id_fifo_axi_w_chl_en = wvld && w_idle                            ;
    
    assign id_fifo_wr_en        = rob_id_vld && rob_id_rdy                  ;
    assign id_fifo_rd_en        = arvld || awvld || id_fifo_axi_w_chl_en    ;

    assign id_fifo_wr_data      = rob_id                                    ;

    cmn_fifo#(
        .DATA_WIDTH(OCM_ROB_ENTRY_WIDTH ),
        .ADDR_WIDTH(2                   )
    )u_rob_id_fifo(
        .clk         (clk               ),
        .rst_n       (rst_n             ),
        .wr_en       (id_fifo_wr_en     ),
        .rd_en       (id_fifo_rd_en     ),
        .wr_data     (id_fifo_wr_data   ),
        .rd_data     (id_fifo_rd_data   ),
        .empty       (id_fifo_empty     ),
        .full        (id_fifo_full      )
    );

    assign w_chl_fifo_wr_en   = id_fifo_axi_w_chl_en && (!awvld) && (!id_fifo_empty);
    assign w_chl_fifo_rd_en   = awvld && !w_chl_fifo_empty                          ;
    assign w_chl_fifo_wr_data = id_fifo_rd_data                                     ;
    
    cmn_fifo#(
        .DATA_WIDTH(OCM_ROB_ENTRY_WIDTH ),
        .ADDR_WIDTH(2                   )
    )u_w_chl_fifo(
        .clk         (clk               ),
        .rst_n       (rst_n             ),
        .wr_en       (w_chl_fifo_wr_en  ),
        .rd_en       (w_chl_fifo_rd_en  ),
        .wr_data     (w_chl_fifo_wr_data),
        .rd_data     (w_chl_fifo_rd_data),
        .empty       (w_chl_fifo_empty  ),
        .full        (w_chl_fifo_full   )
    );
    assign w_rob_id = id_fifo_rd_data ;
//==================================================
//=============Arbiter==============================
//==================================================
    //#TODO current arbiter logic:aw/w>ar,change arbiter logic to ar>w/aw, check the enviroment;
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)               w_idle <= 1'b1;
        else if(wvld && !wlast)  w_idle <= 1'b0;
        else if(wvld && wlast)   w_idle <= 1'b1; 
    end

    always_comb begin
        if(awvld) begin
            axpld.rob_id                                          = w_chl_fifo_empty? id_fifo_rd_data : w_chl_fifo_rd_data;
            axpld.op_is_rd                                        = 1'b0                                                  ;
            axpld[$bits(pack_ocm_ax_pld)-1:OCM_ROB_ENTRY_WIDTH+1] = awpld                                                 ;   
        end
        // else if(arrdy && !id_fifo_axi_w_chl_en) begin
        else begin
            axpld.rob_id                                          = id_fifo_rd_data                                       ;
            axpld.op_is_rd                                        = 1'b1                                                  ;
            axpld[$bits(pack_ocm_ax_pld)-1:OCM_ROB_ENTRY_WIDTH+1] = arpld                                                 ;    
        end
    end
//==================================================
//=============Behavior=============================
//==================================================
    assign aw_under_init_rgn = awpld.awaddr <= init_rgn                                                               ;
    assign ar_under_init_rgn = arpld.araddr <= init_rgn                                                               ;
    assign axvld             = (arvld && arrdy && ar_under_init_rgn) && (awvld && awrdy && aw_under_init_rgn)         ; 
    assign awrdy             = !id_fifo_empty || !w_chl_fifo_empty                                                    ;
    assign arrdy             = !id_fifo_empty && !(awvld||id_fifo_axi_w_chl_en)                                       ;  
    assign wrdy              = (!id_fifo_empty || !w_chl_fifo_empty) || !w_idle                                       ;                                              
endmodule 