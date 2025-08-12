module read_modify_write #(
    parameter AXI_ADDR_WIDTH  = 32,
    parameter AXI_ID_WIDTH    = 6,
    parameter AXI_DATA_WIDTH  = 64,
    parameter AXI_WSTRB_WIDTH = AXI_DATA_WIDTH/8,
    parameter AXI_USER_WIDTH  = 8
    
) (
    // clk&rstn
    input logic                               clk,
    input logic                               rstn,
    // aww
    input  logic                              s_aww_vld,
    output logic                              s_aww_rdy,
    input  logic [AXI_ADDR_WIDTH-1:0]         s_aww_addr,
    input  logic [AXI_ID_WIDTH-1:0]           s_aww_id,
    input  logic [AXI_USER_WIDTH-1:0]         s_aww_user,
    input  logic [AXI_DATA_WIDTH-1:0]         s_aww_data,
    input  logic [AXI_WSTRB_WIDTH-1:0]        s_aww_strb,
    input  logic                              s_aww_last,
    // to req arb
    output logic                              m_req_vld,
    input  logic                              m_req_rdy,
    output logic                              m_req_rw,
    output logic                              m_req_rmw,
    output logic                              m_req_axlast,
    output logic [AXI_ID_WIDTH-1:0]           m_req_axid,
    output logic [AXI_USER_WIDTH-1:0]         m_req_axuser,
    output logic [AXI_ADDR_WIDTH-1:0]         m_req_axaddr,
    output logic [AXI_DATA_WIDTH-1:0]         m_req_data,
    // from rsp dec
    input  logic                              s_rsp_vld,
    output logic                              s_rsp_rdy,
    input  logic                              s_rsp_rw,
    input  logic                              s_rsp_rmw,
    input  logic                              s_rsp_axlast,
    input  logic [AXI_ID_WIDTH-1:0]           s_rsp_axid,
    input  logic [AXI_DATA_WIDTH-1:0]         s_rsp_data
);


    localparam  IDLE         = 5'b0_0001,
                DIRECT_W     = 5'b0_0010,
                RMW_R        = 5'b0_0100,
                WAIT_RMW_RD  = 5'b0_1000,
                RMW_W        = 5'b1_0000;

    logic [4:0]                  cur_state;
    logic [4:0]                  nxt_state;
    logic                        arb_req_en;
    logic                        rw_flag;  // 0:read; 1:write(default)
    logic                        rmw_req;
    logic                        axlast_flag;
    logic [AXI_ID_WIDTH-1:0]     axid_reg;
    logic [AXI_USER_WIDTH-1:0]   axuser_reg;
    logic [AXI_ADDR_WIDTH-1:0]   axaddr_reg;
    logic [AXI_DATA_WIDTH-1:0]   data_reg;
    logic [AXI_WSTRB_WIDTH-1:0]  wstrb_reg;

    logic [AXI_DATA_WIDTH-1:0]   data_mask;


    // dec rdy
    assign s_rsp_rdy   = 1'b1;

    // arb req state machine
    always_ff @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            cur_state <= IDLE;
        end else begin
            cur_state <= nxt_state;
        end
    end

    always @(*) begin
        nxt_state = IDLE;
        case (cur_state)
            IDLE: begin
                if (s_aww_vld && s_aww_rdy && &s_aww_strb) begin
                    nxt_state = DIRECT_W;
                end else if (s_aww_vld && s_aww_rdy && ~&s_aww_strb) begin
                    nxt_state = RMW_R;
                end else begin
                    nxt_state = IDLE;
                end
            end
            DIRECT_W: begin
                if (s_aww_vld && s_aww_rdy && &s_aww_strb && m_req_vld && m_req_rdy) begin
                    nxt_state = DIRECT_W;
                end else if (s_aww_vld && s_aww_rdy && ~&s_aww_strb && m_req_vld && m_req_rdy) begin
                    nxt_state = RMW_R;
                end else if (m_req_vld && m_req_rdy) begin
                    nxt_state = IDLE;
                end else begin
                    nxt_state = DIRECT_W;
                end
            end
            RMW_R: begin
                if (m_req_vld && m_req_rdy) begin
                    nxt_state = WAIT_RMW_RD;
                end else begin
                    nxt_state = RMW_R;
                end
            end
            WAIT_RMW_RD: begin
                if (s_rsp_vld && s_rsp_rdy) begin
                    nxt_state = RMW_W;
                end else begin
                    nxt_state = WAIT_RMW_RD;
                end
            end
            RMW_W: begin
                if (m_req_vld && m_req_rdy && s_aww_vld && s_aww_rdy && &s_aww_strb) begin
                    nxt_state = DIRECT_W;
                end else if (m_req_vld && m_req_rdy && s_aww_vld && s_aww_rdy && ~&s_aww_strb) begin
                    nxt_state = RMW_R;
                end else if (m_req_vld && m_req_rdy) begin
                    nxt_state = IDLE;
                end else begin
                    nxt_state = RMW_W;
                end
            end
            default: begin
                nxt_state = IDLE;
            end
        endcase
    end

    always_ff @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            // s_aww_rdy   <= 1'b1;
            arb_req_en  <= 1'b0;
            rw_flag     <= 1'b1;
            rmw_req     <= 1'b0;
            axlast_flag <= 1'b0;
            axid_reg    <= {AXI_ID_WIDTH{1'b0}};
            axuser_reg  <= {AXI_USER_WIDTH{1'b0}};
            axaddr_reg  <= {AXI_ADDR_WIDTH{1'b0}};
            data_reg    <= {AXI_DATA_WIDTH{1'b0}};
            wstrb_reg   <= {AXI_WSTRB_WIDTH{1'b0}};
        end else begin
            case (nxt_state)
                IDLE: begin
                    // s_aww_rdy   <= 1'b1;
                    arb_req_en  <= 1'b0;
                    rw_flag     <= 1'b1;
                    rmw_req     <= 1'b0;
                    axlast_flag <= 1'b0;
                    axid_reg    <= {AXI_ID_WIDTH{1'b0}};
                    axuser_reg  <= {AXI_USER_WIDTH{1'b0}};
                    axaddr_reg  <= {AXI_ADDR_WIDTH{1'b0}};
                    data_reg    <= {AXI_DATA_WIDTH{1'b0}};
                    wstrb_reg   <= {AXI_WSTRB_WIDTH{1'b0}};
                end
                DIRECT_W: begin
                    if (s_aww_vld && s_aww_rdy && &s_aww_strb) begin
                        // s_aww_rdy   <= 1'b1;
                        arb_req_en  <= 1'b1;
                        rw_flag     <= 1'b1;
                        rmw_req     <= 1'b0;
                        axlast_flag <= s_aww_last;
                        axid_reg    <= s_aww_id;
                        axuser_reg  <= s_aww_user;
                        axaddr_reg  <= s_aww_addr;
                        data_reg    <= s_aww_data;
                        wstrb_reg   <= s_aww_strb;
                    end else begin
                        // s_aww_rdy   <= 1'b0;
                        arb_req_en  <= 1'b1;
                        rw_flag     <= 1'b1;
                        rmw_req     <= 1'b0;
                        axlast_flag <= axlast_flag;
                        axid_reg    <= axid_reg;
                        axuser_reg  <= axuser_reg;
                        axaddr_reg  <= axaddr_reg;
                        data_reg    <= data_reg;
                        wstrb_reg   <= wstrb_reg;
                    end
                end
                RMW_R: begin
                    if (s_aww_vld && s_aww_rdy && ~&s_aww_strb) begin
                        // s_aww_rdy   <= 1'b0;
                        arb_req_en  <= 1'b1;
                        rw_flag     <= 1'b0;
                        rmw_req     <= 1'b1;
                        axlast_flag <= s_aww_last;
                        axid_reg    <= s_aww_id;
                        axuser_reg  <= s_aww_user;
                        axaddr_reg  <= s_aww_addr;
                        data_reg    <= s_aww_data;
                        wstrb_reg   <= s_aww_strb;
                    end else begin
                        // s_aww_rdy   <= 1'b0;
                        arb_req_en  <= 1'b1;
                        rw_flag     <= 1'b0;
                        rmw_req     <= 1'b1;
                        axlast_flag <= axlast_flag;
                        axid_reg    <= axid_reg;
                        axuser_reg  <= axuser_reg;
                        axaddr_reg  <= axaddr_reg;
                        data_reg    <= data_reg;
                        wstrb_reg   <= wstrb_reg;
                    end
                end
                WAIT_RMW_RD: begin
                    // s_aww_rdy   <= 1'b0;
                    arb_req_en  <= 1'b0;
                    rw_flag     <= 1'b0;
                    rmw_req     <= 1'b1;
                    axlast_flag <= axlast_flag;
                    axid_reg    <= axid_reg;
                    axuser_reg  <= axuser_reg;
                    axaddr_reg  <= axaddr_reg;
                    data_reg    <= data_reg;
                    wstrb_reg   <= wstrb_reg;
                end
                RMW_W: begin
                    if (s_rsp_vld && s_rsp_rdy) begin
                        // s_aww_rdy   <= 1'b0;
                        arb_req_en  <= 1'b1;
                        rw_flag     <= 1'b1;
                        rmw_req     <= 1'b1;
                        axlast_flag <= axlast_flag;
                        axid_reg    <= axid_reg;
                        axuser_reg  <= axuser_reg;
                        axaddr_reg  <= axaddr_reg;
                        data_reg    <= (data_reg & data_mask) | (s_rsp_data & ~data_mask);
                        wstrb_reg   <= wstrb_reg;
                    end else begin
                        // s_aww_rdy   <= 1'b0;
                        arb_req_en  <= 1'b1;
                        rw_flag     <= 1'b1;
                        rmw_req     <= 1'b1;
                        axlast_flag <= axlast_flag;
                        axid_reg    <= axid_reg;
                        axuser_reg  <= axuser_reg;
                        axaddr_reg  <= axaddr_reg;
                        data_reg    <= data_reg;
                        wstrb_reg   <= wstrb_reg;
                    end
                end
                default: begin
                    // s_aww_rdy   <= 1'b1;
                    arb_req_en  <= 1'b0;
                    rw_flag     <= 1'b1;
                    rmw_req     <= 1'b0;
                    axlast_flag <= 1'b0;
                    axid_reg    <= {AXI_ID_WIDTH{1'b0}};
                    axuser_reg  <= {AXI_USER_WIDTH{1'b0}};
                    axaddr_reg  <= {AXI_ADDR_WIDTH{1'b0}};
                    data_reg    <= {AXI_DATA_WIDTH{1'b0}};
                    wstrb_reg   <= {AXI_WSTRB_WIDTH{1'b0}};
                end
            endcase
        end
    end
    
    // arb req gen
    assign m_req_vld    = arb_req_en;
    assign m_req_rw     = rw_flag;
    assign m_req_rmw    = rmw_req;
    assign m_req_axlast = axlast_flag;
    assign m_req_axid   = axid_reg;
    assign m_req_axuser = rw_flag ? axuser_reg : {AXI_USER_WIDTH{1'b0}};
    assign m_req_axaddr = axaddr_reg;
    assign m_req_data   = data_reg;
    
    // s_ready
    assign s_aww_rdy = ((cur_state==DIRECT_W || cur_state==RMW_W && !m_req_rdy)
                        || cur_state==RMW_R || cur_state==WAIT_RMW_RD) ? 1'b0 : 1'b1;

    always @(*) begin
        case (AXI_DATA_WIDTH)
            64:  data_mask = {
                                {8{wstrb_reg[7]}}, {8{wstrb_reg[6]}}, {8{wstrb_reg[5]}}, {8{wstrb_reg[4]}}, 
                                {8{wstrb_reg[3]}}, {8{wstrb_reg[2]}}, {8{wstrb_reg[1]}}, {8{wstrb_reg[0]}}
                             };
            128: data_mask = {
                                {8{wstrb_reg[15]}}, {8{wstrb_reg[14]}}, {8{wstrb_reg[13]}}, {8{wstrb_reg[12]}},
                                {8{wstrb_reg[11]}}, {8{wstrb_reg[10]}}, {8{wstrb_reg[9]}},  {8{wstrb_reg[8]}}, 
                                {8{wstrb_reg[7]}},  {8{wstrb_reg[6]}},  {8{wstrb_reg[5]}},  {8{wstrb_reg[4]}}, 
                                {8{wstrb_reg[3]}},  {8{wstrb_reg[2]}},  {8{wstrb_reg[1]}},  {8{wstrb_reg[0]}}
                             };
            256: data_mask = {  
                                {8{wstrb_reg[31]}}, {8{wstrb_reg[30]}}, {8{wstrb_reg[29]}}, {8{wstrb_reg[28]}},
                                {8{wstrb_reg[27]}}, {8{wstrb_reg[26]}}, {8{wstrb_reg[25]}}, {8{wstrb_reg[24]}},
                                {8{wstrb_reg[23]}}, {8{wstrb_reg[22]}}, {8{wstrb_reg[21]}}, {8{wstrb_reg[20]}}, 
                                {8{wstrb_reg[19]}}, {8{wstrb_reg[18]}}, {8{wstrb_reg[17]}}, {8{wstrb_reg[16]}}, 
                                {8{wstrb_reg[15]}}, {8{wstrb_reg[14]}}, {8{wstrb_reg[13]}}, {8{wstrb_reg[12]}}, 
                                {8{wstrb_reg[11]}}, {8{wstrb_reg[10]}}, {8{wstrb_reg[9]}},  {8{wstrb_reg[8]}}, 
                                 {8{wstrb_reg[7]}}, {8{wstrb_reg[6]}},  {8{wstrb_reg[5]}},  {8{wstrb_reg[4]}}, 
                                {8{wstrb_reg[3]}},  {8{wstrb_reg[2]}},  {8{wstrb_reg[1]}},  {8{wstrb_reg[0]}}
                             };
            default: 
                 data_mask  = {
                                {8{wstrb_reg[7]}}, {8{wstrb_reg[6]}}, {8{wstrb_reg[5]}}, {8{wstrb_reg[4]}}, 
                                {8{wstrb_reg[3]}}, {8{wstrb_reg[2]}}, {8{wstrb_reg[1]}}, {8{wstrb_reg[0]}}
                             };
        endcase
    end

endmodule