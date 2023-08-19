module ecc_decoder #(
    parameter AXI_ID_WIDTH      = 6,
    parameter AXI_DATA_WIDTH    = 64,
    parameter ECC_DATA_WIDTH    = 64 + 7 + 1
) (
    input  logic                         s_ecc_vld,
    output logic                         s_ecc_rdy,
    input  logic                         s_ecc_rw,
    input  logic                         s_ecc_rmw,
    input  logic                         s_ecc_axlast,
    input  logic [AXI_ID_WIDTH-1:0]      s_ecc_axid,
    input  logic [ECC_DATA_WIDTH-1:0]    s_ecc_data,

    output logic                         m_ecc_vld,
    input  logic                         m_ecc_rdy,
    output logic                         m_ecc_rw,
    output logic                         m_ecc_rmw,
    output logic                         m_ecc_axlast,
    output logic [AXI_ID_WIDTH-1:0]      m_ecc_axid,
    output logic [AXI_DATA_WIDTH-1:0]    m_ecc_data,

    output logic                         ecc_err

);

    logic [ECC_DATA_WIDTH-1:0]  ecc_decoded_data;

    hamming_secded_decoder #(
        .INFO_WIDTH ( AXI_DATA_WIDTH )
    ) u_hamming_ecc_decoder(
        .encoded_bits ( s_ecc_data       ),
        .info_bits    ( ecc_decoded_data ),
        .fatal_err    ( ecc_err          )
    );

    assign m_ecc_vld     = s_ecc_vld;
    assign s_ecc_rdy     = m_ecc_rdy;
    
    assign m_ecc_data    = ~s_ecc_rw ? ecc_decoded_data : {AXI_DATA_WIDTH{1'b0}};   // w req no data rsp

    assign m_ecc_rw      = s_ecc_rw;
    assign m_ecc_rmw     = s_ecc_rmw;
    assign m_ecc_axlast  = s_ecc_axlast;
    assign m_ecc_axid    = s_ecc_axid;
    assign m_ecc_axuser  = s_ecc_axuser;
    assign m_ecc_axaddr  = s_ecc_axaddr;

    
endmodule