#ifndef __FETCH_H__
#define __FETCH_H__

#include "config.h"
#include "memory.h"
#include "pipe_data.h"
#include <iomanip>


class Fetch{
  MemoryPortMaster<RegVal, RegVal> &inst_mem_port;
  RegVal pc, pc_next;
  EXEToFetch &fromEXE;
  DecodeToFetch &fromDecode;
  FetchTodecode &toDecode;
  FetchToEXE &toExe;
  RegVal reset_pc;
public:
  Fetch(RegVal reset_pc,
        FetchTodecode &fetch2decode,
        DecodeToFetch &dec2fetch,
        EXEToFetch &exe2fetch,
        FetchToEXE &fetch2exe,
        MemoryPortMaster<RegVal, RegVal> &imem_port
      )
  :inst_mem_port(imem_port),
   toDecode(fetch2decode),
   fromDecode(dec2fetch),
   fromEXE(exe2fetch),
   toExe(fetch2exe)
   {
     this->reset_pc = reset_pc;
     reset();
   }
  void tick(){
    pc = pc_next;
    toExe.flush =false;
    toDecode.flush =false;
    if (fromEXE.bp_fail) {
      pc = (fromEXE.branch_taken) ? fromEXE.jump_pc
                                          : fromEXE.exe_pc + 4;
      LOG_INFO("brnach fail, try to return:%x\n", pc);
      /* flush decode and exe, since they are handling
       * wrong instruction.
       */
      // toDecode.flush =true;
      // toExe.flush =true;
    } else if (fromEXE.jump_taken) {
      pc = fromEXE.jump_pc;
      // toExe.flush =true;
      // toDecode.flush =true;
      LOG_INFO("jump to:%x\n", pc);
    } else if (fromDecode.bp_taken) {
      pc = fromDecode.bp_pc;
      LOG_INFO("brnach to:%x\n", pc);
      // toDecode.flush =true;
    }
    pc_next = pc + 4;
    RegVal inst = inst_mem_port.issue_read(pc, sizeof(RegVal));
    LOG_INFO("executing: 0x%08x at pc:0x%x\n",inst, pc);

    toDecode.inst = inst;
    toDecode.pc = pc;
  }
  void reset(){
    pc_next = reset_pc;
  }
};
#endif
