#ifndef __UART_H__
#define __UART_H__
#include "config.h"
#include <cstdio>


class Uart {
  Uart(){}
  void write(int addr, RegVal data){
    if(addr == 0x4){
      printf("%c",(uint8_t)data);
    }
  }
  void read() {
    //TODO:
  }
};
#endif
