
#include "config.h"
#include <unordered_map>

class CSR {
  std::unordered_map<int, RegVal> data;
  /* just give me a default constructor */
  RegVal read(int addr) {
    auto res = data.find(addr);
    assert(res != data.end());
    return data[addr];
  }
  void write(int addr, RegVal w_data) {
    auto res = data.find(addr);
    assert(res != data.end());
    data[addr] = w_data;
    if(addr == 0x51e) {
      std::cout << "receive stop signal" <<std::endl;
      std::exit(0);
    }
  }
};
