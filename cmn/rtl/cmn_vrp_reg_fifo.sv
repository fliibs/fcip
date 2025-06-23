module cmn_vrp_reg_fifo#(
        parameter  type             PLD_TYPE     = logic          ,
        parameter  integer unsigned ADDR_WIDTH   = 8              ,
        localparam integer unsigned PTR_WIDTH    = ADDR_WIDTH+1   ,
        localparam integer unsigned ADDR_DEPTH   = 1 << ADDR_WIDTH
    )(
        input  logic                        clk         ,
        input  logic                        rst_n       ,

        input  logic                        in_vld      , // write channel
        output logic                        in_rdy      , // write channel
        input  PLD_TYPE                     in_pld      , // write channel

        output logic                        out_vld     , // read channel
        input  logic                        out_rdy     , // read channel
        output PLD_TYPE                     out_pld       // read channel
    );


    //=====================================
    // internal signals
    //=====================================
    PLD_TYPE                               v_entry [ADDR_DEPTH-1:0];
    logic    [PTR_WIDTH-1:0]               wr_ptr              ;
    logic    [PTR_WIDTH-1:0]               rd_ptr              ;
    logic    [ADDR_WIDTH-1:0]              wr_addr             ;
    logic    [ADDR_WIDTH-1:0]              rd_addr             ;

    logic                                  empty               ;
    logic                                  full                ;

    //=====================================
    // interface 
    //=====================================
    assign in_rdy = ~full;

    assign out_pld = v_entry[rd_addr];
    assign out_vld = ~empty;

    //=====================================
    // pointer
    //=====================================
    assign wr_addr = wr_ptr[ADDR_WIDTH-1:0]                 ;
    assign rd_addr = rd_ptr[ADDR_WIDTH-1:0]                 ;
    assign empty   = wr_ptr == rd_ptr                       ;
    assign full    = (wr_ptr[PTR_WIDTH-1] != rd_ptr[PTR_WIDTH-1])&& (wr_ptr[PTR_WIDTH-2:0] == rd_ptr[PTR_WIDTH-2:0]);

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)                      wr_ptr <= {PTR_WIDTH{1'b0}}                         ;
        else if(in_vld&&in_rdy)         wr_ptr <= {{(PTR_WIDTH-1){1'b0}},{1'b1}} + wr_ptr   ;
    end

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)                      rd_ptr <= {PTR_WIDTH{1'b0}}                         ;
        else if(out_vld&&out_rdy)       rd_ptr <= {{(PTR_WIDTH-1){1'b0}},{1'b1}} + rd_ptr   ;
    end

    //=====================================
    // entry
    //=====================================
    genvar i;
    generate
        for(i=0;i<ADDR_DEPTH;i++) begin
            always@(posedge clk)begin
                if((wr_addr==i) && !full)    v_entry[i] <= in_pld  ;
            end
        end
    endgenerate


endmodule