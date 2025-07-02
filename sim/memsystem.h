#ifndef __MEMSYSTEM_H__
#define __MEMSYSTEM_H__

#include "config.h"
#include "memory.h"
#include <fstream>
#include <string>
#include <iomanip>

class MemSystem {
  SyncRamDP<RegVal, RegVal> imem;
  SyncRamDP<RegVal, RegVal> dmem;

public:
  MemoryPortSlave<RegVal, RegVal> port0;
  MemoryPortSlave<RegVal, RegVal> port1;
  MemSystem() : imem(INST_MEM_SIZE), dmem(DMEM_DPETH) {
    // port to cpu data port
    port0.attach_mem(&imem, PC_RESET_VALUE, INST_MEM_SIZE);
    port0.attach_mem(&dmem, 0, DMEM_DPETH);
    // port to cpu inst port
    port1.attach_mem(&imem, PC_RESET_VALUE, INST_MEM_SIZE);
  }
  void load_mif(std::string file_name) {
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
      if (idx < 10) {
        std::cout << "line:" << line << std::endl;
        std::cout << "load_data:" << idx << ":" << std::hex << std::setw(8)
                  << tmp << std::endl;
      }
      mif_data.push_back(tmp);
      idx++;
    }

    imem = mif_data;
  }
  void load_image(std::string file_name){}
};

#endif
