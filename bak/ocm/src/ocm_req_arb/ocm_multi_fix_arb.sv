module cmn_multi_fix_arb 
import ocm_package::*;
(
    input   logic                           s_vld_1th_prio  ,
    output  logic                           s_rdy_1th_prio  ,
    input   pack_ocm_ax_pld                 s_pld_1th_prio  ,
    input   logic                           s_vld_2th_prio  ,
    output  logic                           s_rdy_2th_prio  ,
    input   pack_ocm_ax_pld                 s_pld_2th_prio  ,
    input   logic                           s_vld           ,
    output  logic                           s_rdy           ,
    input   pack_ocm_ax_pld                 s_pld           ,
    output  logic                           m_vld           ,
    input   logic                           m_rdy           ,
    output  pack_ocm_req_arb_ack_pld        m_pld           
);

assign m_vld           = s_vld_1th_prio | s_vld_2th_prio | s_vld                ;
assign s_rdy_1th_prio  = s_vld_1th_prio ? m_rdy : 1'b0                          ;
  
assign s_rdy_2th_prio  = s_vld_1th_prio ? 1'b0  :
                         s_vld_2th_prio ? m_rdy : 
                         1'b0                   ;
 
assign s_rdy           = s_vld_1th_prio || s_vld_2th_prio ? 1'b0    :
                         s_vld                            ? m_rdy   : 
                         1'b0                                       ;
 
assign m_pld.axpld     = s_vld_1th_prio ? s_pld_1th_prio    :
                        s_vld_2th_prio ? s_pld_2th_prio     :
                        s_pld                               ;

assign m_pld.opcode[1] = s_vld_1th_prio && s_rdy_1th_prio   ;
assign m_pld.opcode[0] = s_vld_2th_prio && s_rdy_2th_prio   ;

endmodule