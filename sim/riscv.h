
#include "config.h"
#include "decode.h"
#include "exe.h"
#include "fetch.h"
#include "memory.h"
#include "mem_stage.h"
#include "wb.h"
#include <iostream>
#include <string>
#include <vector>

class TinyRiscv {
  Fetch fetch;
  Decode dec;
  Execution exe;
  MemStage mem;
  WriteBack wb;
  FetchTodecode fetch_to_decode;
  DecodeToFetch dec_to_fetch;
  EXEToFetch exe_to_fetch;
  FetchToEXE fetch_to_exe;
  EXEToDecode exe_to_decode;
  DecodeToEXE decode_to_exe;
  WBToDecode wb_to_decode;
  MemToDecode mem_to_decode;
  EXEToMem exe_to_mem;
  MemToWB mem_to_wb;

public:
  MemoryPortMaster<RegVal, RegVal> imem_port;
  MemoryPortMaster<RegVal, RegVal> dmem_port;
  TinyRiscv();
  void reset();
  void tick();
};
