module transfer_split #(
    parameter AXI_ADDR_WIDTH  = 32,
    parameter AXI_ID_WIDTH    = 6,
    parameter AXI_DATA_WIDTH  = 64,
    parameter AXI_USER_WIDTH  = 8
) (  
    // clk&rstn
    input logic                               clk,
    input logic                               rstn,
    // axi tr
    input  logic                              s_vld,
    output logic                              s_rdy,
    input  logic [AXI_ADDR_WIDTH-1:0]         s_addr,
    input  logic [AXI_ID_WIDTH-1:0]           s_id,
    input  logic [7:0]                        s_len,
    input  logic [2:0]                        s_size,
    input  logic [1:0]                        s_burst,
    input  logic [AXI_USER_WIDTH-1:0]         s_user,
    // split tr
    output logic                              m_vld,
    input  logic                              m_rdy,
    output logic                              m_last,
    output logic [AXI_ID_WIDTH-1:0]           m_id,
    output logic [AXI_USER_WIDTH-1:0]         m_user,
    output logic [AXI_ADDR_WIDTH-1:0]         m_addr
);
    // next address calculate function
    function automatic logic [AXI_ADDR_WIDTH-1:0] nxt_addr_calc(input logic [AXI_ADDR_WIDTH-1:0] addr, logic [7:0] len, input logic [2:0] size, input logic [1:0] burst);
        logic [AXI_ADDR_WIDTH-1:0] aligned_addr;
        logic [AXI_ADDR_WIDTH-1:0] wrap_boundary;
        logic [AXI_ADDR_WIDTH-1:0] upper_wrap_addr;
        logic [3:0]                wrap_shift;
        logic [AXI_ADDR_WIDTH:0]   addr_temp;
        logic [AXI_ADDR_WIDTH-1:0] axi_addr_calc;

        aligned_addr  = (addr >> size) << size;

        if (burst == 2'b10) begin
            if (len == 8'd2) begin
                wrap_shift = size + 3'd1;
            end else if (len == 8'd4) begin
                wrap_shift = size + 3'd2;
            end else if (len == 8'd8) begin
                wrap_shift = size + 3'd3;
            end else begin
                wrap_shift = size + 3'd4;
            end 
        end else begin
            wrap_shift = 4'b0;
        end

        if (burst == 2'b10) begin
            wrap_boundary   = (addr >> wrap_shift ) << wrap_shift;
            upper_wrap_addr = wrap_boundary + (16'b1 << wrap_shift);
        end else begin
            wrap_boundary   = {AXI_ADDR_WIDTH{1'b0}};
            upper_wrap_addr = {AXI_ADDR_WIDTH{1'b0}};
        end

        addr_temp =  aligned_addr + {8'b1 << size};

        // axi burst addr split
        if (burst == 2'b10 && addr_temp == upper_wrap_addr) begin
            axi_addr_calc = wrap_boundary[AXI_ADDR_WIDTH-1:0];
        end else if (burst == 2'b10 || burst == 2'b01) begin
            axi_addr_calc = addr_temp[AXI_ADDR_WIDTH-1:0];
        end else begin
            axi_addr_calc = addr;
        end

        // sram data width aligned
        if (AXI_DATA_WIDTH == 64) begin
            nxt_addr_calc = {axi_addr_calc[AXI_ADDR_WIDTH-1:3], 3'h0};
        end else (AXI_DATA_WIDTH == 128) begin
            nxt_addr_calc = {axi_addr_calc[AXI_ADDR_WIDTH-1:4], 4'h0};
        end else (AXI_DATA_WIDTH == 256) begin
            nxt_addr_calc = {axi_addr_calc[AXI_ADDR_WIDTH-1:5], 5'h0};
        end else begin
            nxt_addr_calc = {axi_addr_calc[AXI_ADDR_WIDTH-1:3], 3'h0};
        end
    endfunction




    logic [8:0] burst_len;
    logic [7:0] burst_cnt;

    logic [AXI_ADDR_WIDTH-1:0]         s_addr_q;
    logic [AXI_ID_WIDTH-1:0]           s_id_q;
    logic [7:0]                        s_len_q;
    logic [2:0]                        s_size_q;
    logic [1:0]                        s_burst_q;
    logic [AXI_USER_WIDTH-1:0]         s_user_q;

    logic [AXI_ADDR_WIDTH-1:0] addr_reg;

    assign burst_len = s_len + 1'b1;

    assign s_rdy = (burst_cnt == 8'h0);

    always_ff @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            burst_cnt <= 8'h0;
        end else if (m_vld && m_rdy) begin
            burst_cnt <= burst_cnt - 1'b1;
        end else if (s_vld && s_rdy) begin
            burst_cnt <= burst_len;
        end
    end
    
    always_ff @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            s_addr_q  <= {AXI_ADDR_WIDTH{1'b0}};
            s_id_q    <= {AXI_ID_WIDTH{1'b0}};
            s_len_q   <= 8'h0;
            s_size_q  <= 3'h0;
            s_burst_q <= 2'h0;
            s_user_q  <= {AXI_USER_WIDTH{1'b0}};
        end else if (s_vld && s_rdy) begin
            s_addr_q  <= s_addr;
            s_id_q    <= s_id;
            s_len_q   <= s_len;
            s_size_q  <= s_size;
            s_burst_q <= s_burst;
            s_user_q  <= s_user;
        end
    end

    always_ff @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            addr_reg <= {AXI_ADDR_WIDTH{1'b0}};
        end else if (m_vld && m_rdy) begin
            addr_reg <= nxt_addr_calc(addr_reg, s_len_q, s_size_q, s_burst_q);
        end else if (s_vld && s_rdy) begin
            addr_reg <= nxt_addr_calc(s_addr, burst_len, s_size, s_burst);
        end
    end
    
    assign m_vld   = |burst_cnt;
    assign m_last = (burst_cnt == 8'b1);
    assign m_id   = s_id_q;
    assign m_user = s_user_q;
    assign m_addr = (s_vld && s_rdy) ? s_addr : addr_reg;


endmodule