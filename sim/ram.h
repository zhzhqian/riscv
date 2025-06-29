#include "config.h"
#include <vector>
template <typename MemCell=DataWidth>
class SyncRamDP {
  private:
  std::vector<MemCell> data;
  public:
  SyncRamDP(int memsize) : data(memsize) {}
  MemCell read(int addr) {
    assert(addr < data.size());
    return data[addr];
  }
  MemCell write(int addr, MemCell w_data) {
    assert(addr < data.size());
    data[addr] = w_data;
  }
};

