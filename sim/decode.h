#include "config.h"
#include "pipe_data.h"
#include "artith_ops.h"
#include <cstdint>
#include "regfile.h"

static inline int funct_to_brachop(uint32_t funct){
  // funct equals branch op
  return funct;
}

static inline int arith_funct_to_aluop(uint32_t funct, uint32_t bit_30){
  switch(funct){
    case ADDI_FUNCT : return ALU_OP_ADD;
    case SLTI_FUNCT : return ALU_OP_LT;
    case SLTIU_FUNCT : return ALU_OP_LTU;
    case XORI_FUNCT : return ALU_OP_XOR;
    case ORI_FUNCT : return ALU_OP_OR;
    case ANDI_FUNCT : return ALU_OP_AND;
    case SLLI_FUNCT : return ALU_OP_SLL;
    case SRLI_FUNCT :
      if(bit_30)
        return ALU_OP_SRA;
      else
        return ALU_OP_SRL;
    default:
      std::cerr<<"unrecognized arith_imm funct"<<std::endl;
  }
  return funct;
}
// TODO: sel logic shift or arith shift
static inline int arith_imm_funct_to_aluop(uint32_t funct, uint32_t bit_30){
  switch(funct){
    case ADD_FUNCT:
       if(bit_30)
         return ALU_OP_SUB;
       else
         return ALU_OP_ADD;
    case SLL_FUNCT: return ALU_OP_SLL;
    case SLT_FUNCT: return ALU_OP_LT;
    case SLTU_FUNCT: return ALU_OP_LTU;
    case XOR_FUNCT: return ALU_OP_XOR;
    case SRL_FUNCT:
       if(bit_30)
         return ALU_OP_SRA;
       else
         return ALU_OP_SRL;
    case OR_FUNCT: return ALU_OP_ADD;
    case AND_FUNCT: return ALU_OP_ADD;
      default:
      std::cerr<<"unrecognized arith_imm funct"<<std::endl;
  }
  return funct;
}

union InstType{
    uint32_t inst_raw;
    InstType(uint32_t inst){
      inst_raw=inst;
    }
    static uint32_t get_sign_mask(uint32_t sign, uint32_t bit_low, uint32_t bit_hi) {
      u32 sign_mask = 0;
      if(sign) {
        sign_mask |= (~0U) & ((~0U) >> bit_hi) &((~0U) << bit_low);
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
  }r_type;
  struct IType {
    uint32_t opcode : 7;
    uint32_t rd : 5;
    uint32_t funct3 : 3;
    uint32_t rs1 : 5;
    uint32_t imm0 : 5;
    uint32_t imm1 : 7;
    template<typename T>
    T get_imm(){
      return (T)(this->imm0 | (this->imm1 << 5) | InstType.get_sign_mask(this->imm1 >> 6));
    }
    template<typename T>
    T get_shm(){
      return (T)(this->imm0 | InstType.get_sign_mask(this->imm1 >> 6));
    }
    template<typename T>
    T get_immu(){
      return (T)(this->imm0 | (this->imm1 << 5) | InstType.get_sign_mask(0));
    }
  }i_type;
  struct SType {
    uint32_t opcode : 7;
    uint32_t imm_lo : 5;
    uint32_t funct3 : 3;
    uint32_t rs1 : 5;
    uint32_t rs2 : 5;
    uint32_t imm_hi : 7;
    template<typename T>
    T get_imm(){
      return (T)(this->imm_lo | (this->imm_hi << 5) | InstType.get_sign_mask(this->imm_hi >> 6));
    }
  }s_type;
  struct BType {
    uint32_t opcode : 7;
    uint32_t imm_11 : 1;
    uint32_t imm_lo : 4;
    uint32_t funct3 : 3;
    uint32_t rs1 : 5;
    uint32_t rs2 : 5;
    uint32_t imm_hi : 6;
    uint32_t imm_12 : 1;
    template<typename T>
    T get_imm(){
      return (T)((this->imm_11 << 12) | (this->imm_11 << 11)
                  | this->imm_lo | (this->imm_hi << 4) | InstType.get_sign_mask(this->imm_12));
    }
  }b_type;
  struct UType {
    uint32_t opcode : 7;
    uint32_t rd : 5;
    uint32_t imm: 20;
    template<typename T>
    T get_imm(){
      return (T)(this->imm << 12);
    }
  }u_type;
  struct JType {
    uint32_t opcode : 7;
    uint32_t rd : 5;
    uint32_t imm_19_12 : 8;
    uint32_t imm_11 : 1;
    uint32_t imm_10_1 : 10;
    uint32_t imm_20 : 1;
    template<typename T>
    T get_imm(){
      return (T)((this->imm_20 << 20)| (this->imm_19_12 << 12)|
                 (this->imm_11 << 11)| (this->imm_10_1 << 1) |
                InstType.get_sign_mask(this->imm_20));
    }
  }j_type;
};

static_assert(sizeof(InstType) == 4, "instruction format is not correct");

class Decode {
  FetchTodecode &inpFromFetch;
  EXEToDecode &inpFromEXE;
  DecodeToEXE &outToEXE;
  RegVal inst;
  RegFile_1W2R<RegVal> regfile;

  Decode(FetchTodecode &fetch_to_decode, EXEToDecode &exe_to_decode,
         DecodeToEXE &decode_to_exe)
      : inpFromFetch(fetch_to_decode), inpFromEXE(exe_to_decode),
        outToEXE(decode_to_exe),
        regfile(32) {}
  void tick() {
    inst = inpFromFetch.inst;
    InstType inst_t = (InstType)inst;
    // default imm
    outToEXE.imm = inst_t.i_type.get_imm<RegVal>();
    outToEXE.pc = inpFromFetch.pc;
    int rs1= inst_t.r_type.rs1;
    int rs2=inst_t.r_type.rs2;
    outToEXE.dst_reg = inst_t.r_type.rd;
    switch (inst_t.i_type.opcode) {
      case(LUI_OP):
        outToEXE.reg_we = true;
        outToEXE.imm = inst_t.u_type.get_imm<RegVal>();
        outToEXE.wb_sel = WBSEL_ALU;
        break;
      case(AUIPC_OP):
        outToEXE.reg_we = true;
        outToEXE.imm = inst_t.u_type.get_imm<RegVal>();
        outToEXE.alu_sel0 = ALU_PORT0_PC;
        outToEXE.wb_sel = WBSEL_ALU;
        break;
      case(JAL_OP):
        outToEXE.reg_we = true;
        outToEXE.is_jump = true;
        outToEXE.alu_sel0 = ALU_PORT0_PC;
        outToEXE.wb_sel = WBSEL_;
        outToEXE.imm = inst_t.j_type.get_imm<RegVal>();
        break;
      case(JALR_OP):
        outToEXE.reg_we = true;
        outToEXE.is_jump = true;
        outToEXE.imm = inst_t.i_type.get_imm<RegVal>();
        outToEXE.wb_sel = WBSEL_00;
        break;
      case(BRANCH_OP):
        outToEXE.is_branch=true;
        outToEXE.wb_sel = WBSEL_01;
        outToEXE.alu_sel0 = ALU_PORT0_PC;
        outToEXE.imm = inst_t.b_type.get_imm<RegVal>();
        outToEXE.br_op = funct_to_brachop(inst_t.b_type.funct3);
        break;
      case(LOAD_OP):
        outToEXE.mem_rd = true;
        outToEXE.reg_we = true;
        outToEXE.mem_op_size = inst_t.i_type.funct3; 
        outToEXE.imm = inst_t.i_type.get_imm<RegVal>();
        outToEXE.alu_op = ALU_OP_ADD;
        break;
      case(STORE_OP):
        outToEXE.mem_wr = true;
        outToEXE.mem_op_size = inst_t.s_type.funct3; 
        outToEXE.imm = inst_t.s_type.get_imm<RegVal>();
        outToEXE.alu_op = ALU_OP_ADD;
        break;
      case(ARITH_IMM_OP):
        outToEXE.reg_we = true;
        if( inst_t.i_type.funct3 == SLLI_FUNCT ||
            inst_t.i_type.funct3 == SRLI_FUNCT  ){
          outToEXE.imm = inst_t.i_type.get_shm<RegVal>();
        }
        outToEXE.alu_op = arith_imm_funct_to_aluop(inst_t.i_type.funct3, inst_t.inst_raw & BIT(31));
        break;
      case(ARITH_REG_OP):
        outToEXE.reg_we = true;
        outToEXE.alu_sel1 =ALU_PORT1_RS1; 
        outToEXE.alu_op = arith_funct_to_aluop(inst_t.i_type.funct3, inst_t.inst_raw & BIT(31));
        break;
      case(CSR_OP):
        if(inst_t.r_type.funct3 == CSRRW_FUNCT) {
          outToEXE.csr_op = CSR_OP_RW;
          outToEXE.csr_idx =inst_t.r_type.funct7;
        } else {
          outToEXE.csr_op = CSR_OP_RWI;
          outToEXE.imm = inst_t.r_type.funct3;
          outToEXE.csr_idx =inst_t.r_type.funct7;
        }
        break;
    }
    outToEXE.rs1 = regfile.read_port(rs2);
    outToEXE.rs2 = regfile.read_port(rs2);
  }

  void control() {
    
  }
};
