`include "arith_op.vh"
module control(inst,PcJump,imm,regWE,BSel,ASel,ALUFunc,
            MemRw,WBSel,CSR_EN,load_unsign,bhw,Br_OP,
            //for branch predict
            branch);

    localparam LUI_OP=7'b0110111;
    localparam AUIPC_OP=7'b0010111;
    localparam JAL_OP=7'b1101111;
    localparam JALR_OP=7'b1100111;
    
    localparam BRANCH_OP=7'b1100011;

    localparam LOARD_OP=7'b0000011;

    localparam STORE_OP=7'b0100011;
    
    localparam ARITH_IMM_OP=7'b0010011;

    localparam ARITH_REG_OP=7'b0110011;

    localparam CSR_OP=7'b1110011;
    localparam CSRRWI_FUNCT=3'b101;
    localparam CSRRW_FUNCT=3'b001;

    localparam BEQ_FUNCT=3'b000;
    localparam BNE_FUNCT=3'b001;
    localparam BLT_FUNCT=3'b100;
    localparam BGE_FUNCT=3'b101;
    localparam BLTU_FUNCT=3'b110;
    localparam BGEU_FUNCT=3'b111;

    
    localparam LB_FUNCT=3'b000;
    localparam LH_FUNCT=3'b001;
    localparam LW_FUNCT=3'b010;
    localparam LBU_FUNCT=3'b100;
    localparam LHU_FUNCT=3'b101;

    localparam SB_FUNCT=3'b000;
    localparam SH_FUNCT=3'b001;
    localparam SW_FUNCT=3'b010;


    localparam ADDI_FUNCT=3'b000;
    localparam SLTI_FUNCT=3'b010;
    localparam SLTIU_FUNCT=3'b011;
    localparam XORI_FUNCT=3'b100;
    localparam ORI_FUNCT=3'b110;
    localparam ANDI_FUNCT=3'b111;
    localparam SLLI_FUNCT=3'b001;
    localparam SRLI_FUNCT=3'b101;
    localparam SRAI_FUNCT=3'b101;

    localparam ADD_FUNCT=3'b000;
    localparam SLL_FUNCT=3'b001;
    localparam SLT_FUNCT=3'b010;
    localparam SLTU_FUNCT=3'b011;
    localparam XOR_FUNCT=3'b100;
    localparam SRL_FUNCT=3'b101;
    localparam OR_FUNCT=3'b110;
    localparam AND_FUNCT=3'b111;


    input [32-1:0] inst;

    output reg PcJump,BSel,regWE,ASel,load_unsign,branch;
    output MemRw;
    output [32-1:0] imm;
    output [3:0]bhw;
    output [1:0] CSR_EN;
    output [`Br_OP_BIT-1:0] Br_OP;
    reg [`Br_OP_BIT-1:0] Br_OP;
    reg [3:0] bhw;
    reg [32-1:0] imm;
    output [1:0]WBSel;
    reg [1:0]WBSel;

    reg[1:0]CSR_EN;
    reg  MemRw;
    wire [6:0] opcode;
    wire [2:0] funct;
    output [`ALU_FUNC_BIT-1:0] ALUFunc;
    reg [`ALU_FUNC_BIT-1:0] ALUFunc;
    
    assign opcode=inst[6:0];
    assign funct=inst[14:12];

    always @(*) begin
        branch=0;
        PcJump=0;
        regWE=1;
        BSel=1;
        ASel=1;
        ALUFunc=`add;
        MemRw=1'b0;
        WBSel=2'b01;
        imm={{20{inst[31]}},inst[31:20]};
        load_unsign=1;
        CSR_EN=0;
        bhw=4'b1111;
        Br_OP=0;
        case(opcode)
            LUI_OP: begin
                imm={inst[31:12],12'b0};
                WBSel=2'b11;
            end
            AUIPC_OP: begin
                ASel=0;
                WBSel=2'b01;
                imm={inst[31:12],12'b0};
            end
            JAL_OP: begin
                PcJump=1;
                ASel=0;
                WBSel=2'b00;
                imm={{11{inst[31]}},inst[31],inst[19:12],inst[20],inst[30:21],1'b0};
            end
            JALR_OP:begin
                PcJump=1;
                WBSel=2'b00;
                imm={{20{inst[31]}},inst[31:20]};
            end
            BRANCH_OP: begin
                branch=1;
                WBSel=2'b01;
                regWE=0;
                ASel=0;
                imm={{19{inst[31]}},inst[31],inst[7],inst[30:25],inst[11:8],1'b0};
                case (funct)
                    BEQ_FUNCT: Br_OP=`Br_Eq;
                    BNE_FUNCT: Br_OP=`Br_NEq;
                    BLT_FUNCT: Br_OP=`Br_Lt;
                    BGE_FUNCT: Br_OP=`Br_Ge;
                    BLTU_FUNCT: Br_OP=`Br_Ltu;
                    BGEU_FUNCT: Br_OP=`Br_Geu;
                endcase
            end
            LOARD_OP: begin
                WBSel=2'b10;
                load_unsign=0;
                case(funct) 
                    LB_FUNCT: bhw=4'b001; 
                    LH_FUNCT:  bhw=4'b011; 
                    LW_FUNCT: bhw=4'b1111; 
                    LBU_FUNCT:begin
                        load_unsign=1;
                        bhw=4'b001;
                    end
                    LHU_FUNCT:begin
                        load_unsign=1;
                        bhw=4'b011;
                    end
                endcase
            end
            STORE_OP: begin
                regWE=0;
                ASel=1;
                MemRw=1'b1;
                imm={{20{inst[31]}},inst[31:25],inst[11:7]};
                case(funct) 
                    SB_FUNCT: bhw=4'b001;
                    SH_FUNCT: bhw=4'b011;
                    SW_FUNCT: bhw=4'b1111;
                endcase
            end   
        ARITH_IMM_OP:
            case(funct)
                ADDI_FUNCT: ALUFunc=`add;
                SLTI_FUNCT:  ALUFunc=`lt; 
                SLTIU_FUNCT:begin
                    ALUFunc=`ltu;
                    imm={20'b0,inst[31:20]};
                end
                XORI_FUNCT: ALUFunc=`op_xor;
                ORI_FUNCT: ALUFunc=`op_or;
                ANDI_FUNCT: ALUFunc=`op_and;
                SLLI_FUNCT:begin
                    ALUFunc=`sll;
                    imm={{27{inst[31]}},inst[24:20]};
                    
                end
                SRLI_FUNCT:begin
                    if(inst[30])
                        ALUFunc=`sra;
                    else 
                        ALUFunc=`srl;
                    imm={{27{inst[31]}},inst[24:20]};
                end
         endcase
        
        ARITH_REG_OP:begin
                    imm=32'b0;
                    BSel=0;
            case(funct)
                ADD_FUNCT: begin
                    if(inst[30])
                        ALUFunc=`sub;
                    else
                        ALUFunc=`add;
                end 
                SLT_FUNCT: ALUFunc=`lt; 
                SLTU_FUNCT: ALUFunc=`ltu;
                XOR_FUNCT: ALUFunc=`op_xor;
                OR_FUNCT: ALUFunc=`op_or;
                AND_FUNCT: ALUFunc=`op_and;
                SLL_FUNCT:  ALUFunc=`sll;
                SRL_FUNCT:begin
                    if(inst[30])
                        ALUFunc=`sra;
                    else
                        ALUFunc=`srl;
                end
            endcase
        end
        CSR_OP:begin  
                regWE=0;
                imm={20'b0,inst[31:20]};
                CSR_EN=2'b0;
                case (funct)
                    CSRRW_FUNCT:  CSR_EN=2'b01;
                    CSRRWI_FUNCT:  CSR_EN=2'b10;
                endcase
            end
    endcase
    end
endmodule