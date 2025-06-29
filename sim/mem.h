#ifndef __MEM_H__
#define __MEM_H__

#include "config.h"
#include "pipe_data.h"
#include "ram.h"
#include "uart.h"

class MemStage {
  EXEToMem& from_exe;
  MemToWB& to_wb;
  SyncRamDP<DataWidth> data_mem;
  MemStage(EXEToMem& exe_to_exe, 
           MemToWB& mem_to_wb):
  from_exe(exe_to_exe),
  to_wb(mem_to_wb),
  data_mem(DMEM_DPETH)
  {
    
  }

  void tick() {
    if(from_exe.mem_rd) {
      to_wb.mem_data = data_mem.read(from_exe.alu_out);
    }
    if(from_exe.mem_wr) {
      data_mem.write(from_exe.alu_out,from_exe.rs2);
    }
    to_wb.alu_out = from_exe.alu_out;
    to_wb.dst_reg = from_exe.dst_reg;
    to_wb.csr_out = from_exe.csr_out;
    to_wb.reg_we = from_exe.reg_we;
    to_wb.wb_sel = from_exe.wb_sel;
  }
};
#endif
