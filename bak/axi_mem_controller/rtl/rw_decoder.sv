module rw_decoder #(
    parameter AXI_ID_WIDTH   = 6,
    parameter AXI_DATA_WIDTH = 64
) (
    input  logic                       sel             ,
    input  logic                       s_dec_vld       ,
    output logic                       s_dec_rdy       , 
    input  logic                       s_dec_rw        ,
    input  logic                       s_dec_rmw       , 
    input  logic                       s_dec_axlast    , 
    input  logic [AXI_ID_WIDTH-1:0]    s_dec_axid      ,  
    input  logic [AXI_DATA_WIDTH-1:0]  s_dec_data      ,
                                                        
    output logic                       m_dec_0_vld     ,
    input  logic                       m_dec_0_rdy     , 
    output logic                       m_dec_0_rw      ,
    output logic                       m_dec_0_rmw     , 
    output logic                       m_dec_0_axlast  , 
    output logic [AXI_ID_WIDTH-1:0]    m_dec_0_axid    ,  
    output logic [AXI_DATA_WIDTH-1:0]  m_dec_0_data    ,
                                                         
    output logic                       m_dec_1_vld     ,
    input  logic                       m_dec_1_rdy     , 
    output logic                       m_dec_1_rw      ,
    output logic                       m_dec_1_rmw     , 
    output logic                       m_dec_1_axlast  , 
    output logic [AXI_ID_WIDTH-1:0]    m_dec_1_axid    ,  
    output logic [AXI_DATA_WIDTH-1:0]  m_dec_1_data    
);


    assign s_dec_rdy = sel ? m_dec_1_rdy : m_dec_0_rdy;

    assign m_dec_0_vld    = ~sel && s_dec_vld;
    assign m_dec_0_rw     = m_dec_0_vld & s_dec_rw;
    assign m_dec_0_rmw    = m_dec_0_vld & s_dec_rmw;
    assign m_dec_0_axlast = m_dec_0_vld & s_dec_axlast;
    assign m_dec_0_axid   = {AXI_ID_WIDTH{m_dec_0_vld}} & s_dec_axid;
    assign m_dec_0_data   = {AXI_DATA_WIDTH{m_dec_0_vld}} & s_dec_data;

    assign m_dec_1_vld    = sel && s_dec_vld;
    assign m_dec_1_rw     = m_dec_1_vld & s_dec_rw;
    assign m_dec_1_rmw    = m_dec_1_vld & s_dec_rmw;
    assign m_dec_1_axlast = m_dec_1_vld & s_dec_axlast;
    assign m_dec_1_axid   = {AXI_ID_WIDTH{m_dec_1_vld}} & s_dec_axid;
    assign m_dec_1_data   = {AXI_DATA_WIDTH{m_dec_1_vld}} & s_dec_data;
    
endmodule