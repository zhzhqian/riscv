#ifndef __FETCH_H__
#define __FETCH_H__

#include "config.h"
#include "mem.h"
#include "pipe_data.h"
#include <iomanip>


class Fetch{
  SyncRamDP<RegVal> &inst_mem;
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
        SyncRamDP<RegVal> &imem
      )
  :inst_mem(imem),
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
      /* flush decode and exe, since they are handling
       * wrong instruction.
       */
      // toDecode.flush =true;
      // toExe.flush =true;
    } else if (fromEXE.jump_taken) {
      pc = fromEXE.jump_pc;
      // toExe.flush =true;
      // toDecode.flush =true;
    } else if (fromDecode.bp_taken) {
      pc = fromDecode.bp_pc;
      // toDecode.flush =true;
    }
    pc_next = pc + 4;
    RegVal inst = inst_mem.read(pc);
    std::cout<< "executing: "<<std::hex<<std::setw(8) << inst<<std::end;

    toDecode.inst = inst;
    toDecode.pc = pc;
  }
  void reset(){
    pc_next = reset_pc;
  }
};
#endif
