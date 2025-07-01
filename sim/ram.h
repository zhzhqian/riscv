#ifndef __RAM_H__
#define __RAM_H__
#include "config.h"
#include <vector>
template <typename MemCell = DataWidth> class SyncRamDP {
private:
  std::vector<MemCell> data;
  RegVal addr_base;
public:
  SyncRamDP() {}
  SyncRamDP(int memsize, RegVal base) : data(memsize),addr_base(base) {}
  SyncRamDP(std::vector<MemCell> &init_data) : data(init_data) {}
  MemCell read(RegVal addr) {
    RegVal rel_addr = addr - addr_base;
    assert(rel_addr < data.size());
    return data[rel_addr];
  }
  MemCell write(RegVal addr, MemCell w_data) {
    RegVal rel_addr = addr - addr_base;
    assert(rel_addr < data.size());
    data[rel_addr] = w_data;
  }
  SyncRamDP& operator=(const std::vector<RegVal>& o) {
    this->data = o;
    return *this;
  }
};

#endif
