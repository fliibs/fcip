module cmn_vrp_sram_fifo_delay #(
        parameter type             PLD_TYPE   = logic,
        parameter integer unsigned ADDR_WIDTH = 8,
        parameter integer unsigned FIFO_DEPTH = 2**ADDR_WIDTH,
        parameter integer unsigned DELAY_CYCLE= 3,
        parameter integer unsigned PTR_WIDTH  = ADDR_WIDTH+1
    )(
        input  logic                     clk,
        input  logic                     rst_n,

        input  logic                     in_vld,
        output logic                     in_rdy,
        input  PLD_TYPE                  in_pld,

        output logic                     out_vld,
        input  logic                     out_rdy,
        output PLD_TYPE                  out_pld,

        output logic                     mem_wr_en,
        output logic    [ADDR_WIDTH-1:0] mem_wr_addr,
        output PLD_TYPE                  mem_wr_data,

        output logic                     mem_rd_en,
        output logic    [ADDR_WIDTH-1:0] mem_rd_addr,
        input  PLD_TYPE                  mem_rd_data
    );

    logic    [PTR_WIDTH-1:0]   wr_ptr;
    logic    [PTR_WIDTH-1:0]   rd_ptr;
    logic    [ADDR_WIDTH-1:0]  wr_addr;
    logic    [ADDR_WIDTH-1:0]  rd_addr;

    logic                      wren;
    logic                      rden;
    logic    [DELAY_CYCLE-1:0] rden_s1;
    PLD_TYPE                   rd_data;

    logic                      empty;
    logic                      full;

    logic    [DELAY_CYCLE-1:0] s_rs_vld;
    logic    [DELAY_CYCLE-1:0] s_rs_rdy;
    PLD_TYPE                   s_rs_pld [DELAY_CYCLE-1:0];
    logic    [DELAY_CYCLE-1:0] m_rs_vld;
    logic    [DELAY_CYCLE-1:0] m_rs_rdy;
    PLD_TYPE                   m_rs_pld [DELAY_CYCLE-1:0];

    assign in_rdy = ~full;

    assign out_pld = m_rs_pld[DELAY_CYCLE-1];
    assign out_vld = m_rs_vld[DELAY_CYCLE-1];

    generate
        for(genvar i=0; i<DELAY_CYCLE; i=i+1) begin: GEN_RS
            if(DELAY_CYCLE==1) begin 
                assign s_rs_vld[i]   = rden_s1[DELAY_CYCLE-1];
                assign s_rs_pld[i]   = mem_rd_data;
                assign m_rs_rdy[i]   = out_rdy;
            end
            else if(i==0) begin
                assign s_rs_vld[i]   = rden_s1[DELAY_CYCLE-1];
                assign s_rs_pld[i]   = mem_rd_data;
                assign m_rs_rdy[i]   = s_rs_rdy[i+1];
            end
            else if(i==(DELAY_CYCLE-1)) begin
                assign s_rs_vld[i]   = m_rs_vld[i-1];
                assign s_rs_pld[i]   = m_rs_pld[i-1];
                assign m_rs_rdy[i]   = out_rdy;
            end
            else begin
                assign s_rs_vld[i]   = m_rs_vld[i-1];
                assign s_rs_pld[i]   = m_rs_pld[i-1];
                assign m_rs_rdy[i]   = s_rs_rdy[i-1];
            end

            cmn_reg_slice_backward #(
                .PLD_TYPE(PLD_TYPE)
            ) u_bwd_rs (
                .clk  (clk        ),
                .rst_n(rst_n      ),
                .s_vld(s_rs_vld[i]),
                .s_rdy(s_rs_rdy[i]),
                .s_pld(s_rs_pld[i]),
                .m_vld(m_rs_vld[i]),
                .m_rdy(m_rs_rdy[i]),
                .m_pld(m_rs_pld[i])
            );
        end
    endgenerate


    assign wr_addr = wr_ptr[ADDR_WIDTH-1:0];
    assign rd_addr = rd_ptr[ADDR_WIDTH-1:0];
    assign full    = (wr_ptr[PTR_WIDTH-1] != rd_ptr[PTR_WIDTH-1]) && (wr_ptr[PTR_WIDTH-2:0] == rd_ptr[PTR_WIDTH-2:0]);
    assign empty   = wr_ptr == rd_ptr;
    assign wren    = in_vld && in_rdy;
    assign rden    = ~empty && (out_rdy && s_rs_rdy[0]);

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                          wr_ptr <= {PTR_WIDTH{1'b0}};
        else if(wren) begin
            if(wr_addr==(FIFO_DEPTH-1))     wr_ptr <= {~wr_ptr[PTR_WIDTH-1], {(PTR_WIDTH-1){1'b0}}};
            else                            wr_ptr <= {{(PTR_WIDTH-1){1'b0}}, 1'b1} + wr_ptr;
        end
    end


    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                          rd_ptr <= {PTR_WIDTH{1'b0}};
        else if(rden) begin
            if(rd_addr==(FIFO_DEPTH-1))     rd_ptr <= {~rd_ptr[PTR_WIDTH-1], {(PTR_WIDTH-1){1'b0}}};
            else                            rd_ptr <= {{(PTR_WIDTH-1){1'b0}}, 1'b1} + rd_ptr;
        end
    end

    generate
        for(genvar i=0; i<DELAY_CYCLE; i=i+1) begin: GEN_RD_DELAY
            if(i==0) begin
                always_ff @(posedge clk or negedge rst_n) begin
                    if(~rst_n)              rden_s1[i] <= 1'b0;
                    else                    rden_s1[i] <= rden;
                end
            end
            else begin
                always_ff @(posedge clk or negedge rst_n) begin
                    if(~rst_n)              rden_s1[i] <= 1'b0;
                    else                    rden_s1[i] <= rden_s1[i-1];
                end
            end
        end
    endgenerate

    assign mem_wr_en   = wren;
    assign mem_wr_addr = wr_addr;
    assign mem_wr_data = in_pld;

    assign mem_rd_en   = rden;
    assign mem_rd_addr = rd_addr;
    assign rd_data     = mem_rd_data;

endmodule