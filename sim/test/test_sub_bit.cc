#include <cstdint>
#include <stdio.h>
template <typename DataType = uint32_t>
DataType substitute_bit(DataType data_sub, DataType data_ori, int bit_hi,int bit_low){
  /* when bit_lo:16, bit_hi:23
   * mask: 0x00ff0000 
   * mask_lo: 0x0000ffff
   * mask_hi: 0x00ffffff
   */
  DataType mask_hi = (((DataType)1) << (bit_hi + 1));
  if(mask_hi == 1)  mask_hi = (DataType) -1;
  else mask_hi -= 1;
  DataType mask_lo = (((DataType)1) << bit_low) - 1;
  DataType mask = mask_hi ^ mask_lo;
  return (data_sub & (~mask)) | (mask&(data_ori << bit_low));
}

template <typename DataType = uint32_t>
DataType substitute_bit_ref(DataType data_sub, DataType data_ori, int bit_hi,int bit_low){
  DataType res =0;

  for (int i = bit_low; i <= bit_hi; i++) {
    if(data_ori &((DataType)(1) << (i - bit_low)))
      data_sub |= ~((DataType)(1) << i);
    else
      data_sub &= ~((DataType)(1) << i);
  }
  return data_sub;
}

int main(){
  uint32_t data_sub_arr[]={0x12345678};
  uint32_t data_ori_arr[]={0x9};
  uint32_t bit_low_arr[] = {0, 8,16,24, 0,16, 8, 0, 8};
  uint32_t bit_hi_arr[]  = {7,15,23,31,15,31,23,23,31};
  for(int i=0;i<sizeof(bit_hi_arr)/sizeof(bit_hi_arr[0]);i++){
    uint32_t res =substitute_bit(data_sub_arr[0], data_ori_arr[0], bit_hi_arr[i], bit_low_arr[i]);
    uint32_t exp =substitute_bit_ref(data_sub_arr[0], data_ori_arr[0], bit_hi_arr[i], bit_low_arr[i]);
    if(res != exp){
      printf("bit_hi:%d, bit_lo:%d res:%x, exp:%x\n", bit_hi_arr[i], bit_low_arr[i], res, exp);
    }
  }
}
