#ifndef __PIPE_DATA_H__
#define __PIPE_DATA_H__

#include "config.h"
#include "artith_ops.h"

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
  WBSEL_ALU,
  WBSEL_MEM,
  WBSEL_PC,
  WBSEL_SCR,
};

enum ALUDataPort0 {
  ALU_PORT0_PC,
  ALU_PORT0_RS1
};
enum ALUDataPort1 {
  ALU_PORT1_IMM,
  ALU_PORT1_RS2
};


struct HandShake{
  bool ready;
  bool valid;
};

struct FetchTodecode{
  RegVal inst;
  RegVal pc;
  bool flush;
  FetchTodecode():flush(false) {}
};

struct DecodeToFetch{
  RegVal bp_pc;  
  bool bp_taken;
  DecodeToFetch() :bp_taken(false){}
  void flush() {bp_taken = false;}
};

struct EXEToFetch{
  RegVal jump_pc;  
  RegVal exe_pc;  
  bool jump_taken;
  bool bp_fail;
  bool branch_taken;
  EXEToFetch(): jump_taken(false),bp_fail(false),branch_taken(false){}
  void flush(){
    jump_taken = false;
    bp_fail =false;
    branch_taken =false;
  }
};

struct DecodeToEXE {
  int alu_op;
  RegVal pc;
  bool is_branch;
  bool is_jump;
  bool reg_we;
  bool loadu;
  RegVal rs1, rs2, imm;
  int wb_sel;
  int alu_sel0,alu_sel1;
  uint32_t br_op; 
  bool mem_rd, mem_wr;
  int mem_op_size;
  int csr_op;
  int csr_idx;
  int dst_reg;
  bool bp_taken;
  static DecodeToEXE* Bubble() {
    return new DecodeToEXE();
  }
  void flush() {
    bp_taken = false;
    alu_op = ALU_OP_NONE;
    is_branch = false;
    is_jump = false;
    reg_we =false;
    loadu= false;
    wb_sel = WBSEL_ALU;
    mem_rd = false;
    mem_wr = false;
    mem_op_size = Mem_OP_WORD;
    csr_op = CSR_OP_NONE;
  }
  
  DecodeToEXE(){
    flush();
  }
};

struct EXEToDecode {
  bool branch_taken;
  bool reg_we;
  int dst_reg;
  RegVal dst_reg_data;
  EXEToDecode() :reg_we(false) {}
};

struct EXEToMem {
  RegVal alu_out;
  RegVal csr_out;
  RegVal pc;
  bool reg_we;
  int wb_sel;
  bool loadu;
  bool mem_rd,mem_wr;
  bool branch_taken;
  int dst_reg;
  RegVal rs2;
  EXEToMem() :reg_we(false),
    mem_rd(false),
    mem_wr(false),
    branch_taken(false)
    {}
  void flush() {
    reg_we = false;
    mem_rd = false;
    mem_wr = false;
  }
};

struct MemToWB {
  RegVal mem_data;
  RegVal alu_out;
  RegVal csr_out;
  int dst_reg;
  bool reg_we;
  int wb_sel;
  MemToWB() :reg_we(false){}
};

struct WBToDecode {
  RegVal wb_data;
  int dst_reg;
  bool reg_we;
  WBToDecode() :reg_we(false){}
};

struct FetchToEXE {
  bool flush;
  FetchToEXE() :flush(false){}
};

struct MemToDecode {
  bool reg_we;
  int dst_reg;
  RegVal dst_reg_data;
  MemToDecode() :reg_we(false){}
};

#endif
