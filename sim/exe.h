#ifndef __EXE_H__
#define __EXE_H__

#include "alu.h"
#include "artith_ops.h"
#include "config.h"
#include "csr.h"
#include "pipe_data.h"
#include <cstdint>

class Execution {
  EXEToFetch &to_fetch;
  DecodeToEXE &from_decode;
  EXEToMem &to_mem;
  FetchToEXE &from_fetch;
  ALU alu;
  CSR csr;
public:
  Execution(EXEToFetch &exe_to_fecth,
            DecodeToEXE &dec_to_exe,
            EXEToMem &exe_to_mem,
            FetchToEXE &fetch_to_exe)
      : to_fetch(exe_to_fecth), from_decode(dec_to_exe), to_mem(exe_to_mem),
        from_fetch(fetch_to_exe) {}

  void tick() {
    RegVal alu_in0, alu_in1;
    to_mem.flush();
    to_fetch.flush();
    // first, handle alu calc
    alu_in0 = (from_decode.alu_sel0 == ALU_PORT0_PC) ? from_decode.pc
                                                     : from_decode.rs1;
    alu_in1 = (from_decode.alu_sel1 == ALU_PORT1_IMM) ? from_decode.imm
                                                      : from_decode.rs2;
    to_mem.alu_out = alu.evaluate(from_decode.alu_op, alu_in0, alu_in1);

    // second, handle csrrw
    to_mem.csr_out = csr.read(from_decode.csr_idx);
    if (from_decode.csr_op == CSR_OP_RW) {
      csr.write(from_decode.csr_idx, from_decode.rs1);
    } else if (from_decode.csr_op == CSR_OP_RWI) {
      csr.write(from_decode.csr_idx, from_decode.imm);
    }

    // third handle branch
    if (from_decode.is_branch) {
      to_mem.branch_taken =
          branch_evaluate(from_decode.br_op, from_decode.rs1, from_decode.rs2);
      to_fetch.branch_taken = to_mem.branch_taken;
      to_fetch.bp_fail = from_decode.bp_taken != to_fetch.branch_taken;
    }

    // passthrough signal from decode
    to_mem.mem_rd = from_decode.mem_rd;
    to_mem.mem_wr = from_decode.mem_wr;
    to_mem.mem_op_size = from_decode.mem_op_size;
    to_mem.reg_we = from_decode.reg_we;
    to_mem.wb_sel = from_decode.wb_sel;
    to_mem.loadu = from_decode.loadu;
    to_mem.rs2 = from_decode.rs2;
    to_mem.dst_reg = from_decode.dst_reg;

    // don't use branch predict now
    to_fetch.bp_fail = false;

    // branch and jump both use jump_pc
    to_fetch.jump_pc = to_mem.alu_out;
    to_fetch.jump_taken = from_decode.is_jump;
    to_fetch.exe_pc = from_decode.pc;

    // request from fetch stage to execution stage
    if (from_fetch.flush) {
      to_mem.flush();
      to_fetch.flush();
    }
  }
  bool branch_evaluate(int branch_op, RegVal rs1, RegVal rs2) {
    bool taken = false;
    switch (branch_op) {
    case (BEQ_FUNCT):
      taken = rs1 == rs2;
      break;
    case (BNE_FUNCT):
      taken = rs1 != rs2;
      break;
    case (BLT_FUNCT):
      taken = rs1 < rs2;
      break;
    case (BGE_FUNCT):
      taken = rs1 >= rs2;
      break;
    case (BLTU_FUNCT):
      taken = (RegVal_u)rs1 < (RegVal_u)rs2;
      break;
    case (BGEU_FUNCT):
      taken = (RegVal_u)rs1 >= (RegVal_u)rs2;
      break;
    }
    return taken;
  }
};
#endif
