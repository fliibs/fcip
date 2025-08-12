module ocm_bank_agt
import ocm_package::*;
(
    input  logic                    clk         ,
    input  logic                    rst_n       ,    
    input  logic                    wr_update   ,
    input  logic                    rd_update   ,
    output logic                    wr_bank_en  ,     
    output logic                    rd_bank_en     
);
always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)              rd_bank_en <= 1'b1     ;
    else if(wr_update)      rd_bank_en <= 1'b0     ;
    else                    rd_bank_en <= 1'b1     ;
end
assign wr_bank_en = 1'b1    ;
endmodule