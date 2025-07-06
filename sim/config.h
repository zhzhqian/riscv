#ifndef __CONFIG_H__
#define __CONFIG_H__

#include <cstdint>
#include <iostream>
#include <assert.h>
#include <cstdlib>
#include "log.h"

using RegVal=int32_t;
using RegVal_u=uint32_t;
using u32=uint32_t;

#define AddrWidth 32
#define DataWidth 32

#define XLEN 32
#define INST_MEM_SIZE (512 * 1024)
#define INST_MEM_BASE 
#define DMEM_DPETH 16384
#define DMEM_BASE 16384
#define PC_RESET_VALUE (0x40000000)

#endif
