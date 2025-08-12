module cmn_fifo#(
    parameter  integer unsigned DATA_WIDTH = 8              ,
    parameter  integer unsigned ADDR_WIDTH = 8              ,
    localparam integer unsigned PTR_WIDTH  = ADDR_WIDTH+1   ,
    localparam integer unsigned ADDR_DEPTH = 1 << ADDR_WIDTH          
)(
    input  logic                        clk         ,
    input  logic                        rst_n       ,
    input  logic                        wr_en       ,
    input  logic                        rd_en       ,
    input  logic [DATA_WIDTH-1:0]       wr_data     ,
    output logic [DATA_WIDTH-1:0]       rd_data     ,
    output logic                        empty       ,
    output logic                        full    
);
//=====================================
//=============internal signals========
//=====================================
    logic [DATA_WIDTH-1:0]              data[ADDR_DEPTH-1:0];
    logic [PTR_WIDTH-1:0]               wr_ptr              ;
    logic [PTR_WIDTH-1:0]               rd_ptr              ;
    logic [ADDR_WIDTH-1:0]              wr_addr             ;
    logic [ADDR_WIDTH-1:0]              rd_addr             ;
    logic [ADDR_DEPTH-1:0]              wr_addr_ohot        ;
    logic [ADDR_DEPTH-1:0]              rd_addr_ohot        ;

//=====================================
//=============behavior================
//=====================================
    assign wr_addr = wr_ptr[ADDR_WIDTH-1:0]                 ;
    assign rd_addr = rd_ptr[ADDR_WIDTH-1:0]                 ;
    assign full    = wr_ptr == rd_ptr                       ;
    assign empty   = (wr_ptr[PTR_WIDTH-1] != rd_ptr[PTR_WIDTH-1])&& (wr_ptr[PTR_WIDTH-2:0] == rd_ptr[PTR_WIDTH-2:0]);

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)                  wr_ptr <= {PTR_WIDTH{1'b0}}                         ;
        else if(wr_en&&!full)       wr_ptr <= {{(PTR_WIDTH-1){1'b0}},{1'b1}} + wr_ptr   ;
    end

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)                  rd_ptr <= {PTR_WIDTH{1'b0}}                         ;
        else if(rd_en&&!empty)      rd_ptr <= {{(PTR_WIDTH-1){1'b0}},{1'b1}} + rd_ptr   ;
    end
    
    genvar i;

    generate
        for(i=0;i<ADDR_DEPTH;i=i+1)begin : WR_ADDR_BIN2OH
            assign wr_addr_ohot[i]    =   (wr_addr == i[ADDR_WIDTH-1:0]);
        end
    endgenerate

    generate
        for(i=0;i<ADDR_DEPTH;i=i+1)begin : RD_ADDR_BIN2OH
            assign rd_addr_ohot[i]    =   (rd_addr == i[ADDR_WIDTH-1:0]);
        end
    endgenerate

    generate for(i=0;i<ADDR_DEPTH;i++) begin
        always@(posedge clk)begin
            if(wr_addr_ohot[i] && !full)    data[i] <= wr_data  ;
        end
    end
    endgenerate

    always_comb begin
        for(int i=0;i<ADDR_DEPTH;i++) begin
            if(rd_addr_ohot[i]) begin
                rd_data = data[i];
            end
        end
    end
endmodule