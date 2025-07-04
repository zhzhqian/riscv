#ifndef __MEMORY_H__
#define __MEMORY_H__

#include "config.h"
// #include "ram.h"
#include <cmath>
#include <vector>

template <typename MemCell = RegVal, typename AddrType = RegVal>
class MemoryUnit {
public:
  virtual void write(AddrType addr, MemCell w_data) = 0;
  virtual MemCell read(AddrType addr) = 0;
};

template <typename MemCell = RegVal, typename AddrType = RegVal>
class SyncRamDP : public MemoryUnit<MemCell, AddrType> {
private:
  std::vector<MemCell> data;

public:
  SyncRamDP() {}
  SyncRamDP(int memsize) : data(memsize) {}
  SyncRamDP(std::vector<MemCell> &init_data) : data(init_data) {}
  MemCell read(AddrType addr) {
    assert(addr < data.size());
    return data[addr];
  }
  void write(AddrType addr, MemCell w_data) {
    assert(addr < data.size());
    data[addr] = w_data;
  }
  SyncRamDP &operator=(const std::vector<MemCell> &o) {
    this->data = o;
    return *this;
  }
};

template <typename DataType>
DataType substitute_bit(DataType data_sub, DataType data_ori, int bit_hi,
                        int bit_low) {
  /* when bit_lo:16, bit_hi:23
   * mask: 0x00ff0000
   * mask_lo: 0x0000ffff
   * mask_hi: 0x00ffffff
   */
  DataType mask_hi = (((DataType)1) << (bit_hi + 1));
  // in case of cyclic shift
  if (mask_hi == 1)
    mask_hi = (DataType)-1;
  else
    mask_hi -= 1;
  DataType mask_lo = (((DataType)1) << bit_low) - 1;
  DataType mask = mask_hi ^ mask_lo;
  return (data_sub & (~mask)) | (mask & (data_ori << bit_low));
}

template <typename MemCell = RegVal, typename AddrType = RegVal>
class MemoryPortMaster;

template <typename MemCell = RegVal, typename AddrType = RegVal>
class MemoryPortSlave {

  struct AttachedMem {
    MemoryUnit<MemCell, AddrType> *mem;
    AddrType mem_base, mem_size;
    AttachedMem(MemoryUnit<MemCell, AddrType> *mem, AddrType mem_base,
                AddrType mem_size) {
      this->mem = mem;
      this->mem_base = mem_base;
      this->mem_size = mem_size;
    }
  };
  std::vector<AttachedMem> attached_mem;

public:
  MemoryPortMaster<MemCell, AddrType> *to;
  MemoryPortSlave() {}
  void attach_mem(MemoryUnit<MemCell, AddrType> *mem, AddrType base,
                  AddrType size) {
    // TODO: check if address range overlap
    this->attached_mem.push_back(AttachedMem(mem, base, size));
  }
  void receive_write(AddrType addr, MemCell data, int size) {
    assert(to != nullptr);
    assert(size <= sizeof(MemCell));
    // assert(addr >= mem_base && addr < mem_base + mem_size);
    // unsupport unaligned access.
    assert((addr & (size - 1)) != 0);
    int offset = addr & ((AddrType)(sizeof(MemCell) - 1));
    for (auto att_mem : attached_mem) {
      if (att_mem.mem_base <= addr &&
          att_mem.mem_base + att_mem.mem_size > addr) {
        if (size < sizeof(data)) {
          MemCell read_data = att_mem.mem->read((addr - att_mem.mem_base) / sizeof(MemCell));
          data = substitute_bit(read_data, data, (offset + size) * 8 - 1,
                                offset * 8);
        }
        att_mem.mem->write(addr - att_mem.mem_base, data);
      }
      break;
    }
  }
  MemCell receive_read(AddrType addr, int size) {
    assert(to != nullptr);
    assert(size <= sizeof(MemCell));
    // use -1 to indicate wrong addr
    MemCell read_data = -1;
    AddrType offset = addr & ((AddrType)(sizeof(MemCell) - 1));
    for (auto att_mem : attached_mem) {
      if (att_mem.mem_base <= addr &&
          att_mem.mem_base + att_mem.mem_size > addr) {
        read_data = att_mem.mem->read((addr - att_mem.mem_base) / sizeof(MemCell));
        if (size < sizeof(MemCell)) {
          read_data =
              substitute_bit(0, read_data, (offset + size) * 8 - 1, offset * 8);
          read_data >>= offset * 8;
        }
        break;
      }
    }
    return read_data;
  }
};

template <typename MemCell, typename AddrType> class MemoryPortMaster {
  MemoryPortSlave<RegVal, AddrType> *to;

public:
  MemoryPortMaster() {}
  void connect(MemoryPortSlave<RegVal, AddrType> *slave) {
    to = slave;
    slave->to = this;
  }
  void issue_write(AddrType addr, MemCell data, int size) {
    to->receive_write(addr, data, size);
  }
  MemCell issue_read(AddrType addr, int size) {
    return to->receive_read(addr, size);
  }
};
#endif
