#ifndef __WB_H__
#define __WB_H__
#include "config.h"
#include "pipe_data.h"

class WriteBack{
  MemToWB& from_mem;
  WBToDecode& to_decode;
  public:
  WriteBack(MemToWB& mem_to_wb,
            WBToDecode& wb_to_dec) :
  from_mem(mem_to_wb),
  to_decode(wb_to_dec)
  {
    
  }
  void tick() {
    to_decode.reg_we = from_mem.reg_we;
    to_decode.dst_reg = from_mem.dst_reg;
    if(from_mem.wb_sel == WBSEL_ALU)
      to_decode.wb_data =from_mem.alu_out;
    else if (from_mem.wb_sel == WBSEL_MEM)
      to_decode.wb_data = from_mem.mem_data;
    else
      to_decode.wb_data = from_mem.csr_out;

  }
};
#endif
