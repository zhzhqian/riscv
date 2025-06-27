#include "config.h"
#include "artith_ops.h"
#include <iostream>

class ALU{
  ALU() {}

  RegVal execute(int op, RegVal rs0, RegVal rs1) {
    RegVal rd = 0;
    switch(op) {
      case add: {rd = rs0 + rs1; break;}
      case sub: {rd = rs0 - rs1; break;}
      case lt: {rd = rs0 < rs1; break;}
      case ltu: {rd = (RegVal_u)rs0 < (RegVal_u)rs1; break;}
      case op_xor: {rd = rs0 | rs1; break;}
      case op_or: {rd = rs0 ^ rs1; break;}
      case op_and: {rd = rs0 & rs1; break;}
      case sll: {rd = (RegVal_u)rs0 << rs1; break;}
      case srl: {rd = (RegVal_u)rs0 >> rs1; break;}
      case sra: {rd = rs0 >> rs1; break;}
      case eq: {rd = rs0 == rs1; break;}
      case neq: {rd = rs0 != rs1; break;}
      case ge: {rd = rs0 > rs1; break;}
      case geu: {rd = rs0 >= rs1; break;}
      // case Br_Lt: {rd = rs0 - rs1; break;}
      // case Br_Ltu: {rd = rs0 - rs1; break;}
      // case Br_Ge: {rd = rs0 - rs1; break;}
      // case Br_Geu: {rd = rs0 - rs1; break;}
      // case Br_Eq: {rd = rs0 - rs1; break;}
      // case Br_NEq: {rd = rs0 - rs1; break;}
      default: {
        std::cout << "unrecognized alu op" <<std::endl;
        break;
      }
    }
    return rd;
  }

};
