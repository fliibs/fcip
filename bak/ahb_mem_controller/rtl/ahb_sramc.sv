module ahb_sramc #(
    parameter  AHB_DATA_WIDTH    = 64,
    parameter  SRAM_R_LATENCY    = 1,  // It should be no more than 8 
    parameter  HAS_NARROW_TR     = 1,
    localparam DATA_STRB_WIDTH   = AHB_DATA_WIDTH/8
) (
    // clk&rstn
    input logic                               clk,
    input logic                               rstn,
    // ahb slave interface 
    input  logic                              s_hsel,
    
    input  logic [31:0]                       s_haddr,
    input  logic                              s_hwrite,
    input  logic [1:0]                        s_htrans,
    input  logic [2:0]                        s_hsize,
    input  logic [2:0]                        s_hburst,
    input  logic [3:0]                        s_hprot,     // TBD
    input  logic                              s_hmastlock, // no use for single mst
    input  logic                              s_hreadyin,

    input  logic [AHB_DATA_WIDTH-1:0]         s_hwdata,

    output logic [AHB_DATA_WIDTH-1:0]         s_hrdata,
    output logic                              s_hreadyout,
    output logic                              s_hresp,
    // memory wrapper master interface
    // memory in
    output logic                              m_mi_ce,
    output logic                              m_mi_we,
    output logic [31:0]                       m_mi_addr,
    output logic [AHB_DATA_WIDTH-1:0]         m_mi_data,
    // memory out
    input  logic [AHB_DATA_WIDTH-1:0]         m_mo_data,
    // Reg
    output logic                              ahb_sramc_idle

);

    localparam IDLE   = 2'b00,
               BUSY   = 2'b01,
               NONSEQ = 2'b10,
               SEQ    = 2'b11;
    
    logic is_narrow_tr;

    logic direct_r;
    logic direct_w;
    logic rmw_r;
    logic rmw_w;

    logic new_tr_en;
    logic new_w_tr;
    
    logic [31:0] haddr_buf;
    logic [2:0]  hsize_buf;

    logic [31:0] addr_unaligned;
    logic [31:0] addr_aligned;
    
    logic [DATA_STRB_WIDTH-1:0] wdata_strb;
    logic [AHB_DATA_WIDTH-1:0]  rmw_data_mask;
    logic [AHB_DATA_WIDTH-1:0]  rmw_rdata;

    // ahb sramc idle
    assign ahb_sramc_idle = (~s_hsel || ~m_mi_ce) && s_hreadyout;

    assign new_tr_en = s_hsel && s_hreadyin && (s_htrans == NONSEQ || s_htrans == SEQ) && s_hreadyout;

    assign direct_r = new_tr_en && !s_hwrite;

    assign direct_w = new_w_tr; // write delay 1 cycle

    assign rmw_r = new_tr_en && s_hwrite && is_narrow_tr;

    // ctrl signal buf
    always_ff @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            haddr_buf <= 32'h0;
            hsize_buf <= 3'h0;
          end else if (new_tr_en) begin
            haddr_buf <= s_haddr;
            hsize_buf <= s_hsize;
          end
    end

    always_ff @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            new_w_tr   <= 1'b0;
          end else if (new_tr_en && s_hwrite) begin
            new_w_tr   <= 1'b1;
          end else begin
            new_w_tr   <= 1'b0;
          end
    end

    assign addr_unaligned = new_tr_en ? s_haddr : haddr_buf;

     // transfer addr aligned for sram
    generate
        if (AHB_DATA_WIDTH == 32) begin: ADDR_ALIGNED32
            assign addr_aligned = {addr_unaligned[31:2], 2'h0};
        end else if (AHB_DATA_WIDTH == 64) begin: ADDR_ALIGNED64
            assign addr_aligned = {addr_unaligned[31:3], 3'h0};
        end else if (AHB_DATA_WIDTH == 128) begin: ADDR_ALIGNED128
            assign addr_aligned = {addr_unaligned[31:4], 4'h0};
        end else if (AHB_DATA_WIDTH == 256) begin: ADDR_ALIGNED256
            assign addr_aligned = {addr_unaligned[31:5], 5'h0};
        end else begin: ADDR_ALIGNED32_DEFAULT
            assign addr_aligned = {addr_unaligned[31:2], 2'h0};
        end
    endgenerate

    // sram ctrl if gen
    assign m_mi_ce = direct_r || direct_w || rmw_r || rmw_w;
    
    always_comb begin
        if (direct_r) begin
            m_mi_we   = 1'b0;
            m_mi_addr = addr_aligned;
            m_mi_data = {AHB_DATA_WIDTH{1'b0}};
        end else if (new_w_tr) begin
            m_mi_we   = 1'b1;
            m_mi_addr = addr_aligned;
            m_mi_data = s_hwdata;
        end else if (rmw_r) begin
            m_mi_we   = 1'b0;
            m_mi_addr = addr_aligned;
            m_mi_data = {AHB_DATA_WIDTH{1'b0}};
        end else if (rmw_w) begin
            m_mi_we   = 1'b1;
            m_mi_addr = addr_aligned;
            m_mi_data = (s_hwdata & rmw_data_mask) | (rmw_rdata & ~rmw_data_mask);
        end else begin
            m_mi_we   = s_hwrite;
            m_mi_addr = addr_aligned;
            m_mi_data = {AHB_DATA_WIDTH{1'b0}};
        end
    end

    // ahb resp gen
    assign s_hresp = 1'b1; // the resp is always OKAY

    generate 
        if (SRAM_R_LATENCY==0) begin: SRAM_R_LATENCY_ZERO

            assign s_hreadyout = 1'b1;

            always_ff @(posedge clk or negedge rstn) begin
                if (~rstn) begin
                    s_hrdata <= {AHB_DATA_WIDTH{1'b0}};
                end else begin
                    s_hrdata <= m_mo_data;
                end
            end

            assign rmw_rdata = s_hrdata;

            always_ff @(posedge clk or negedge rstn) begin
                if (~rstn) begin
                    rmw_w <= 1'b0;
                end else if (rmw_r) begin
                    rmw_w <= 1'b1;
                end else begin
                    rmw_w <= 1'b0;
                end
            end
        end else begin: SRAM_R_LATENCY_GREATER_ZERO
            localparam DELAY_CNT_WIDTH = $clog2(SRAM_R_LATENCY) + 1;
            logic [DELAY_CNT_WIDTH-1:0] delay_cnt;
            logic [2*DELAY_CNT_WIDTH-1:0] double_delay_cnt;

            always_ff @(posedge clk or negedge rstn) begin
                if (~rstn) begin
                    delay_cnt <= {DELAY_CNT_WIDTH{1'b0}};
                end else if (m_mi_ce && ~direct_w) begin
                    delay_cnt <= SRAM_R_LATENCY-1;
                end else if (new_tr_en && s_hwrite) begin // direct_w addr phase
                    delay_cnt <= SRAM_R_LATENCY;
                end else if (|delay_cnt) begin
                    delay_cnt <= delay_cnt - 1'b1;
                end
            end

            always_ff @(posedge clk or negedge rstn) begin
                if (~rstn) begin
                    double_delay_cnt <= {2*DELAY_CNT_WIDTH{1'b0}};
                end else if (rmw_r) begin
                    double_delay_cnt <= 2*SRAM_R_LATENCY-1;
                end else if (|double_delay_cnt) begin
                    double_delay_cnt <= double_delay_cnt - 1'b1;
                end
            end
            
            always_ff @(posedge clk or negedge rstn) begin
                if (~rstn) begin
                    rmw_w <= 1'b0;
                end else if (delay_cnt=='d1 || (SRAM_R_LATENCY==1 && rmw_r)) begin
                    rmw_w <= 1'b1;
                end else begin
                    rmw_w <= 1'b0;
                end
            end

            always_ff @(posedge clk or negedge rstn) begin
                if (~rstn) begin
                    rmw_rdata <= {AHB_DATA_WIDTH{1'b0}};
                end else if (rmw_w) begin
                    rmw_rdata <= s_hrdata;
                end
            end

            assign s_hreadyout = ~|delay_cnt && ~|double_delay_cnt;
            assign s_hrdata    = m_mo_data;
        end
    endgenerate

    // data mask calculate
    generate
        if (HAS_NARROW_TR==1) begin: NARROW_MODE
            localparam BIN_WIDTH = $clog2(AHB_DATA_WIDTH)-3;

            assign is_narrow_tr = {s_hsize[2:0],3'h0} != AHB_DATA_WIDTH;

            case (AHB_DATA_WIDTH)
                32: begin: DATA_WIDTH32
                    always_comb begin
                        case (hsize_buf[2:0])
                            3'b000: begin
                                wdata_strb[DATA_STRB_WIDTH-1:0] = {DATA_STRB_WIDTH{1'b0}};
                                wdata_strb[haddr_buf[BIN_WIDTH-1:0]+:1] = 1'b1;
                            end
                            3'b001: begin
                                wdata_strb[DATA_STRB_WIDTH-1:0] = {DATA_STRB_WIDTH{1'b0}};
                                wdata_strb[haddr_buf[BIN_WIDTH-1:0]+:2] = 2'b11;
                            end
                            default: wdata_strb[DATA_STRB_WIDTH-1:0] = {DATA_STRB_WIDTH{1'b0}};
                        endcase
                    end

                    assign rmw_data_mask = {
                                            {8{wdata_strb[3]}}, {8{wdata_strb[2]}}, {8{wdata_strb[1]}}, {8{wdata_strb[0]}}
                                           };
                end
                64: begin: DATA_WIDTH64
                    always_comb begin
                        case (hsize_buf[2:0])
                            3'b000: begin
                                wdata_strb[DATA_STRB_WIDTH-1:0] = {DATA_STRB_WIDTH{1'b0}};
                                wdata_strb[haddr_buf[BIN_WIDTH-1:0]+:1] = 1'b1;
                            end
                            3'b001: begin
                                wdata_strb[DATA_STRB_WIDTH-1:0] = {DATA_STRB_WIDTH{1'b0}};
                                wdata_strb[haddr_buf[BIN_WIDTH-1:0]+:2] = 2'b11;
                            end
                            3'b010: begin
                                wdata_strb[DATA_STRB_WIDTH-1:0] = {DATA_STRB_WIDTH{1'b0}};
                                wdata_strb[haddr_buf[BIN_WIDTH-1:0]+:4] = 4'b1111;
                            end 
                            default: wdata_strb[DATA_STRB_WIDTH-1:0] = {DATA_STRB_WIDTH{1'b0}};
                        endcase
                    end

                    assign rmw_data_mask = {
                                            {8{wdata_strb[7]}}, {8{wdata_strb[6]}}, {8{wdata_strb[5]}}, {8{wdata_strb[4]}},
                                            {8{wdata_strb[3]}}, {8{wdata_strb[2]}}, {8{wdata_strb[1]}}, {8{wdata_strb[0]}}
                                           };
                end
                128: begin: DATA_WIDTH128
                    always_comb begin
                        wdata_strb = (DATA_STRB_WIDTH)'(0);
                        case (hsize_buf[2:0])
                            3'b000: begin
                                wdata_strb[DATA_STRB_WIDTH-1:0] = {DATA_STRB_WIDTH{1'b0}};
                                wdata_strb[haddr_buf[BIN_WIDTH-1:0]+:1] = 1'b1;
                            end
                            3'b001: begin
                                wdata_strb[DATA_STRB_WIDTH-1:0] = {DATA_STRB_WIDTH{1'b0}};
                                wdata_strb[haddr_buf[BIN_WIDTH-1:0]+:2] = 2'b11;
                            end
                            3'b010: begin
                                wdata_strb[DATA_STRB_WIDTH-1:0] = {DATA_STRB_WIDTH{1'b0}};
                                wdata_strb[haddr_buf[BIN_WIDTH-1:0]+:4] = 4'b1111;
                            end
                            3'b011: begin
                                wdata_strb[DATA_STRB_WIDTH-1:0] = {DATA_STRB_WIDTH{1'b0}};
                                wdata_strb[haddr_buf[BIN_WIDTH-1:0]+:8] = 8'b1111_1111;
                            end
                            default: wdata_strb[DATA_STRB_WIDTH-1:0] = {DATA_STRB_WIDTH{1'b0}};
                        endcase
                    end

                    assign rmw_data_mask = {
                                            {8{wdata_strb[15]}}, {8{wdata_strb[14]}}, {8{wdata_strb[13]}}, {8{wdata_strb[12]}},
                                            {8{wdata_strb[11]}}, {8{wdata_strb[10]}}, {8{wdata_strb[9]}}, {8{wdata_strb[8]}},
                                            {8{wdata_strb[7]}}, {8{wdata_strb[6]}}, {8{wdata_strb[5]}}, {8{wdata_strb[4]}},
                                            {8{wdata_strb[3]}}, {8{wdata_strb[2]}}, {8{wdata_strb[1]}}, {8{wdata_strb[0]}}
                                           };
                end
                256: begin: DATA_WIDTH256
                    always_comb begin
                        wdata_strb = (DATA_STRB_WIDTH)'(0);
                        case (hsize_buf[2:0])
                            3'b000: begin
                                wdata_strb[DATA_STRB_WIDTH-1:0] = {DATA_STRB_WIDTH{1'b0}};
                                wdata_strb[haddr_buf[BIN_WIDTH-1:0]+:1] = 1'b1;
                            end
                            3'b001: begin
                                wdata_strb[DATA_STRB_WIDTH-1:0] = {DATA_STRB_WIDTH{1'b0}};
                                wdata_strb[haddr_buf[BIN_WIDTH-1:0]+:2] = 2'b11;
                            end
                            3'b010: begin
                                wdata_strb[DATA_STRB_WIDTH-1:0] = {DATA_STRB_WIDTH{1'b0}};
                                wdata_strb[haddr_buf[BIN_WIDTH-1:0]+:4] = 4'b1111;
                            end
                            3'b011: begin
                                wdata_strb[DATA_STRB_WIDTH-1:0] = {DATA_STRB_WIDTH{1'b0}};
                                wdata_strb[haddr_buf[BIN_WIDTH-1:0]+:8] = 8'b1111_1111;
                            end
                            3'b100: begin
                                wdata_strb[DATA_STRB_WIDTH-1:0] = {DATA_STRB_WIDTH{1'b0}};
                                wdata_strb[haddr_buf[BIN_WIDTH-1:0]+:16] = 16'b1111_1111_1111_1111;
                            end
                            default: wdata_strb[DATA_STRB_WIDTH-1:0] = {DATA_STRB_WIDTH{1'b0}};
                        endcase
                    end

                    assign rmw_data_mask = {
                                            {8{wdata_strb[31]}}, {8{wdata_strb[30]}}, {8{wdata_strb[29]}}, {8{wdata_strb[28]}},
                                            {8{wdata_strb[27]}}, {8{wdata_strb[26]}}, {8{wdata_strb[25]}}, {8{wdata_strb[24]}},
                                            {8{wdata_strb[23]}}, {8{wdata_strb[22]}}, {8{wdata_strb[21]}}, {8{wdata_strb[20]}}, 
                                            {8{wdata_strb[19]}}, {8{wdata_strb[18]}}, {8{wdata_strb[17]}}, {8{wdata_strb[16]}}, 
                                            {8{wdata_strb[15]}}, {8{wdata_strb[14]}}, {8{wdata_strb[13]}}, {8{wdata_strb[12]}},
                                            {8{wdata_strb[11]}}, {8{wdata_strb[10]}}, {8{wdata_strb[9]}}, {8{wdata_strb[8]}},
                                            {8{wdata_strb[7]}}, {8{wdata_strb[6]}}, {8{wdata_strb[5]}}, {8{wdata_strb[4]}},
                                            {8{wdata_strb[3]}}, {8{wdata_strb[2]}}, {8{wdata_strb[1]}}, {8{wdata_strb[0]}}
                                           };
                end
                default: begin: DATA_WIDTH32_DEFAULT
                    always_comb begin
                        case (hsize_buf[2:0])
                            3'b000: begin
                                wdata_strb[DATA_STRB_WIDTH-1:0] = {DATA_STRB_WIDTH{1'b0}};
                                wdata_strb[haddr_buf[BIN_WIDTH-1:0]+:1] = 1'b1;
                            end
                            3'b001: begin
                                wdata_strb[DATA_STRB_WIDTH-1:0] = {DATA_STRB_WIDTH{1'b0}};
                                wdata_strb[haddr_buf[BIN_WIDTH-1:0]+:2] = 2'b11;
                            end
                            default: wdata_strb[DATA_STRB_WIDTH-1:0] = {DATA_STRB_WIDTH{1'b0}};
                        endcase
                    end

                    assign rmw_data_mask = {
                                            {8{wdata_strb[3]}}, {8{wdata_strb[2]}}, {8{wdata_strb[1]}}, {8{wdata_strb[0]}}
                                           };
                end
            endcase
        end else begin: NONNARROW_MODE
            assign is_narrow_tr = 1'b0;
            assign rmw_data_mask = {AHB_DATA_WIDTH{1'b1}};
        end
    endgenerate

endmodule