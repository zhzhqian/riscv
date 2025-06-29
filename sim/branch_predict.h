#ifndef __BRANCH_PREDICT_H__
#define __BRANCH_PREDICT_H__

#include "config.h"
#include <vector>
#include <bitset>

// branch predict table width
#define PHT_WIDTH 2
#define PHT_DEPTH 1024
#define PHT_DEPTH_WIDTH 10
#define PHT_DEPTH_MASK ((1UL <<PHT_DEPTH_WIDTH) -1) 

enum Pattern{
  STRONG_NOT_TAKEN,
  NOT_TAKEN,
  TAKEN,
  STRONG_TAKEN,
};

using PatternEntry = std::bitset<PHT_WIDTH>;
class BranchPredict {

  std::vector<PatternEntry> pht;
  BranchPredict() :pht(PHT_DEPTH,std::bitset<PHT_WIDTH>(0)) {}

  void bp_pattern_next(PatternEntry &entry,bool taken){
    unsigned long cnt =entry.to_ulong();
    cnt += (taken) ? 1:0;
    entry = cnt;
  }

  bool bp_pattern_taken(PatternEntry &entry){
      return entry[PHT_WIDTH -1];
  }

  bool evaluate(int cur_pc, int last_pc, bool last_taken) {
    int pht_idx = cur_pc & PHT_DEPTH_MASK;
    PatternEntry &cur_stat = pht[pht_idx];
    int last_pht_idx = last_pc & PHT_DEPTH_MASK;
    PatternEntry &last_stat = pht[last_pht_idx];
    last_stat |= last_taken;
    bp_pattern_next(last_stat, last_taken);
    return bp_pattern_taken(cur_stat);
  }
};

#endif
