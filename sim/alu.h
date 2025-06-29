#ifndef __ALU_H__
#define __ALU_H__

#include "config.h"
class ALU{
  public:
  ALU() {}
  RegVal evaluate(int op, RegVal rs0, RegVal rs1);
  };

#endif
