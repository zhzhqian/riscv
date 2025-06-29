#ifndef __CONFIG_H__
#define __CONFIG_H__

#include <cstdint>
#include <iostream>
#include <assert.h>
#include <cstdlib>

using RegVal=int32_t;
using RegVal_u=uint32_t;
using AddrWidth=uint32_t;
using DataWidth=uint32_t;
using u32=uint32_t;

#define INST_MEM_SIZE (512 * 1024)
#define DMEM_DPETH 16384

#endif
