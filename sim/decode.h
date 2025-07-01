#ifndef __DECODE_H__
#define __DECODE_H__

#include "artith_ops.h"
#include "config.h"
#include "pipe_data.h"
#include "regfile.h"
#include <cstdint>

static inline int funct_to_brachop(uint32_t funct) {
  // funct equals branch op
  return funct;
}

static inline int arith_imm_funct_to_aluop(uint32_t funct, uint32_t bit_30) {
  switch (funct) {
  case ADDI_FUNCT:
    return ALU_OP_ADD;
  case SLTI_FUNCT:
    return ALU_OP_LT;
  case SLTIU_FUNCT:
    return ALU_OP_LTU;
  case XORI_FUNCT:
    return ALU_OP_XOR;
  case ORI_FUNCT:
    return ALU_OP_OR;
  case ANDI_FUNCT:
    return ALU_OP_AND;
  case SLLI_FUNCT:
    return ALU_OP_SLL;
  case SRLI_FUNCT:
    if (bit_30)
      return ALU_OP_SRA;
    else
      return ALU_OP_SRL;
  default:
    std::cerr << "unrecognized arith_imm funct" << std::endl;
  }
  return funct;
}
// TODO: sel logic shift or arith shift
static inline int arith_funct_to_aluop(uint32_t funct, uint32_t bit_30) {
  switch (funct) {
  case ADD_FUNCT:
    if (bit_30)
      return ALU_OP_SUB;
    else
      return ALU_OP_ADD;
  case SLL_FUNCT:
    return ALU_OP_SLL;
  case SLT_FUNCT:
    return ALU_OP_LT;
  case SLTU_FUNCT:
    return ALU_OP_LTU;
  case XOR_FUNCT:
    return ALU_OP_XOR;
  case SRL_FUNCT:
    if (bit_30)
      return ALU_OP_SRA;
    else
      return ALU_OP_SRL;
  case OR_FUNCT:
    return ALU_OP_ADD;
  case AND_FUNCT:
    return ALU_OP_ADD;
  default:
    std::cerr << "unrecognized arith_imm funct" << std::endl;
  }
  return funct;
}

union InstType {
  uint32_t inst_raw;
  InstType(uint32_t inst) { inst_raw = inst; }
  static uint32_t get_sign_mask(uint32_t sign, uint32_t bit_low =0,
                                uint32_t bit_hi=31) {
    u32 sign_mask = 0;
    if (sign) {
      sign_mask |= (~0U) & ((~0U) >> bit_hi) & ((~0U) << bit_low);
    }
    return sign_mask;
  }
  struct RType {
    uint32_t opcode : 7;
    uint32_t rd : 5;
    uint32_t funct3 : 3;
    uint32_t rs1 : 5;
    uint32_t rs2 : 5;
    uint32_t funct7 : 7;
  } r_type;
  struct IType {
    uint32_t opcode : 7;
    uint32_t rd : 5;
    uint32_t funct3 : 3;
    uint32_t rs1 : 5;
    uint32_t imm0 : 5;
    uint32_t imm1 : 7;
    template <typename T> T get_imm() {
      return (T)(this->imm0 | (this->imm1 << 5) |
                 get_sign_mask(this->imm1 >> 6));
    }
    template <typename T> T get_shm() {
      return (T)(this->imm0 | get_sign_mask(this->imm1 >> 6));
    }
    template <typename T> T get_immu() {
      return (T)(this->imm0 | (this->imm1 << 5) | get_sign_mask(0));
    }
  } i_type;
  struct SType {
    uint32_t opcode : 7;
    uint32_t imm_lo : 5;
    uint32_t funct3 : 3;
    uint32_t rs1 : 5;
    uint32_t rs2 : 5;
    uint32_t imm_hi : 7;
    template <typename T> T get_imm() {
      return (T)(this->imm_lo | (this->imm_hi << 5) |
                 get_sign_mask(this->imm_hi >> 6));
    }
  } s_type;
  struct BType {
    uint32_t opcode : 7;
    uint32_t imm_11 : 1;
    uint32_t imm_lo : 4;
    uint32_t funct3 : 3;
    uint32_t rs1 : 5;
    uint32_t rs2 : 5;
    uint32_t imm_hi : 6;
    uint32_t imm_12 : 1;
    template <typename T> T get_imm() {
      return (T)((this->imm_11 << 12) | (this->imm_11 << 11) | this->imm_lo |
                 (this->imm_hi << 4) | get_sign_mask(this->imm_12));
    }
  } b_type;
  struct UType {
    uint32_t opcode : 7;
    uint32_t rd : 5;
    uint32_t imm : 20;
    template <typename T> T get_imm() { return (T)(this->imm << 12); }
  } u_type;
  struct JType {
    uint32_t opcode : 7;
    uint32_t rd : 5;
    uint32_t imm_19_12 : 8;
    uint32_t imm_11 : 1;
    uint32_t imm_10_1 : 10;
    uint32_t imm_20 : 1;
    template <typename T> T get_imm() {
      return (T)((this->imm_20 << 20) | (this->imm_19_12 << 12) |
                 (this->imm_11 << 11) | (this->imm_10_1 << 1) |
                 get_sign_mask(this->imm_20));
    }
  } j_type;
};

static_assert(sizeof(InstType) == 4, "instruction format is not correct");

class Decode {
  FetchTodecode &from_fetch;
  EXEToDecode &from_exe;
  WBToDecode &from_wb;
  MemToDecode &from_mem;
  DecodeToEXE &to_exe;
  DecodeToFetch &to_fetch;
  RegVal inst;
  RegFile_1W2R<RegVal> regfile;
public:
  Decode(FetchTodecode &fetch_to_decode,
         EXEToDecode &exe_to_decode,
         DecodeToEXE &decode_to_exe,
         WBToDecode &wb_to_decode,
         MemToDecode &mem_to_decode,
         DecodeToFetch &dec_to_fetch
       )
      : from_fetch(fetch_to_decode), from_exe(exe_to_decode),
        from_wb(wb_to_decode), from_mem(mem_to_decode),
        to_exe(decode_to_exe),to_fetch(dec_to_fetch),
        regfile(32) {}
  void tick() {
    int rs1 = 0;
    int rs2 = 0;
    inst = from_fetch.inst;
    InstType inst_t = (InstType)inst;
    // reset signal
    // default imm
    to_exe.flush();
    to_fetch.flush();
    to_exe.imm = inst_t.i_type.get_imm<RegVal>();
    to_exe.pc = from_fetch.pc;
    to_exe.dst_reg = inst_t.r_type.rd;
    to_exe.alu_op = ALU_OP_ADD;
    switch (inst_t.i_type.opcode) {
    case (LUI_OP):
      to_exe.reg_we = true;
      to_exe.imm = inst_t.u_type.get_imm<RegVal>();
      to_exe.wb_sel = WBSEL_ALU;
      rs1 = 0;
      to_exe.alu_sel0 = ALU_PORT0_RS1;
      to_exe.alu_sel1 = ALU_PORT1_IMM;
      break;
    case (AUIPC_OP):
      to_exe.reg_we = true;
      to_exe.imm = inst_t.u_type.get_imm<RegVal>();
      to_exe.alu_sel0 = ALU_PORT0_PC;
      to_exe.wb_sel = WBSEL_ALU;
      break;
    case (JAL_OP):
      to_exe.reg_we = true;
      to_exe.is_jump = true;
      to_exe.alu_sel0 = ALU_PORT0_PC;
      to_exe.wb_sel = WBSEL_PC;
      to_exe.imm = inst_t.j_type.get_imm<RegVal>();
      break;
    case (JALR_OP):
      to_exe.reg_we = true;
      to_exe.is_jump = true;
      to_exe.imm = inst_t.i_type.get_imm<RegVal>();
      to_exe.wb_sel = WBSEL_PC;
      break;
    case (BRANCH_OP):
      to_exe.is_branch = true;
      to_exe.alu_sel0 = ALU_PORT0_PC;
      to_exe.imm = inst_t.b_type.get_imm<RegVal>();
      to_exe.br_op = funct_to_brachop(inst_t.b_type.funct3);
      rs1 = inst_t.s_type.rs1;
      rs2 = inst_t.s_type.rs2;
      break;
    case (LOAD_OP):
      to_exe.mem_rd = true;
      to_exe.reg_we = true;
      to_exe.mem_op_size = inst_t.i_type.funct3;
      to_exe.imm = inst_t.i_type.get_imm<RegVal>();
      to_exe.alu_op = ALU_OP_ADD;
      to_exe.alu_sel0 = ALU_PORT0_RS1;
      to_exe.alu_sel1 = ALU_PORT1_IMM;
      rs1 = inst_t.i_type.rs1;
      break;
    case (STORE_OP):
      to_exe.mem_wr = true;
      to_exe.mem_op_size = inst_t.s_type.funct3;
      to_exe.imm = inst_t.s_type.get_imm<RegVal>();
      to_exe.alu_op = ALU_OP_ADD;
      to_exe.alu_sel0 = ALU_PORT0_RS1;
      to_exe.alu_sel1 = ALU_PORT1_IMM;
      rs1 = inst_t.s_type.rs1;
      rs2 = inst_t.s_type.rs2;
      break;
    case (ARITH_IMM_OP):
      to_exe.reg_we = true;
      if (inst_t.i_type.funct3 == SLLI_FUNCT ||
          inst_t.i_type.funct3 == SRLI_FUNCT) {
        to_exe.imm = inst_t.i_type.get_shm<RegVal>();
      }
      to_exe.alu_op = arith_imm_funct_to_aluop(inst_t.i_type.funct3,
                                                 inst_t.inst_raw & BIT(30));
      rs1 = inst_t.i_type.rs1;
      break;
    case (ARITH_REG_OP):
      to_exe.reg_we = true;
      to_exe.alu_sel1 = ALU_PORT1_RS2;
      to_exe.alu_op =
          arith_funct_to_aluop(inst_t.i_type.funct3, inst_t.inst_raw & BIT(30));
      rs1 = inst_t.r_type.rs1;
      rs2 = inst_t.r_type.rs2;
      break;
    case (CSR_OP):
      if (inst_t.i_type.funct3 == CSRRW_FUNCT) {
        to_exe.csr_op = CSR_OP_RW;
        to_exe.csr_idx = inst_t.i_type.get_immu<RegVal>();
        rs1 = inst_t.i_type.rs1;
        rs2 = 0;
        to_exe.alu_sel0 = ALU_PORT0_RS1;
        to_exe.alu_sel1 = ALU_PORT1_RS2;
      } else {
        to_exe.csr_op = CSR_OP_RWI;
        to_exe.imm = inst_t.r_type.funct3;
        to_exe.csr_idx = inst_t.r_type.funct7;
      }
      break;
    }
    to_exe.rs1 = regfile.read_port(rs1);
    to_exe.rs2 = regfile.read_port(rs2);
    to_exe.pc = from_fetch.pc;

    // assume every branch taken
    to_exe.bp_taken   = true && to_exe.is_branch;
    to_fetch.bp_taken = true && to_exe.is_branch;

    if (from_wb.reg_we) {
      regfile.write_port(from_wb.dst_reg, from_wb.wb_data);
    }

    check_data_hazard(rs1, rs2);
    if(from_fetch.flush){
      to_exe.flush();
      to_fetch.flush();

    }
  }

  void check_data_hazard(int rs1 , int rs2) {
    if (from_wb.reg_we) {
      if (from_exe.dst_reg == rs1 && rs1)
        to_exe.rs1 = from_wb.dst_reg;
      if (from_exe.dst_reg == rs2 && rs2)
        to_exe.rs2 = from_wb.dst_reg;
    }

    if (from_mem.reg_we) {
      if (from_exe.dst_reg == rs1 && rs1)
        to_exe.rs1 = from_mem.dst_reg;
      if (from_exe.dst_reg == rs2 && rs2)
        to_exe.rs2 = from_mem.dst_reg;
    }

    if (from_exe.reg_we) {
      if (from_exe.dst_reg == rs1 && rs1)
        to_exe.rs1 = from_exe.dst_reg;
      if (from_exe.dst_reg == rs2 && rs2)
        to_exe.rs2 = from_exe.dst_reg;
    }
  }
};
#endif
