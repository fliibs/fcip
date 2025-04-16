module cmn_vrp_sram_fifo#(
        parameter  type             PLD_TYPE               = logic          ,
        parameter  integer unsigned ADDR_WIDTH             = 8              ,
        localparam integer unsigned PTR_WIDTH              = ADDR_WIDTH+1
    )(
        input  logic                        clk          ,
        input  logic                        rst_n        ,

        input  logic                        in_vld       , // write channel
        output logic                        in_rdy       , // write channel
        input  PLD_TYPE                     in_pld       , // write channel

        output logic                        out_vld      , // read channel
        input  logic                        out_rdy      , // read channel
        output PLD_TYPE                     out_pld      , // read channel

        output logic                        mem_wr_en   ,
        output logic    [ADDR_WIDTH-1:0]    mem_wr_addr ,
        output PLD_TYPE                     mem_wr_data ,

        output logic                        mem_rd_en   ,
        output logic    [ADDR_WIDTH-1:0]    mem_rd_addr ,
        input  PLD_TYPE                     mem_rd_data
    );

    //=====================================
    // internal signals
    //=====================================
    logic [PTR_WIDTH-1:0]               wr_ptr              ;
    logic [PTR_WIDTH-1:0]               rd_ptr              ;
    logic [ADDR_WIDTH-1:0]              wr_addr             ;
    logic [ADDR_WIDTH-1:0]              rd_addr             ;

    logic                               wren                ;
    logic                               rden                ;
    logic                               rden_s1             ;
    PLD_TYPE                            rd_data             ;

    logic                               empty               ;
    logic                               full                ;

    logic                               s_rs_vld            ;
    logic                               s_rs_rdy            ;
    PLD_TYPE                            s_rs_pld            ;
    logic                               m_rs_vld            ;
    logic                               m_rs_rdy            ;
    PLD_TYPE                            m_rs_pld            ;

    //=====================================
    // interface 
    //=====================================
    assign in_rdy = ~full;

    assign out_pld = m_rs_vld ? m_rs_pld : rd_data;
    assign out_vld = m_rs_vld || rden_s1;

    //=====================================
    // reg slice
    //=====================================
    assign s_rs_vld = rden_s1 && (m_rs_vld||~out_rdy);
    assign s_rs_pld = rd_data;

    assign m_rs_rdy = out_rdy;

    cmn_reg_slice_forward #(
        .PLD_TYPE(PLD_TYPE)
    ) u_fwd_rs0 (
        .clk(clk),
        .rst_n(rst_n),
        .s_vld(s_rs_vld),
        .s_rdy(s_rs_rdy),
        .s_pld(s_rs_pld),
        .m_vld(m_rs_vld),
        .m_rdy(m_rs_rdy),
        .m_pld(m_rs_pld)
    );

    //=====================================
    // pointer
    //=====================================
    assign wr_addr = wr_ptr[ADDR_WIDTH-1:0]                 ;
    assign rd_addr = rd_ptr[ADDR_WIDTH-1:0]                 ;
    assign full    = (wr_ptr[PTR_WIDTH-1] != rd_ptr[PTR_WIDTH-1])&& (wr_ptr[PTR_WIDTH-2:0] == rd_ptr[PTR_WIDTH-2:0])                       ;
    assign empty   = wr_ptr == rd_ptr ;
    assign wren    = in_vld  && in_rdy;
    assign rden    = ~empty && (out_rdy||(~rden_s1&&~m_rs_vld));

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)                  wr_ptr <= {PTR_WIDTH{1'b0}}                         ;
        else if(wren)               wr_ptr <= {{(PTR_WIDTH-1){1'b0}},{1'b1}} + wr_ptr   ;
    end

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)                  rd_ptr <= {PTR_WIDTH{1'b0}}                         ;
        else if(rden)               rd_ptr <= {{(PTR_WIDTH-1){1'b0}},{1'b1}} + rd_ptr   ;
    end

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)                  rden_s1 <= 1'b0                                     ;
        else                        rden_s1 <= rden                                     ;
    end

    //=====================================
    // sram
    //=====================================
    assign mem_wr_en     = wren   ;
    assign mem_wr_addr   = wr_addr ;
    assign mem_wr_data   = in_pld ;

    assign mem_rd_en     = rden    ;
    assign mem_rd_addr   = rd_addr  ;
    assign rd_data     = mem_rd_data;

    // cmn_dual_mem_model #(
    //     .ADDR_WIDTH(ADDR_WIDTH              ),
    //     .DATA_WIDTH($bits(PLD_TYPE)         )
    // ) u_entry (
    //     .clk    (clk                        ),
    //     .wr_en  (wren                       ),
    //     .wr_addr(wr_addr                    ),
    //     .wr_data(in_pld                      ),
    //     .rd_en  (rden                       ),
    //     .rd_addr(rd_addr                    ),
    //     .rd_data(rd_data                    )
    // );


endmodule