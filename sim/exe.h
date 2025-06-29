
#include "config.h"
#include "pipe_data.h"
#include "artith_ops.h"
#include "alu.h"
#include "csr.h"
#include <cstdint>


class Execution {
  EXEToFetch& to_fetch;
  DecodeToEXE& from_decode;
  EXEToMem& to_mem;
  ALU alu;
  CSR csr;

  Execution(EXEToFetch& exe_to_fecth,
            DecodeToEXE& dec_to_exe,
          EXEToMem& exe_to_mem):
  to_fetch(exe_to_fecth),
  from_decode(dec_to_exe),
  to_mem(exe_to_mem) {
   
  }

  void tick(){
    RegVal alu_in0, alu_in1;
    // first, handle alu calc
    alu_in0 = (from_decode.alu_sel0 ==  ALU_PORT0_PC) ? from_decode.pc :
                                                      from_decode.rs1;
    alu_in1 = (from_decode.alu_sel1 ==  ALU_PORT1_IMM) ? from_decode.imm :
                                                      from_decode.rs2;
    to_mem.alu_out = alu.evaluate(from_decode.alu_op, alu_in0, alu_in1);

    // second, handle csrrw
    to_mem.csr_out = csr.read(from_decode.csr_idx);
    if(from_decode.csr_op != CSR_OP_RW){
      csr.write(from_decode.csr_idx, from_decode.rs1);
    }else if(from_decode.csr_op != CSR_OP_RWI){
      csr.write(from_decode.csr_idx, from_decode.imm);
    }

    // third handle branch
    if(from_decode.is_branch) {
      to_mem.branch_taken = !!(to_mem.alu_out);
    }

    // passthrough signal from decode
    to_mem.mem_rd = from_decode.mem_rd;
    to_mem.mem_wr = from_decode.mem_wr;
    to_mem.reg_we = from_decode.reg_we;
    to_mem.wb_sel = from_decode.wb_sel;
    to_mem.loadu  = from_decode.loadu;
    to_mem.rs2    = from_decode.rs2;
  }
};
