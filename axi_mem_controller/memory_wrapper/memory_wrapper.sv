module memory_wrapper #(
    parameter  ADDR_WIDTH      = 32,
    parameter  DATA_WIDTH      = 64,
    parameter  AXI_USER_WIDTH  = 8,
    parameter  CTRL_WIDTH      = 64,
    parameter  PLD_I_WIDTH     = CTRL_WIDTH + AXI_USER_WIDTH + ADDR_WIDTH + DATA_WIDTH,
    parameter  PLD_O_WIDTH     = CTRL_WIDTH + DATA_WIDTH,
    parameter  SRAM_R_LATENCY  = 1,
    localparam CNT_WIDTH       = (SRAM_R_LATENCY==1) ? 2 : $clog2(SRAM_R_LATENCY)+1
) (
    input   logic                     clk,
    input   logic                     rstn,
    input   logic                     s_vld,
    output  logic                     s_rdy,
    input   logic [PLD_I_WIDTH-1:0]   s_pld,
    output  logic                     m_vld,
    input   logic                     m_rdy,
    output  logic [PLD_O_WIDTH-1:0]   m_pld
);
    

    logic  [CTRL_WIDTH-1:0] ctrl;
    logic  [AXI_USER_WIDTH-1:0] user;
    logic  [ADDR_WIDTH-1:0] addr;
    logic  [DATA_WIDTH-1:0] idata;
    logic  [DATA_WIDTH-1:0] odata;

    logic  ce;
    logic  we;

    logic  [CTRL_WIDTH-1:0] ctrl_reg;

    logic                   fifo_vld;
    logic                   fifo_rdy;
    logic [PLD_O_WIDTH-1:0] fifo_pld;

    logic [CNT_WIDTH-1:0]   tr_cnt;

    assign idata    = s_pld[DATA_WIDTH-1:0];
    assign addr     = s_pld[DATA_WIDTH+ADDR_WIDTH-1:DATA_WIDTH];
    assign user     = s_pld[DATA_WIDTH+ADDR_WIDTH+AXI_USER_WIDTH-1:DATA_WIDTH+ADDR_WIDTH];
    assign ctrl     = s_pld[PLD_I_WIDTH-1:DATA_WIDTH+ADDR_WIDTH+AXI_USER_WIDTH];

    assign ce = s_vld && s_rdy;
    assign we = s_pld[PLD_I_WIDTH-1];


    single_port_sram #( 
        .AW ( ADDR_WIDTH ),
        .DW ( DATA_WIDTH )
    ) u_single_port_sram(
        .clk  ( clk   ),  
        .ce   ( ce    ),  
        .we   ( we    ),  
        .addr ( addr  ),   
        .din  ( idata ), 
        .dout ( odata )  
    );

    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            ctrl_reg <= {CTRL_WIDTH{1'b0}};
        end else if (ce) begin
            ctrl_reg <= ctrl;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            fifo_vld <= 1'b0;
        end else if (~fifo_rdy) begin
            fifo_vld <= 1'b0;
        end else if (ce) begin
            fifo_vld <= 1'b1;
        end else begin
            fifo_vld <= 1'b0;
        end
    end

    assign fifo_pld = {ctrl_reg,odata};

    vrp_fifo #(
        .PLD_WIDTH ( DATA_WIDTH +  CTRL_WIDTH),
        .DEPTH     ( SRAM_R_LATENCY+1 )
    ) u_sram_fifo (
        .clk   ( clk      ),
        .rst_n ( rstn     ),
        .vld_s ( fifo_vld ),
        .rdy_s ( fifo_rdy ),
        .pld_s ( fifo_pld ),
        .vld_m ( m_vld    ),
        .rdy_m ( m_rdy    ),
        .pld_m ( m_pld    )
    );
    
    // sram access tr counter
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            tr_cnt <= {CNT_WIDTH{1'b0}};
        end else if (s_vld && s_rdy && m_vld && m_rdy) begin
            tr_cnt <= tr_cnt;
        end else if (s_vld && s_rdy) begin
            tr_cnt <= tr_cnt + 1'b1;
        end else if (m_vld && m_rdy) begin
            tr_cnt <= tr_cnt - 1'b1;
        end
    end
    
    assign s_rdy = (tr_cnt != SRAM_R_LATENCY+2);

endmodule