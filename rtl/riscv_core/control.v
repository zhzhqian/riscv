`include "arith_op.vh"
`include "Opcode.vh"
module control(inst,PcJump,Branch,imm,regWE,BSel,ASel,ALUFunc,MemRE,MemWE,WBSel,CSR_EN,load_unsign,bhw,Br_OP);
    //this is only input,instruction 
    input [32-1:0] inst;
    //brach inst?
    output reg Branch;
    //jump? use imm?,write reg? use pc?
    output reg PcJump,BSel,regWE,ASel,load_unsign;
    // do we write or read mem?
    output reg  MemRE,MemWE;
    output reg [31:0] imm;
    // 0001 : lb 0011 load half 1111 load word
    output reg [3:0]bhw;
    //01 and 11
    output reg [1:0] CSR_EN;
    // in branch comperator how we compare 
    output reg [`Br_OP_BIT-1:0] Br_OP;
    output reg [1:0]WBSel;
    output reg [`ALU_FUNC_BIT-1:0] ALUFunc;

    wire [6:0] opcode;
    wire [2:0] funct;
    
    assign opcode=inst[6:0];
    assign funct=inst[14:12];

    always @(*) begin
        Branch=0;
        PcJump=0;
        regWE=0;
        BSel=1;
        ASel=1;
        ALUFunc=`add;
        MemRE=1'b0;
        MemWE=1'b0;
        WBSel=2'b01;
        imm={{20{inst[31]}},inst[31:20]};
        load_unsign=1;
        CSR_EN=0;
        bhw=4'b1111;
        Br_OP=0;
        case(opcode)
            `LUI_OP: begin
                regWE=1;
                imm={inst[31:12],12'b0};
                WBSel=2'b11;
            end
            `AUIPC_OP: begin
                regWE=1;
                ASel=0;
                WBSel=2'b01;
                imm={inst[31:12],12'b0};
            end
            `JAL_OP: begin
                regWE=1;
                PcJump=1;
                ASel=0;
                WBSel=2'b00;
                imm={{11{inst[31]}},inst[31],inst[19:12],inst[20],inst[30:21],1'b0};
            end
            `JALR_OP:begin
                regWE=1;
                PcJump=1;
                WBSel=2'b00;
                imm={{20{inst[31]}},inst[31:20]};
            end
            `BRANCH_OP: begin
                Branch=1;
                WBSel=2'b01;
                ASel=0;
                imm={{19{inst[31]}},inst[31],inst[7],inst[30:25],inst[11:8],1'b0};
                case (funct)
                    `BEQ_FUNCT: Br_OP=`Br_Eq;
                    `BNE_FUNCT: Br_OP=`Br_NEq;
                    `BLT_FUNCT: Br_OP=`Br_Lt;
                    `BGE_FUNCT: Br_OP=`Br_Ge;
                    `BLTU_FUNCT: Br_OP=`Br_Ltu;
                    `BGEU_FUNCT: Br_OP=`Br_Geu;
                endcase
            end
            `LOARD_OP: begin
                regWE=1;
                WBSel=2'b10;
                load_unsign=0;
                MemRE=1;
                case(funct) 
                    `LB_FUNCT: bhw=4'b001; 
                    `LH_FUNCT:  bhw=4'b011; 
                    `LW_FUNCT: bhw=4'b1111; 
                    `LBU_FUNCT:begin
                        load_unsign=1;
                        bhw=4'b001;
                    end
                    `LHU_FUNCT:begin
                        load_unsign=1;
                        bhw=4'b011;
                    end
                endcase
            end
            `STORE_OP: begin
                ASel=1;
                 MemWE=1'b1;
                imm={{20{inst[31]}},inst[31:25],inst[11:7]};
                case(funct) 
                    `SB_FUNCT: bhw=4'b001;
                    `SH_FUNCT: bhw=4'b011;
                    `SW_FUNCT: bhw=4'b1111;
                endcase
            end   
        `ARITH_IMM_OP:begin
                regWE=1;
            
            case(funct)
                `ADDI_FUNCT: ALUFunc=`add;
                `SLTI_FUNCT:  ALUFunc=`lt; 
                `SLTIU_FUNCT:begin
                    ALUFunc=`ltu;
                    imm={{20{inst[31]}},inst[31:20]};
                end
                `XORI_FUNCT: ALUFunc=`op_xor;
                `ORI_FUNCT: ALUFunc=`op_or;
                `ANDI_FUNCT: ALUFunc=`op_and;
                `SLLI_FUNCT:begin
                    ALUFunc=`sll;
                    imm={{27{inst[31]}},inst[24:20]};
                    
                end
                `SRLI_FUNCT:begin
                    if(inst[30])
                        ALUFunc=`sra;
                    else 
                        ALUFunc=`srl;
                    imm={{27{inst[31]}},inst[24:20]};
                end
         endcase
        end
        
        `ARITH_REG_OP:begin
                    imm=32'b0;
                    BSel=0;
                regWE=1;
            case(funct)
                `ADD_FUNCT: begin
                    if(inst[30])
                        ALUFunc=`sub;
                    else
                        ALUFunc=`add;
                end 
                `SLT_FUNCT: ALUFunc=`lt; 
                `SLTU_FUNCT: ALUFunc=`ltu;
                `XOR_FUNCT: ALUFunc=`op_xor;
                `OR_FUNCT: ALUFunc=`op_or;
                `AND_FUNCT: ALUFunc=`op_and;
                `SLL_FUNCT:  ALUFunc=`sll;
                `SRL_FUNCT:begin
                    if(inst[30])
                        ALUFunc=`sra;
                    else
                        ALUFunc=`srl;
                end
            endcase
        end
        `CSR_OP:begin  
                imm={20'b0,inst[31:20]};
                CSR_EN=2'b0;
                case (funct)
                    `CSRRW_FUNCT:  CSR_EN=2'b01;
                    `CSRRWI_FUNCT:  CSR_EN=2'b10;
                endcase
            end
    endcase
    end
endmodule