module ocm_rob_age_matrix
import ocm_package::*;
(
    input  logic                                                    clk           ,
    input  logic                                                    rst_n         ,
    input  logic                                                    axen          ,
    input  logic [OCM_ROB_ENTRY_NUM-1:0]                            v_update_en   ,
    output logic [OCM_ROB_ENTRY_NUM-1:0] [OCM_ROB_ENTRY_NUM-1:0]    v_age           
);

logic [OCM_ROB_ENTRY_NUM-1:0][OCM_ROB_ENTRY_NUM-1:0] v_next_age ;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)                  v_age <= {OCM_ROB_ENTRY_NUM*OCM_ROB_ENTRY_NUM{1'b0}};
    else                        v_age <= v_next_age                                 ;
end

genvar i  ;
integer j ;
generate for(i=0;i<OCM_ROB_ENTRY_NUM;i++) begin
    for(j=0;j<OCM_ROB_ENTRY_NUM;j++) begin
        if(i==j)
            assign v_next_age[i][j] = 1'b0                                                      ;
        else if(j<i)            
            assign v_next_age[i][j] = ~v_next_age[j][i]                                         ;   
        else 
            assign v_next_age[i][j] = axen  ? (v_update_en[j] | (~(v_update_en[i]) & v_age[i][j])) : v_age[i][j] ;
    end
end
endgenerate

endmodule