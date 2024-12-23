module cmn_sram_fifo#(
        parameter  type             PLD_TYPE               = logic          ,
        parameter  integer unsigned ADDR_WIDTH             = 8              ,
        localparam integer unsigned PTR_WIDTH              = ADDR_WIDTH+1
    )(
        input  logic                        clk         ,
        input  logic                        rst_n       ,

        input  logic                        vld_s       , // read channel
        output logic                        rdy_s       , // read channel
        input  PLD_TYPE                     pld_s       , // read channel

        output logic                        vld_m       , // write channel
        input  logic                        rdy_m       , // write channel
        output PLD_TYPE                     pld_m         // write channel
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

    //=====================================
    // interface 
    //=====================================
    assign rdy_s = ~full;

    assign pld_m = rd_data;
    assign vld_m = rden_s1;

    //=====================================
    // pointer
    //=====================================
    assign wr_addr = wr_ptr[ADDR_WIDTH-1:0]                 ;
    assign rd_addr = rd_ptr[ADDR_WIDTH-1:0]                 ;
    assign full    = wr_ptr == rd_ptr                       ;
    assign empty   = (wr_ptr[PTR_WIDTH-1] != rd_ptr[PTR_WIDTH-1])&& (wr_ptr[PTR_WIDTH-2:0] == rd_ptr[PTR_WIDTH-2:0]);
    assign wren    = vld_s  && rdy_s;
    assign rden    = ~empty && rdy_m;

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
    cmn_dual_mem_model #(
        .ADDR_WIDTH(ADDR_WIDTH              ),
        .DATA_WIDTH($bits(PLD_TYPE)         )
    ) u_entry (
        .clk    (clk                        ),
        .wr_en  (wren                       ),
        .wr_addr(wr_addr                    ),
        .wr_data(pld_s                      ),
        .rd_en  (rden                       ),
        .rd_addr(rd_addr                    ),
        .rd_data(rd_data                    )
    );


endmodule