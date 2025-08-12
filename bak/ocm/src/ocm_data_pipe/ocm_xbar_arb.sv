module ocm_xbar_v_arb
import ocm_package::*;
(
    input  logic                                            v_wr_data_ram_en      ,
    input  pack_ocm_rob_ack_pld                             v_wr_data_ram_pld     ,  
    input  logic [OCM_DATA_RAM_UNENC_DATA_WIDTH-1:0]        v_wr_data_ram_data    ,                 
               
    input  logic                                            v_rd_data_ram_en      ,               
    input  pack_ocm_rob_ack_pld                             v_rd_data_ram_pld     ,
    output pack_ocm_ram_wrapper_in_pld                      v_ram_wrapper_in_pld  ,
    output logic [OCM_DATA_RAM_UNENC_DATA_WIDTH-1:0]        v_ram_wrapper_din     
);
//===================================
//=================internal signals
//===================================
logic  init_en;
assign init_en = v_rd_data_ram_en &&  (v_rd_data_ram_pld.opcode == 2'b00); 
//===================================
//=================behavior arbiter
//===================================
assign v_ram_wrapper_in_pld.addr                 = v_wr_data_ram_en ? v_wr_data_ram_pld.ram_addr        : v_rd_data_ram_pld.ram_addr        ;
assign v_ram_wrapper_in_pld.en                   = v_wr_data_ram_en || v_rd_data_ram_en                                                     ;
assign v_ram_wrapper_in_pld.wr                   = v_wr_data_ram_en                                                                         ;
assign v_ram_wrapper_in_pld.ram_bps_pld.id       = v_wr_data_ram_en ? v_wr_data_ram_pld.ram_bps_pld.id  : v_rd_data_ram_pld.ram_bps_pld.id  ;
//===================================
//=================data arbiter
//===================================
assign v_ram_wrapper_din = init_en ? {OCM_DATA_RAM_UNENC_DATA_WIDTH{1'b0}} : v_wr_data_ram_data    ;
endmodule