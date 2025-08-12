module reg_slice #(
    parameter RS_TYPE   = 0,  // 0: Pass Through 1: Forward 2: Backward 3:Full
    parameter PLD_WIDTH = 32
)(
    input                       clk,
    input                       rst_n,

    input                       s_vld,
    output                      s_rdy,
    input   [PLD_WIDTH-1:0]     s_pld,

    output                      m_vld,
    input                       m_rdy,
    output  [PLD_WIDTH-1:0]     m_pld

);

generate
    if(RS_TYPE==0) begin //Pass Through
        assign s_rdy = m_rdy;
        assign m_vld = s_vld;
        assign m_pld = s_pld;
    
    end else if(RS_TYPE==1) begin //Forward

        logic                   vld_r;
        logic [PLD_WIDTH-1:0]   pld_r;

        assign s_rdy = !m_vld || m_rdy;
        assign m_vld = vld_r;
        assign m_pld = pld_r;

        always @(posedge clk or negedge rst_n) begin 
            if(~rst_n) vld_r <= 1'b0;
            else if(s_vld&&s_rdy) vld_r <= 1'b1;
            else if(m_rdy) vld_r <= 1'b0;
        end 

        always @(posedge clk or negedge rst_n) begin 
            if(~rst_n) pld_r <= {PLD_WIDTH{1'b0}};
            else if(s_vld&&s_rdy) pld_r <= s_pld;
        end 

    end else if(RS_TYPE==2) begin // Backward
        logic                   vld_r;
        logic [PLD_WIDTH-1:0]   pld_r;

        assign s_rdy = !m_vld || m_rdy;
        assign m_vld = vld_r;
        assign m_pld = pld_r;

        always @(posedge clk or negedge rst_n) begin 
            if(~rst_n) vld_r <= 1'b0;
            else if(s_vld&&s_rdy) vld_r <= 1'b1;
            else if(m_rdy) vld_r <= 1'b0;
        end 

        always @(posedge clk or negedge rst_n) begin 
            if(~rst_n) pld_r <= {PLD_WIDTH{1'b0}};
            else if(s_vld&&s_rdy) pld_r <= s_pld;
        end 

    end else if(RS_TYPE==3) begin // Full
        logic [PLD_WIDTH-1:0] pld_r [1:0];
        logic [1:0] pntr_w;
        logic [1:0] pntr_r;

        assign s_rdy = ~(pntr_w=={~pntr_r[1],pntr_r[0]}); // not full
        assign m_vld = ~(pntr_w==pntr_r); // not empty

        assign m_pld = pntr_r[0] ? pld_r[1] : pld_r[0];

        always @(posedge clk or negedge rst_n) begin 
            if(~rst_n) pntr_w <= 2'b0;
            else if(s_vld&&s_rdy) pntr_w <= pntr_w + 1'b1;
        end

        always @(posedge clk or negedge rst_n) begin 
            if(~rst_n) pntr_r <= 2'b0;
            else if(m_rdy&&m_vld) pntr_r <= pntr_r + 1'b1;
        end

        always @(posedge clk or negedge rst_n) begin 
            if(~rst_n) pld_r[0] <= {PLD_WIDTH{1'b0}};
            else if(s_vld&&s_rdy&&(pntr_w[0]==0)) pld_r[0] <= s_pld;
        end

        always @(posedge clk or negedge rst_n) begin 
            if(~rst_n) pld_r[1] <= {PLD_WIDTH{1'b0}};
            else if(s_vld&&s_rdy&&(pntr_w[1]==1)) pld_r[1] <= s_pld;
        end

    end else begin // Full
        logic [PLD_WIDTH-1:0] pld_r [1:0];
        logic [1:0] pntr_w;
        logic [1:0] pntr_r;

        assign s_rdy = ~(pntr_w=={~pntr_r[1],pntr_r[0]}); // not full
        assign m_vld = ~(pntr_w==pntr_r); // not empty

        assign m_pld = pntr_r[0] ? pld_r[1] : pld_r[0];

        always @(posedge clk or negedge rst_n) begin 
            if(~rst_n) pntr_w <= 2'b0;
            else if(s_vld&&s_rdy) pntr_w <= pntr_w + 1'b1;
        end

        always @(posedge clk or negedge rst_n) begin 
            if(~rst_n) pntr_r <= 2'b0;
            else if(m_rdy&&m_vld) pntr_r <= pntr_r + 1'b1;
        end

        always @(posedge clk or negedge rst_n) begin 
            if(~rst_n) pld_r[0] <= {PLD_WIDTH{1'b0}};
            else if(s_vld&&s_rdy&&(pntr_w[0]==0)) pld_r[0] <= s_pld;
        end

        always @(posedge clk or negedge rst_n) begin 
            if(~rst_n) pld_r[1] <= {PLD_WIDTH{1'b0}};
            else if(s_vld&&s_rdy&&(pntr_w[1]==1)) pld_r[1] <= s_pld;
        end

    end 
endgenerate


endmodule