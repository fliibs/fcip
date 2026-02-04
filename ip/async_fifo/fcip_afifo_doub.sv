module fcip_afifo_doub #(
    parameter integer unsigned  FIFO_DEPTH              = 16,
    parameter integer unsigned  DATA_WIDTH              = 16,
    parameter integer unsigned  AUTO_CLEAR_EN           = 0,
    parameter integer unsigned  THRESHOLD_EN            = 0,
    parameter integer unsigned  ALMOST_FULL_THRESHOLD   = 12,
    parameter integer unsigned  ALMOST_EMPTY_THRESHOLD  = 4,
    parameter integer unsigned  SYNC_STAGE              = 2,
    parameter integer unsigned  DOUBLE_DATA_WIRE        = 1,
    parameter integer unsigned  VT_TYPE                 = 1 // 0: SVT, 1: LVT, 2: ULVT, 3: ELVT, 4: LVTLL, 5: ULVTLL
)(
    input  logic                    wclk           ,
    input  logic                    rclk           ,
    input  logic                    wrst_n         ,
    input  logic                    rrst_n         ,

    //power down
    input  logic                    read_stall     ,
    input  logic                    write_stall    ,
    input  logic                    read_clear     ,
    input  logic                    write_clear    ,

    output logic                    read_full_zero ,
    output logic                    write_full_zero,

    output logic                    read_idle           ,

    //threshold port
    output logic                    almost_empty,
    output logic                    almost_full,

    //s port
    input  logic                    s_vld  ,
    input  logic [DATA_WIDTH-1:0]   s_pld  ,
    output logic                    s_rdy  ,

    //m port
    output logic                    m_vld  ,
    output logic [DATA_WIDTH-1:0]   m_pld  ,
    input  logic                    m_rdy
);

logic [FIFO_DEPTH-1:0]   wptr_async;
logic [FIFO_DEPTH-1:0]   rptr_async;
logic [FIFO_DEPTH-1:0]   rptr_sync;
logic [(DOUBLE_DATA_WIRE ? (DATA_WIDTH*2+1) : DATA_WIDTH):0]     pld_sync;

fcip_afifo_slv_doub #(
    .FIFO_DEPTH             (FIFO_DEPTH   ),
    .DATA_WIDTH             (DATA_WIDTH   ),
    .AUTO_CLEAR_EN          (AUTO_CLEAR_EN),
    .THRESHOLD_EN           (THRESHOLD_EN ),
    .ALMOST_FULL_THRESHOLD  (ALMOST_FULL_THRESHOLD),
    .SYNC_STAGE             (SYNC_STAGE   ),
    .DOUBLE_DATA_WIRE       (DOUBLE_DATA_WIRE),
    .VT_TYPE                (VT_TYPE      )
) u_afifo_slv_doub (
    .clk           (wclk           ),
    .rst_n         (wrst_n         ),

    .stall         (write_stall    ),
    .clear         (write_clear    ),
    .full_zero     (write_full_zero),

    .s_vld         (s_vld          ),
    .s_pld         (s_pld          ),
    .s_rdy         (s_rdy          ),

    .almost_full   (almost_full    ),

    .wptr_async    (wptr_async     ),
    .rptr_async    (rptr_async     ),
    .rptr_sync     (rptr_sync      ),
    .pld_sync      (pld_sync       )
);

fcip_afifo_mst_doub #(
    .FIFO_DEPTH             (FIFO_DEPTH   ),
    .DATA_WIDTH             (DATA_WIDTH   ),
    .AUTO_CLEAR_EN          (AUTO_CLEAR_EN),
    .THRESHOLD_EN           (THRESHOLD_EN ),
    .ALMOST_EMPTY_THRESHOLD (ALMOST_EMPTY_THRESHOLD),
    .SYNC_STAGE             (SYNC_STAGE   ),
    .DOUBLE_DATA_WIRE       (DOUBLE_DATA_WIRE),
    .VT_TYPE                (VT_TYPE      )
) u_afifo_mst_doub (
    .clk           (rclk           ),
    .rst_n         (rrst_n         ),

    .stall         (read_stall     ),
    .clear         (read_clear     ),
    .full_zero     (read_full_zero ),
    .idle          (read_idle      ),

    .m_vld         (m_vld          ),
    .m_pld         (m_pld          ),
    .m_rdy         (m_rdy          ),

    .almost_empty  (almost_empty   ),

    .wptr_async    (wptr_async     ),
    .rptr_async    (rptr_async     ),
    .rptr_sync     (rptr_sync      ),
    .pld_sync      (pld_sync       )
);

endmodule