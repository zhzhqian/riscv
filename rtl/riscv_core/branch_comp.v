`include "arith_op.vh"
module branch_comp( Br_OP,dataA,dataB,comp_res);
    parameter BIT =32 ;
    input [`Br_OP_BIT-1:0]Br_OP;
    input [BIT-1:0] dataA;
    input [BIT-1:0] dataB;
    output comp_res;
    reg comp_res;
    reg BrLt;
    always @(*) begin
        comp_res=0;
        case (Br_OP)
            `Br_Lt: comp_res=BrLt;
            `Br_Ltu:comp_res=dataA<dataB;
            `Br_Ge:comp_res=~BrLt;
            `Br_Geu: comp_res=~(dataA<dataB);
            `Br_Eq: comp_res=dataA==dataB;
            `Br_NEq: comp_res=~(dataA==dataB);
        endcase
    end
    always @(*) begin
        if(!dataA[BIT-1]&&!dataB[BIT-1])begin
            BrLt=dataA<dataB;
        end
        else if (dataA[BIT-1]&&!dataB[BIT-1]) begin
            BrLt=1;
        end
        else if(!dataA[BIT-1]&&dataB[BIT-1])begin
            BrLt=0;
        end
        else begin
            BrLt=dataA[BIT-2:0]<dataB[BIT-2:0];
        end
    end
endmodule