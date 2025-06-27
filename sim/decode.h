#include "config.h"
#include "pipe_data.h"
#include "artith_ops.h"
#include <cstdint>

#define BIT(x) (1UL << (x))
//my definition of opcode
#define LUI_OP 0b0110111
#define AUIPC_OP 0b0010111
#define JAL_OP 0b1101111
#define JALR_OP 0b1100111

#define BRANCH_OP 0b1100011

#define LOAD_OP 0b0000011

#define STORE_OP 0b0100011

#define ARITH_IMM_OP 0b0010011

#define ARITH_REG_OP 0b0110011

#define CSR_OP 0b1110011
#define CSRRWI_FUNCT 0b101
#define CSRRW_FUNCT 0b001

#define BEQ_FUNCT 0b000
#define BNE_FUNCT 0b001
#define BLT_FUNCT 0b100
#define BGE_FUNCT 0b101
#define BLTU_FUNCT 0b110
#define BGEU_FUNCT 0b111


#define LB_FUNCT 0b000
#define LH_FUNCT 0b001
#define LW_FUNCT 0b010
#define LBU_FUNCT 0b100
#define LHU_FUNCT 0b101

#define SB_FUNCT 0b000
#define SH_FUNCT 0b001
#define SW_FUNCT 0b010


#define ADDI_FUNCT 0b000
#define SLTI_FUNCT 0b010
#define SLTIU_FUNCT 0b011
#define XORI_FUNCT 0b100
#define ORI_FUNCT 0b110
#define ANDI_FUNCT 0b111
#define SLLI_FUNCT 0b001
#define SRLI_FUNCT 0b101
#define SRAI_FUNCT 0b101

#define ADD_FUNCT 0b000
#define SLL_FUNCT 0b001
#define SLT_FUNCT 0b010
#define SLTU_FUNCT 0b011
#define XOR_FUNCT 0b100
#define SRL_FUNCT 0b101
#define OR_FUNCT 0b110
#define AND_FUNCT 0b111



enum MemOpSizeType{
  Mem_OP_Byte = 0b000,
  Mem_OP_Half = 0b001,
  Mem_OP_WORD = 0b010,
  Mem_OP_Byte_U = 0b100,
  Mem_OP_Half_U = 0b101,
};

enum WriteBackSel{
  WBSEL_00,
  WBSEL_01,
  WBSEL_10,
  WBSEL_11,
};

enum ALUDataPort0 {
  ALU_PORT0_PC,
  ALU_PORT0_RS0
};
enum ALUDataPort1 {
  ALU_PORT1_IMM,
  ALU_PORT1_RS1
};

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

struct DecodeToEXE {
  int alu_op;
  bool is_branch;
  bool is_jump;
  bool reg_we;
  bool loadu;
  RegVal rs0, rs1, imm;
  int wb_sel;
  int alu_sel0,alu_sel1;
  uint32_t br_op; 
  bool mem_rd, mem_wr;
  int mem_op_size;
  int csr_op;
  DecodeToEXE(){
    alu_op = ALU_OP_NONE;
    is_branch = false;
    is_jump = false;
    reg_we =false;
    loadu= false;
    wb_sel = WBSEL_01;
    
  }
};

struct EXEToDecode {
  bool branch_taken;
};

union InstType{
    uint32_t inst_raw;
    InstType(uint32_t inst){
      inst_raw=inst;
    }
    uint32_t get_sign_mask(uint32_t sign, uint32_t bit_low, uint32_t bit_hi) {
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
  Decode(FetchTodecode &fetch_to_decode, EXEToDecode &exe_to_decode,
         DecodeToEXE &decode_to_exe)
      : inpFromFetch(fetch_to_decode), inpFromEXE(exe_to_decode),
        outToEXE(decode_to_exe) {}
  void tick() {
    inst = inpFromFetch.inst;
    InstType inst_t = (InstType)inst;
    // default imm
    outToEXE.imm = inst_t.i_type.get_imm<RegVal>();
    switch (inst_t.i_type.opcode) {
      case(LUI_OP):
        outToEXE.reg_we = true;
        outToEXE.imm = inst_t.u_type.get_imm<RegVal>();
        outToEXE.wb_sel = WBSEL_11;
        break;
      case(AUIPC_OP):
        outToEXE.reg_we = true;
        outToEXE.imm = inst_t.u_type.get_imm<RegVal>();
        outToEXE.alu_sel0 = ALU_PORT0_PC;
        outToEXE.wb_sel = WBSEL_01;
        break;
      case(JAL_OP):
        outToEXE.reg_we = true;
        outToEXE.is_jump = true;
        outToEXE.alu_sel0 = ALU_PORT0_PC;
        outToEXE.wb_sel = WBSEL_00;
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
        break;
      case(STORE_OP):
        outToEXE.mem_wr = true;
        outToEXE.mem_op_size = inst_t.s_type.funct3; 
        outToEXE.imm = inst_t.s_type.get_imm<RegVal>();
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
        outToEXE.imm = inst_t.i_type.get_immu<RegVal>();
        if(inst_t.r_type.funct3 == CSRRW_FUNCT)
          outToEXE.csr_op = CSR_OP_RW;
        else
          outToEXE.csr_op = CSR_OP_RWI;
        break;
    }

    
  }

  void control() {
    
  }
};
