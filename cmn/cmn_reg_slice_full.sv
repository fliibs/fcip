module cmn_reg_slice_full #(
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

    PLD_TYPE pld_r [1:0];

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

    genvar i;
    generate
        for(i=0;i<2;i=i+1) begin: reg_num
            always @(posedge clk or negedge rst_n) begin 
                if(~rst_n) pld_r[i] <= {$bits(PLD_TYPE){1'b0}};
                else if(s_vld&&s_rdy&&(pntr_w[0]==i)) pld_r[i] <= s_pld;
            end
        end 
    endgenerate




endmodule   