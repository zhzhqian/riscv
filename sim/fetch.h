#ifndef __FETCH_H__
#define __FETCH_H__

#include "config.h"
#include "mem.h"
#include "pipe_data.h"


class Fetch{
  SyncRamDP<DataWidth> inst_mem;
  RegVal pc, pc_next;
  EXEToFetch &fromEXE;
  DecodeToFetch &fromDecode;
  FetchTodecode &toDecode;
  FetchToEXE &toExe;

  Fetch(RegVal start_addr,
        FetchTodecode &fetch2decode,
        DecodeToFetch &dec2fetch,
        EXEToFetch &exe2fetch,
        FetchToEXE &fetch2exe
      )
  :pc_next(start_addr),
   inst_mem(INST_MEM_SIZE),
   toDecode(fetch2decode),
   fromDecode(dec2fetch),
   fromEXE(exe2fetch),
   toExe(fetch2exe)
   {}
  void tick(){
    pc = pc_next;
    RegVal inst = inst_mem.read(pc);
    if (fromEXE.bp_fail) {
      pc_next = (fromEXE.branch_taken) ? fromEXE.jump_pc
                                          : fromEXE.exe_pc + 4;
      /* TODO: flush exe state */
      toExe.flush =true;
    } else if (fromEXE.jump_taken) {
      pc_next = fromEXE.jump_pc;
    } else if (fromDecode.bp_taken) {
      pc_next = fromDecode.bp_pc;
    } else {
      pc_next = pc + 4;
    }

    toDecode.inst = inst;
    toDecode.pc = pc;
  }
};
#endif
