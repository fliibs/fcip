module fcip_reg_slice_full_set #(
    parameter type PLD_TYPE = logic
)(
    input                       clk,
    input                       rst_n,
    input                       set, //Synchronous reset signal

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
    
    logic [63:0] cnt;
    always @(posedge clk or negedge rst_n) begin 
        if(~rst_n) cnt <= 'b0;
        else if(s_vld&&s_rdy) cnt <= cnt + 1'b1;
    end 

    logic [1:0] pntr_w_tmp;
    logic [1:0] pntr_r_tmp;
    always @(posedge clk or negedge rst_n) begin 
        if(~rst_n) pntr_w_tmp <= 2'b0;
        else if(set) pntr_w_tmp <= 2'b0;
        else if(s_vld&&s_rdy) pntr_w_tmp <= pntr_w + 1'b1;
    end
    assign pntr_w = pntr_w_tmp & {~set, ~set};
    
    always @(posedge clk or negedge rst_n) begin 
        if(~rst_n) pntr_r_tmp <= 2'b0;
        else if(set) pntr_r_tmp <= 2'b0;
        else if(m_rdy&&m_vld) pntr_r_tmp <= pntr_r + 1'b1;
    end
    assign pntr_r = pntr_r_tmp & {~set, ~set};

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
