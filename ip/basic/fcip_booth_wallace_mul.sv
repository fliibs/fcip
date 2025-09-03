module fcip_booth_wallace_mul #(
    parameter integer unsigned A_WIDTH = 8 ,
    parameter integer unsigned B_WIDTH = 8 ,
    parameter integer unsigned PRODUCT_WIDTH=16
)(
    input                           clk     ,
    input                           rst_n   ,
    input                           TC_a    ,
    input                           TC_b    ,
    input  [A_WIDTH-1       :0]     mul_a   ,
    input  [B_WIDTH-1       :0]     mul_b   ,
    output [PRODUCT_WIDTH-1 :0]     product
);

logic [A_WIDTH+B_WIDTH-1:0]                 mul_a_reg                ;
logic [A_WIDTH+B_WIDTH-1:0]                 out0                     ;
logic [A_WIDTH+B_WIDTH-1:0]                 out1                     ;
logic [B_WIDTH+2        :0]                 mul_b_reg                ;
logic [A_WIDTH+B_WIDTH-1:0]                 tmp_out                  ;
logic                                       cout                     ;
logic [(A_WIDTH+B_WIDTH)*(B_WIDTH/2+1)-1:0] prod                     ;
logic [A_WIDTH+B_WIDTH-1:0]                 part_prod   [B_WIDTH/2:0];
logic [A_WIDTH+B_WIDTH-1:0]                 PP          [B_WIDTH/2:0];
logic                                       cin         [B_WIDTH/2:0];


assign mul_a_reg = TC_a ? {{(B_WIDTH){mul_a[A_WIDTH-1]}}, mul_a}:{{(B_WIDTH){1'b0}},mul_a};
assign mul_b_reg = TC_b ? {{2{mul_b[B_WIDTH-1]}}, mul_b, 1'b0} :{{2{1'b0}},mul_b,1'b0};


genvar i;
generate
    for(i=0;i<B_WIDTH/2+1;i=i+1)begin
        if(i==0)begin
            always@(*)begin
                case(mul_b_reg[2*i+2:2*i])
                    3'b000, 3'b111: begin
                        part_prod[i] = {(A_WIDTH+B_WIDTH){1'b0}};
                        cin[i] = 0;
                    end
                    3'b001, 3'b010:begin
                        part_prod[i] = mul_a_reg << 2*i;
                        cin[i] = mul_b_reg [2*i+2];
                    end
                    3'b110,3'b101:begin
                        part_prod[i] = (~mul_a_reg) << 2*i;
                        cin[i] = mul_b_reg[2*i+2];
                    end
                    3'b011:begin
                        part_prod[i] = (mul_a_reg<<1) << 2*i;
                        cin[i] = mul_b_reg [2*i+2];
                    end
                    3'b100:begin
                        part_prod[i] = (~(mul_a_reg <<1)) << 2*i;
                        cin[i] = mul_b_reg[2*i+2];
                    end
                endcase
                PP[i] = part_prod[i];
            end
        end
        else begin
            always@(*)begin
                case(mul_b_reg[2*i+2:2*i])
                    3'b000, 3'b111: begin
                        part_prod[i] = {(A_WIDTH+B_WIDTH){1'b0}};
                        cin[i] = 0;
                    end
                    3'b001, 3'b010, 3'b110,3'b101:begin
                        part_prod[i] = (mul_b_reg[2*i+2] ? (~mul_a_reg) : mul_a_reg)<< 2*i;
                        cin[i] = mul_b_reg [2*i+2];
                    end
                    3'b100,3'b011:begin
                        part_prod[i] = (mul_b_reg[2*i+2] ? ( ~(mul_a_reg <<1) ) : (mul_a_reg<<1) ) << 2*i;
                        cin[i] = mul_b_reg [2*i+2];
                    end
                endcase
                PP[i] = {part_prod[i][A_WIDTH+B_WIDTH-1:2*i],1'b0,cin[i-1],{2*(i-1){1'b0}}};
            end
        end
        assign prod[i*(A_WIDTH+B_WIDTH) +: (A_WIDTH+B_WIDTH)] = PP[i];
    end
endgenerate

DW02_tree #(
    .num_inputs (B_WIDTH/2+1    ),
    .input_width(A_WIDTH+B_WIDTH)
    ) u_tree (
        .INPUT  (prod),
        .OUT0   (out0),
        .OUT1   (out1)
    );



//DW01_add #(
//    .width(A_WIDTH+B_WIDTH)
//) u_add(
//    .A(out0),
//    .B(out1),
//    .CI(1'b0),
//    .SUM(tmp_out),
//    .CO(cout)
//);
assign tmp_out = out0+out1;
assign product = tmp_out[PRODUCT_WIDTH-1:0];
endmodule