#include "riscv.h"
#include "config.h"

/*
 bios_ram:0x4000_0000 -
 imem:
 dmem:
*/
TinyRiscv::TinyRiscv()
    : imem(INST_MEM_SIZE, PC_RESET_VALUE), dmem(DMEM_DPETH, 0),
      fetch(PC_RESET_VALUE, fetch_to_decode, dec_to_fetch, exe_to_fetch,
            fetch_to_exe, imem),
      dec(fetch_to_decode, exe_to_decode, decode_to_exe, wb_to_decode,
          mem_to_decode,dec_to_fetch),
      exe(exe_to_fetch, decode_to_exe, exe_to_mem, fetch_to_exe),
      mem(exe_to_mem, mem_to_wb, dmem), wb(mem_to_wb, wb_to_decode) {}
void TinyRiscv::reset() {
  imem = SyncRamDP<RegVal>(INST_MEM_SIZE, PC_RESET_VALUE);
  dmem = SyncRamDP<RegVal>(DMEM_DPETH, 0);
}
void TinyRiscv::load_image(std::string file_name) {
  //TODO: load raw image
}
void TinyRiscv::load_mif(std::string file_name) {
  std::string line;
  RegVal tmp;
  int idx = 0;
  std::ifstream mif(file_name);
  std::vector<RegVal> mif_data;
  if (!mif.is_open()) {
    std::cout << "can not open:" << file_name << std::endl;
  }
  while (std::getline(mif, line)) {
    tmp = std::stol(line, NULL, 16);
    // instructions in mif stored in small end
    // tmp = __builtin_bswap32(tmp);
    if(idx < 10){
      std::cout<<"line:"<<line<<std::endl;
      std::cout << "load_data:" << idx << ":" << std::hex << std::setw(8) << tmp
                << std::endl;
      
    }
    mif_data.push_back(tmp);
    idx++;
  }

  imem = mif_data;
}
static unsigned long cycles = 0;
void TinyRiscv::tick() {
  std::cout << "simulating cycle:" << cycles << std::endl;
  fetch.tick();
  dec.tick();
  exe.tick();
  mem.tick();
  wb.tick();
  cycles++;
}


