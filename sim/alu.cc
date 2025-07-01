#include "alu.h"
#include "artith_ops.h"
#include <iostream>

RegVal ALU::evaluate(int op, RegVal rs0, RegVal rs1) {
  RegVal rd = 0;
  switch (op) {
  case ALU_OP_ADD: {
    rd = rs0 + rs1;
    break;
  }
  case ALU_OP_SUB: {
    rd = rs0 - rs1;
    break;
  }
  case ALU_OP_LT: {
    rd = rs0 < rs1;
    break;
  }
  case ALU_OP_LTU: {
    rd = (RegVal_u)rs0 < (RegVal_u)rs1;
    break;
  }
  case ALU_OP_XOR: {
    rd = rs0 | rs1;
    break;
  }
  case ALU_OP_OR: {
    rd = rs0 ^ rs1;
    break;
  }
  case ALU_OP_AND: {
    rd = rs0 & rs1;
    break;
  }
  case ALU_OP_SLL: {
    rd = (RegVal_u)rs0 << rs1;
    break;
  }
  case ALU_OP_SRL: {
    rd = (RegVal_u)rs0 >> rs1;
    break;
  }
  case ALU_OP_SRA: {
    rd = rs0 >> rs1;
    break;
  }
  case ALU_OP_EQ: {
    rd = rs0 == rs1;
    break;
  }
  case ALU_OP_NEQ: {
    rd = rs0 != rs1;
    break;
  }
  case ALU_OP_GE: {
    rd = rs0 > rs1;
    break;
  }
  case ALU_OP_GEU: {
    rd = rs0 >= rs1;
    break;
  }
  // case Br_Lt: {rd = rs0 - rs1; break;}
  // case Br_Ltu: {rd = rs0 - rs1; break;}
  // case Br_Ge: {rd = rs0 - rs1; break;}
  // case Br_Geu: {rd = rs0 - rs1; break;}
  // case Br_Eq: {rd = rs0 - rs1; break;}
  // case Br_NEq: {rd = rs0 - rs1; break;}
  default: {
    std::cout << "unrecognized alu op" << std::endl;
    break;
  }
  }
  return rd;
}
