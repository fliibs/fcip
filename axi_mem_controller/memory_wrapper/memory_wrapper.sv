module memory_wrapper #(
    parameter  ADDR_WIDTH     = 32,
    parameter  DATA_WIDTH     = 64,
    parameter  SIDEBAND_WIDTH = 64,
    parameter  PLD_I_WIDTH    = DATA_WIDTH + ADDR_WIDTH + SIDEBAND_WIDTH,
    parameter  PLD_O_WIDTH    = DATA_WIDTH + SIDEBAND_WIDTH,
    parameter  SRAM_R_LATENCY = 1,
    localparam CNT_WIDTH      = (SRAM_R_LATENCY==1) ? 2 : $clog2(SRAM_R_LATENCY)+1
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
    

    logic  [SIDEBAND_WIDTH-1:0] sideband;
    logic  [ADDR_WIDTH-1:0] addr;
    logic  [DATA_WIDTH-1:0] idata;
    logic  [DATA_WIDTH-1:0] odata;

    logic  ce;
    logic  we;

    logic  [SIDEBAND_WIDTH-1:0] sideband_reg;

    logic                   fifo_vld;
    logic                   fifo_rdy;
    logic [PLD_O_WIDTH-1:0] fifo_pld;

    logic [CNT_WIDTH-1:0]   tr_cnt;

    assign idata    = s_pld[DATA_WIDTH-1:0];
    assign addr     = s_pld[DATA_WIDTH+ADDR_WIDTH-1:DATA_WIDTH];
    assign sideband = s_pld[PLD_I_WIDTH-1:DATA_WIDTH+ADDR_WIDTH];

    assign ce = s_vld && s_rdy;
    assign we = s_pld[PLD_I_WIDTH];


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
            sideband_reg <= SIDEBAND_WIDTH;
        end else if (ce) begin
            sideband_reg <= sideband;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            fifo_vld <= 1'b0;
        end else if (~fifo_rdy) begin
            fifo_vld <= 1'b0;
        end else if (ce) begin
            fifo_vld <= 1'b1;
        end
    end

    assign fifo_pld = {sideband_reg,odata};

    vrp_fifo #(
        .PLD_WIDTH ( DATA_WIDTH +  SIDEBAND_WIDTH),
        .DEPTH     ( SRAM_R_LATENCY+1 )
    ) u_ar_fifo (
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
        end else if (s_vld && s_rdy) begin
            tr_cnt <= tr_cnt + 1'b1;
        end else if (m_vld && m_rdy) begin
            tr_cnt <= tr_cnt - 1'b1;
        end
    end
    
    assign s_rdy = (tr_cnt != SRAM_R_LATENCY+1);

endmodule