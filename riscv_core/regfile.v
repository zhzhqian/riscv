`include "../EECS151.v"

module regfile(readA,readB,write,rst,write_data,WE,clk,dataA,dataB);
    parameter BIT =32 ;
    parameter REG_NUM=32;
    localparam add_bum=$clog2(REG_NUM);
    input [add_bum-1:0]readA;
    input [add_bum-1:0]readB;
    input [add_bum-1:0]write;
    input [BIT-1:0] write_data;
    input WE;
    input clk;
    input rst;
    output [BIT-1:0]dataA;
    output [BIT-1:0]dataB;

    wire [BIT-1:0] reg_out[REG_NUM-1:0];
    wire [REG_NUM-1:0] regce;

    REGISTER_R_CE #(.N(BIT),.INIT(0)) X_0(.d(32'b0),.q(reg_out[0]),.clk(clk),.ce(1'b1),.rst(rst)); 
     
    genvar i;
    generate 
    for(i=1;i<REG_NUM;i=i+1) begin:reg_gen
        REGISTER_R_CE #(.N(BIT),.INIT(0)) X_i(.d(write_data),.q(reg_out[i]),.clk(clk),.ce(regce[i]),.rst(rst)); 
    end
    endgenerate
    generate
    for(i=0;i<REG_NUM;i=i+1) begin:ce_gen
       assign regce[i]=(write==i)&&WE;
    end
    endgenerate
    assign dataA=reg_out[readA];
    assign dataB=reg_out[readB];
endmodule



