module cmn_reg_slice_backward #(
    parameter type PLD_TYPE = logic
)(
    input                       clk,
    input                       rst_n,

    input   logic               s_vld,
    output  logic               s_rdy,
    input   PLD_TYPE            s_pld,

    output  logic               m_vld,
    input   logic               m_rdy,
    output  PLD_TYPE            m_pld

);

    logic                   vld_r; 
    PLD_TYPE                pld_r;

    assign m_vld = s_vld | vld_r;
    assign m_pld = vld_r ? pld_r : s_pld;

    always @(posedge clk or negedge rst_n) begin 
        if(~rst_n)                              vld_r <= 1'b0;
        else if(s_vld && ~vld_r && ~m_rdy)      vld_r <= 1'b1;
        else if(m_rdy)                          vld_r <= 1'b0;
    end 

    always @(posedge clk) begin 
        else if(s_vld && ~vld_r && ~m_rdy)      pld_r <= s_pld;
    end 

    always @(posedge clk or negedge rst_n) begin 
        if(~rst_n)                              s_rdy <= 1'b1;
        else                                    s_rdy <= m_rdy;
    end

endmodule  