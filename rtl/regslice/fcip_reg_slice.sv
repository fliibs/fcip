

module fcip_reg_slice #(
    parameter type      PLD_TYPE = logic,
    parameter integer   RS_TYPE = 0 // 0: full, 1:forward 2: backward, other:full
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

    generate
        // forward reg slice =========================================================
        if(RS_TYPE==1) begin:rs_forward
            logic                   vld_r;
            PLD_TYPE                pld_r;

            assign s_rdy = !m_vld || m_rdy;
            assign m_vld = vld_r;
            assign m_pld = pld_r;

            always @(posedge clk or negedge rst_n) begin 
                if(~rst_n)                  vld_r <= 1'b0;
                else if(s_vld && s_rdy)     vld_r <= 1'b1;
                else if(m_rdy)              vld_r <= 1'b0;
            end 

            always @(posedge clk) begin 
                if(s_vld && s_rdy)          pld_r <= s_pld;
            end 
        end
        // backward reg slice =========================================================
        else if(RS_TYPE==2) begin:rs_backward
            logic                   vld_r; 
            PLD_TYPE                pld_r;

            assign m_vld = s_vld | vld_r;
            assign m_pld = vld_r ? pld_r : s_pld;

            always @(posedge clk or negedge rst_n) begin 
                if(~rst_n)                              vld_r <= 1'b0;
                else if(s_vld && ~vld_r && ~m_rdy)      vld_r <= 1'b1;
                else if(m_rdy)                          vld_r <= 1'b0;
            end 

            always @(posedge clk or negedge rst_n) begin 
                if(~rst_n)                              s_rdy <= 1'b1;
                else                                    s_rdy <= m_rdy;
            end

            always @(posedge clk) begin 
                if(s_vld && ~vld_r && ~m_rdy)           pld_r <= s_pld;
            end 
        end
        // full reg slice =========================================================
        // todo 这个东西的timing应该可以优化，对外的m_vld和s_rdy应该能够做到regout。
        else begin:rs_full
            PLD_TYPE pld_r [1:0];

            logic [1:0] ptr_w;
            logic [1:0] ptr_r;

            assign s_rdy = ~(ptr_w=={~ptr_r[1],ptr_r[0]}); // not full
            assign m_vld = ~(ptr_w==ptr_r); // not empty

            assign m_pld = ptr_r[0] ? pld_r[1] : pld_r[0];

            always @(posedge clk or negedge rst_n) begin 
                if(~rst_n)                  ptr_w <= 2'b0;
                else if(s_vld && s_rdy)     ptr_w <= ptr_w + 1'b1;
            end

            always @(posedge clk or negedge rst_n) begin 
                if(~rst_n)                  ptr_r <= 2'b0;
                else if(m_rdy && m_vld)     ptr_r <= ptr_r + 1'b1;
            end

            always @(posedge clk) begin 
                if(s_vld && s_rdy && (ptr_w[0]==0)) pld_r[0] <= s_pld;
            end

            always @(posedge clk) begin 
                if(s_vld && s_rdy && (ptr_w[0]==1)) pld_r[1] <= s_pld;
            end
        end

    endgenerate


endmodule