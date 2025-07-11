#ifndef __REGFILE_H__
#define __REGFILE_H__

#include "config.h"
#include <vector>


template <typename Reg=RegVal>

class RegFile_1W2R {
  std::vector<Reg> int_regfile;
  public:
  RegFile_1W2R(int depth)
  : int_regfile(depth)
  {
    int_regfile[0] = 0;
  }

  Reg read_port(int idx){
    assert(idx < int_regfile.size());
    return int_regfile[idx];
  }
  
  void write_port(int idx, Reg data){
    if(idx == 0){
      return;
    }
    assert(idx < int_regfile.size());
    int_regfile[idx] = data;
  }

  void tick() {}
};
#endif
