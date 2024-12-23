module cmn_reg_fifo#(
        parameter  type             PLD_TYPE     = logic          ,
        parameter  integer unsigned ADDR_WIDTH   = 8              ,
        localparam integer unsigned PTR_WIDTH    = ADDR_WIDTH+1   ,
        localparam integer unsigned ADDR_DEPTH   = 1 << ADDR_WIDTH
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
    assign rdy_s = ~full;

    assign pld_m = v_entry[rd_addr];
    assign vld_m = ~empty;

    //=====================================
    // pointer
    //=====================================
    assign wr_addr = wr_ptr[ADDR_WIDTH-1:0]                 ;
    assign rd_addr = rd_ptr[ADDR_WIDTH-1:0]                 ;
    assign full    = wr_ptr == rd_ptr                       ;
    assign empty   = (wr_ptr[PTR_WIDTH-1] != rd_ptr[PTR_WIDTH-1])&& (wr_ptr[PTR_WIDTH-2:0] == rd_ptr[PTR_WIDTH-2:0]);

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)                  wr_ptr <= {PTR_WIDTH{1'b0}}                         ;
        else if(vld_s&&rdy_s)       wr_ptr <= {{(PTR_WIDTH-1){1'b0}},{1'b1}} + wr_ptr   ;
    end

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)                  rd_ptr <= {PTR_WIDTH{1'b0}}                         ;
        else if(vld_m&&rdy_m)       rd_ptr <= {{(PTR_WIDTH-1){1'b0}},{1'b1}} + rd_ptr   ;
    end

    //=====================================
    // entry
    //=====================================
    genvar i;
    generate
        for(i=0;i<ADDR_DEPTH;i++) begin
            always@(posedge clk)begin
                if((wr_addr==i) && !full)    v_entry[i] <= pld_s  ;
            end
        end
    endgenerate


endmodule