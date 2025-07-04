#include "riscv.h"
#include "config.h"

/*
 bios_ram:0x4000_0000 -
 imem:
 dmem:
*/
TinyRiscv::TinyRiscv()
    : fetch(PC_RESET_VALUE, fetch_to_decode, dec_to_fetch, exe_to_fetch,
            fetch_to_exe, imem_port),
      dec(fetch_to_decode, exe_to_decode, decode_to_exe, wb_to_decode,
          mem_to_decode,dec_to_fetch),
      exe(exe_to_fetch, decode_to_exe, exe_to_mem, fetch_to_exe),
      mem(exe_to_mem, mem_to_wb, dmem_port), wb(mem_to_wb, wb_to_decode) {}

void TinyRiscv::reset() {
  //TODO: reset all stages
}


void TinyRiscv::tick() {
  cycles++;
  fetch.tick();
  dec.tick();
  exe.tick();
  mem.tick();
  wb.tick();
}


