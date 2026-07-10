module fcip_req_rsp_afifo_slv #(
    parameter integer unsigned SYNC_STAGE   = 3     ,
    parameter integer unsigned FIFO_DEPTH   = 16    ,
    parameter integer unsigned AUTO_CLEAR_EN= 1     ,
    parameter integer unsigned REQ_WIDTH    = 32    ,
    parameter integer unsigned RSP_WIDTH    = 32    ,
    parameter integer unsigned VT_TYPE      = 1     ,// 0: SVT, 1: LVT, 2: ULVT, 3: ELVT, 4: LVTLL, 5: ULVTLL
    localparam int unsigned REQ_SYNC_WIDTH = REQ_WIDTH+1,
    localparam int unsigned RSP_SYNC_WIDTH = RSP_WIDTH+1
)(
    input  logic                        clk,
    input  logic                        rst_n,

    //input  logic                    read_stall,
    //input  logic                    read_clear,
    //output logic                    read_full_zero,
    //output logic                    read_idle,

    // request slave interface
    input   logic                       req_s_vld       ,
    output  logic                       req_s_rdy       ,
    input   logic [REQ_WIDTH-1:0]       req_s_pld       ,
    input   logic                       req_s_last      ,

    // response master interface
    output  logic                       rsp_m_vld       ,
    input   logic                       rsp_m_rdy       ,
    output  logic [RSP_WIDTH-1:0]       rsp_m_pld       ,
    output  logic                       rsp_m_last      ,

    // request sync
    output  logic [FIFO_DEPTH-1:0]      req_wptr_async  ,
    input   logic [FIFO_DEPTH-1:0]      req_rptr_async  ,
    input   logic [FIFO_DEPTH-1:0]      req_rptr_sync   ,
    output  logic [REQ_SYNC_WIDTH:0]    req_pld_sync    ,

    // response sync
    input   logic [FIFO_DEPTH-1:0]      rsp_wptr_async  ,
    output  logic [FIFO_DEPTH-1:0]      rsp_rptr_async  ,
    output  logic [FIFO_DEPTH-1:0]      rsp_rptr_sync   ,
    input   logic [RSP_SYNC_WIDTH:0]    rsp_pld_sync    
);

logic                   rsp_full_zero;
logic                   req_full_zero;
logic                   master_full_zero;
logic [REQ_WIDTH:0]     req_s_pld_ext;

logic                   stall_buffer_vld;
logic                   stall_buffer_rdy;
logic [RSP_WIDTH:0]     stall_buffer_pld;

logic                   read_resp_vld;
logic                   read_resp_rdy;
logic [RSP_WIDTH:0]     read_resp_pld;
logic                   read_resp_last;


// request async fifo slv

assign req_s_pld_ext = {req_s_pld,req_s_last};

fcip_afifo_slv #(
    .FIFO_DEPTH     (FIFO_DEPTH),
    .DATA_WIDTH     (REQ_WIDTH+1),
    .AUTO_CLEAR_EN  (AUTO_CLEAR_EN),
    .THRESHOLD_EN   (0),
    .SYNC_STAGE     (SYNC_STAGE),
    .VT_TYPE        (VT_TYPE      )
) u_afifo_slv(
    .clk            (clk),
    .rst_n          (rst_n),

    .stall          (1'b0),
    .clear          (1'b0),
    .full_zero      (req_full_zero),

    .s_vld          (req_s_vld),
    .s_pld          (req_s_pld_ext),
    .s_rdy          (req_s_rdy),

    .almost_full    (),

    .wptr_async     (req_wptr_async),
    .rptr_async     (req_rptr_async),
    .rptr_sync      (req_rptr_sync),
    .pld_sync       (req_pld_sync)
);

// response async fifo mst

fcip_afifo_mst #(
    .FIFO_DEPTH     (FIFO_DEPTH),
    .DATA_WIDTH     (RSP_WIDTH+1),
    .AUTO_CLEAR_EN  (AUTO_CLEAR_EN),
    .THRESHOLD_EN   (0),
    .SYNC_STAGE     (SYNC_STAGE),
    .VT_TYPE        (VT_TYPE      )
) u_afifo_mst(
    .clk            (clk),
    .rst_n          (rst_n),

    .stall          (1'b0),
    .clear          (1'b0),
    .full_zero      (rsp_full_zero),
    .idle           (),

    .m_vld          (read_resp_vld),
    .m_pld          (read_resp_pld),
    .m_rdy          (read_resp_rdy),

    .almost_empty   (),

    .wptr_async     (rsp_wptr_async),
    .rptr_async     (rsp_rptr_async),
    .rptr_sync      (rsp_rptr_sync),
    .pld_sync       (rsp_pld_sync)
    );

    // transaction counter

    logic [31:0] trans_cnt;
    logic        package_req_last_handshake;
    logic        package_rsp_last_handshake;

    assign package_req_last_handshake = req_s_last && req_s_vld && req_s_rdy;
    assign package_rsp_last_handshake = rsp_m_last && rsp_m_vld && rsp_m_rdy;

    always_ff @( posedge clk or negedge rst_n ) begin
        if(~rst_n)
            trans_cnt <= 'b0;
        else if(package_rsp_last_handshake && package_req_last_handshake)
            trans_cnt <= trans_cnt;
        else if(package_rsp_last_handshake)
            trans_cnt <= trans_cnt - 1'b1;
        else if(package_req_last_handshake)
            trans_cnt <= trans_cnt + 1'b1;
    end

    // stall buffer for waiting for async fifo clear

    assign read_resp_last  = read_resp_pld[0];
    assign master_full_zero = req_full_zero && rsp_full_zero;

    fcip_reg_slice #(
        .PLD_TYPE(logic [RSP_WIDTH:0]),
        .RS_TYPE (1)
    )u_rsp_buffer(
        .clk    (clk            ),
        .rst_n  (rst_n          ),
        .s_vld  (read_resp_vld  ),
        .s_rdy  (read_resp_rdy  ),
        .s_pld  (read_resp_pld  ),
        .m_vld  (stall_buffer_vld      ),
        .m_rdy  (stall_buffer_rdy      ),
        .m_pld  (stall_buffer_pld      )
    );

    generate 
        if(AUTO_CLEAR_EN) begin

            logic buffer_enable;

            assign buffer_enable    = master_full_zero || (trans_cnt!=0);
            assign stall_buffer_rdy = rsp_m_rdy && buffer_enable;
            
            assign rsp_m_vld        = stall_buffer_vld && buffer_enable;
            assign rsp_m_pld        = stall_buffer_pld[RSP_WIDTH:1];
            assign rsp_m_last       = stall_buffer_pld[0];

        end else begin

            assign rsp_m_vld        = stall_buffer_vld;
            assign rsp_m_pld        = stall_buffer_pld[RSP_WIDTH:1];
            assign rsp_m_last       = stall_buffer_pld[0];
            assign stall_buffer_rdy = rsp_m_rdy;
            
        end

    endgenerate

endmodule