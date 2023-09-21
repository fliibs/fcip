module mem_if_ctrl #(
    parameter AXI_ADDR_WIDTH    = 32,
    parameter AXI_ID_WIDTH      = 6,
    parameter AXI_DATA_WIDTH    = 64,
    parameter AXI_USER_WIDTH    = 8,
    parameter SRAM_R_LATENCY    = 1
) (
    input  logic                              clk,
    input  logic                              rstn,
    // from req arb
    input  logic                              s_req_valid,
    output logic                              s_req_ready,
    input  logic                              s_req_rw,
    input  logic                              s_req_rmw,
    input  logic                              s_req_axlast,
    input  logic [AXI_ID_WIDTH-1:0]           s_req_axid,
    input  logic [AXI_USER_WIDTH-1:0]         s_req_axuser, // no need temp
    input  logic [AXI_ADDR_WIDTH-1:0]         s_req_axaddr,
    input  logic [AXI_DATA_WIDTH-1:0]         s_req_data,
    // to rsp dec 
    output logic                              s_rsp_valid,
    input  logic                              s_rsp_ready,
    output logic                              s_rsp_rw,
    output logic                              s_rsp_rmw,
    output logic                              s_rsp_axlast,
    output logic [AXI_ID_WIDTH-1:0]           s_rsp_axid,
    output logic [AXI_DATA_WIDTH-1:0]         s_rsp_data,
    // mem if
    // memory in
    output logic                              m_mi_ce,
    output logic                              m_mi_we,
    output logic [AXI_ADDR_WIDTH-1:0]         m_mi_addr,
    output logic [AXI_DATA_WIDTH-1:0]         m_mi_data,
    // memory out
    input  logic [AXI_DATA_WIDTH-1:0]         m_mo_data
);
    
    localparam CTRL_WIDTH = AXI_ID_WIDTH + 1 + 1 + 1; //id+rw+rmw+last
    localparam PLD_WIDTH  = CTRL_WIDTH + AXI_DATA_WIDTH;
    localparam CNT_WIDTH  = (SRAM_R_LATENCY==1) ? 2 : $clog2(SRAM_R_LATENCY)+1;

    logic  [CTRL_WIDTH-1:0] ctrl;
    logic  [CTRL_WIDTH-1:0] ctrl_reg0;

    logic                   s_fifo_vld;
    logic                   s_fifo_rdy;
    logic [PLD_WIDTH-1:0]   s_fifo_pld;
    logic [PLD_WIDTH-1:0]   m_fifo_pld;

    logic [CNT_WIDTH-1:0]   tr_cnt;
    
    assign m_mi_ce    = s_req_valid && s_req_ready;
    assign m_mi_we    = s_req_rw;
    assign m_mi_addr  = s_req_axaddr;
    assign m_mi_data  = s_req_data;

    assign ctrl = {s_req_rw, s_req_rmw, s_req_axlast, s_req_axid};
    
    // ctrl & fifo vld depend on "SRAM_R_LATENCY"
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            ctrl_reg0 <= {CTRL_WIDTH{1'b0}};
        end else if (m_mi_ce) begin
            ctrl_reg0 <= ctrl;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            s_fifo_vld <= 1'b0;
        end else if (m_mi_ce) begin
            s_fifo_vld <= 1'b1;
        end else begin
            s_fifo_vld <= 1'b0;
        end
    end

    assign s_fifo_pld = {ctrl_reg0, m_mo_data};

    vrp_fifo #(
        .PLD_WIDTH ( PLD_WIDTH ),
        .DEPTH     ( SRAM_R_LATENCY+1 )
    ) u_mem_rsp_fifo (
        .clk   ( clk         ),
        .rst_n ( rstn        ),
        .vld_s ( s_fifo_vld  ),
        .rdy_s ( s_fifo_rdy  ),
        .pld_s ( s_fifo_pld  ),
        .vld_m ( s_rsp_valid ),
        .rdy_m ( s_rsp_ready ),
        .pld_m ( m_fifo_pld  )
    );

    assign {s_rsp_rw,s_rsp_rmw,s_rsp_axlast,s_rsp_axid,s_rsp_data} = m_fifo_pld;

    // sram access tr counter
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            tr_cnt <= {CNT_WIDTH{1'b0}};
        end else if (s_req_valid && s_req_ready && s_rsp_valid && s_rsp_ready) begin
            tr_cnt <= tr_cnt;
        end else if (s_req_valid && s_req_ready) begin
            tr_cnt <= tr_cnt + 1'b1;
        end else if (s_rsp_valid && s_rsp_ready) begin
            tr_cnt <= tr_cnt - 1'b1;
        end
    end
    
    assign s_req_ready = (tr_cnt != SRAM_R_LATENCY+1);


endmodule