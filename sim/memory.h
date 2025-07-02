#include "config.h"
#include "ram.h"

template <typename MemCell = RegVal, typename AddrType = RegVal>
class MemoryPortMaster;

template <typename MemCell = RegVal, typename AddrType = RegVal>
class MemoryPortSlave {
  MemoryUnit<MemCell,AddrType> *mem;
  MemoryPortMaster<MemCell,AddrType>* to;
  AddrType mem_base, mem_size;
public:
  MemoryPortSlave(){
    to = nullptr;
    mem = nullptr;
  }
  void attach_mem(MemoryUnit<MemCell,AddrType>* attached_mem,AddrType base, AddrType size){
    this->mem_base = base;
    this->mem_size = size;
    this->mem = attached_mem;
  }
  void receive_write(AddrType addr, MemCell data, int size)  {
    assert(to != nullptr);
    assert(addr >= mem_base && addr < mem_base + mem_size);
    AddrType offset = addr - mem_base;
    mem->write(offset,  data);
  }
  MemCell receive_read(AddrType addr,int size)  {}
};

template <typename MemCell, typename AddrType>
class MemoryPortMaster {
  MemoryPortSlave<RegVal,AddrType>* to;
public:
  MemoryPortMaster() {
  }
  void connect(MemoryPortSlave<RegVal,AddrType>* slave)  {
    to = slave;
    slave->to = this;
  }
  void issue_write(AddrType addr, MemCell data, int size)  {
      to->receive_write(addr, data, size);
    }
  MemCell issue_read(AddrType addr,int size)  {
      return to->receive_read(addr, size);
  }
};
