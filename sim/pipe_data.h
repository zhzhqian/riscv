#ifndef __PIPE_DATA_H__
#define __PIPE_DATA_H__

#include "config.h"
struct FetchTodecode{
  RegVal inst;
  RegVal pc;
};

struct DecodeToFetch{
  RegVal bp_pc;  
  bool bp_taken;
};

struct EXEToFetch{
  RegVal jump_pc;  
  RegVal exe_pc;  
  bool jump_taken;
  bool bp_fail;
  bool branch_taken;
};

#endif
