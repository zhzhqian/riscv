#ifndef __ARTITH_OPS_H__
#define __ARTITH_OPS_H__
enum ALUOpType {
  ALU_OP_NONE,
  ALU_OP_ADD,
  ALU_OP_SUB,

  ALU_OP_LT,
  ALU_OP_LTU,

  ALU_OP_XOR,
  ALU_OP_OR,
  ALU_OP_AND,

  ALU_OP_SLL,
  ALU_OP_SRL,
  ALU_OP_SRA,

  ALU_OP_EQ,
  ALU_OP_NEQ,
  ALU_OP_GE,
  ALU_OP_GEU,

};
enum BranchOpType {
  BR_OP_EQ = 0b000,
  BR_OP_NEQ = 0b001,
  BR_OP_LT = 0b100,
  BR_OP_GE = 0b101,
  BR_OP_LTU = 0b110,
  BR_OP_GEU = 0b111,
};

enum CSROpType { CSR_OP_NONE, CSR_OP_RW, CSR_OP_RWI };

#endif
