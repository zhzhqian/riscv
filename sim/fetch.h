#include "config.h"
#include "mem.h"
#include "pipe_data.h"


class Fetch{
  IOMem<DataWidth> inst_mem;
  RegVal pc, pc_next;
  EXEToFetch &inpFromEXE;
  DecodeToFetch &inpFromDecode;
  FetchTodecode &outwrite;

  Fetch(RegVal start_addr,
        FetchTodecode &fetch2decode,
        DecodeToFetch &dec2fetch,
        EXEToFetch &exe2fetch
      )
  :pc_next(start_addr),
   inst_mem(INST_MEM_SIZE),
   outwrite(fetch2decode),
   inpFromDecode(dec2fetch),
   inpFromEXE(exe2fetch)
   {}
  void tick(){
    pc = pc_next;
    RegVal inst = inst_mem.read(pc);
    if (inpFromEXE.bp_fail) {
      pc_next = (inpFromEXE.branch_taken) ? inpFromEXE.jump_pc
                                          : inpFromEXE.exe_pc + 4;
    } else if (inpFromEXE.jump_taken) {
      pc_next = inpFromEXE.jump_pc;
    } else if (inpFromDecode.bp_taken) {
      pc_next = inpFromDecode.bp_pc;
    } else {
      pc_next = pc + 4;
    }

    outwrite.inst = inst;
    outwrite.pc = pc;
  }
};
