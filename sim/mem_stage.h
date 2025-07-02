#ifndef __MEM_H__
#define __MEM_H__

#include "config.h"
#include "pipe_data.h"
#include "memory.h"
#include "uart.h"

class MemStage {
  EXEToMem& from_exe;
  MemToWB& to_wb;
  MemoryPortMaster<RegVal, RegVal> &dmem_port;
  public:
  MemStage(EXEToMem& exe_to_exe, 
           MemToWB& mem_to_wb,
            MemoryPortMaster<RegVal, RegVal> &dmem_port
         ):
  from_exe(exe_to_exe),
  to_wb(mem_to_wb),
  dmem_port(dmem_port)
  {
    
  }

  void tick() {
    if(from_exe.mem_rd) {
      to_wb.mem_data = dmem_port.issue_read(from_exe.alu_out, from_exe.mem_op_size);
    }
    if(from_exe.mem_wr) {
      dmem_port.issue_write(from_exe.alu_out,from_exe.rs2, from_exe.mem_op_size);
    }
    to_wb.alu_out = from_exe.alu_out;
    to_wb.dst_reg = from_exe.dst_reg;
    to_wb.csr_out = from_exe.csr_out;
    to_wb.reg_we = from_exe.reg_we;
    to_wb.wb_sel = from_exe.wb_sel;
  }
};
#endif
