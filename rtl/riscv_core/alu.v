`include "arith_op.vh"
module alu(dataA,dataB,ALUFunc,resData);
    parameter BIT=32;
    input [BIT-1:0]dataA;
    input [BIT-1:0]dataB;
    input [`ALU_FUNC_BIT-1:0] ALUFunc; 
    output reg[BIT-1:0]resData;
    //compare less than sign
    reg [BIT-1:0]lt_res_sign;
    wire lt_res_unsign,eq_res;
    // compare less than unsign
    assign lt_res_unsign=dataA<dataB;
    // compare equal 
    assign eq_res=dataA==dataB;
    always @(*) begin
        case(ALUFunc)
            `add: resData=dataA+dataB;
            `sub: resData=dataA-dataB;
            `lt: resData=lt_res_sign;
            `ltu: resData=lt_res_unsign;
            `op_xor:resData=dataA^dataB;
            `op_or:resData=dataA|dataB;
            `op_and:resData=dataA&dataB;
            `sll:resData=dataA<<dataB[4:0];
            `srl: resData=dataA>>dataB[4:0];
            `sra: resData=($signed(dataA))>>>dataB[4:0];
            `eq: resData=eq_res;
            `neq:resData=~eq_res;
            `ge: resData=~lt_res_sign;
            `geu:resData=~lt_res_unsign;
            default:
                resData=0;
        endcase
    end
    always@(*)  begin   
            if(!dataA[BIT-1]&&!dataB[BIT-1])begin
                lt_res_sign=dataA<dataB;
            end
            else if (dataA[BIT-1]&&!dataB[BIT-1]) begin
                lt_res_sign=1;
            end
            else if(!dataA[BIT-1]&&dataB[BIT-1])begin
                lt_res_sign=0;
            end
            else begin
                lt_res_sign=dataA[BIT-2:0]<dataB[BIT-2:0];
            end
        end
endmodule