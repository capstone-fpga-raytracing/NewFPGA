#include "defs.h"


int32_t fip_mult(int32_t x, int32_t y) {
    int64_t temp_res = (int64_t)x * (int64_t)y;
    return (int32_t)(temp_res >> 16);
}

#pragma FUNC_BLACKBOX do_div
int32_t do_div(int48_t x, int32_t y) 
{
__vhdl__("\
  begin \n\
  return_output <= x / y; \n\
");
}

int32_t fip_div(int32_t x, int32_t y) {
    int48_t temp_dividend = (int48_t)x << 16;
    int32_t temp_res = do_div(temp_dividend, y);
    return temp_res;
}

// saturate (i.e. limit to fip bounds).
int32_t fip_sat(int64_t val)
{
    int32_t ret = 0;
    if (val > FIP_MAX) {
        ret = FIP_MAX;
    } else if (val < FIP_MIN) {
        ret = FIP_MIN;
    } else{
        ret = val;
    }
    return (int32_t)ret;
}

int32_t fip_sat_div(int32_t x, int32_t y)
{
    int48_t temp_dividend = (int48_t)x << 16;
    int32_t temp_res = do_div(temp_dividend, y);
    return fip_sat(temp_res);
}

int32_t fip_sat_mult(int32_t x, int32_t y) 
{
    int64_t res = (int64_t)x * (int64_t)y;
    return fip_sat(res >> 16);
}

int32_t fip_sat_add(int32_t x, int32_t y) 
{
    int64_t res = (int64_t)x + y;
    return fip_sat(res);
}

// TO DO: convert to pipelinec
uint32_t fip_sqrt(int32_t x) {
    return x+1;
}

// int32_t fip_det(Vct_3d_t v0, Vct_3d_t v1, Vct_3d_t v2) {
//     /*
//     |a b c| v0
//     |d e f| v1
//     |g h i| v2
//     det = a(ei-fh) + b(fg-di) + c(dh-eg)
//     */
//     int32_t sub1, sub2, sub3;
//     sub1 = fip_mult(v1.var[1], v2.var[2]) - fip_mult(v1.var[2], v2.var[1]);
//     sub2 = fip_mult(v1.var[2], v2.var[0]) - fip_mult(v1.var[0], v2.var[2]);
//     sub3 = fip_mult(v1.var[0], v2.var[1]) - fip_mult(v1.var[1], v2.var[0]);
//     return fip_mult(v0.var[0], sub1) + fip_mult(v0.var[1], sub2) + fip_mult(v0.var[2], sub3);
// }

int32_t fip_det(int32_t v0x, int32_t v0y, int32_t v0z,
                int32_t v1x, int32_t v1y, int32_t v1z,
                int32_t v2x, int32_t v2y, int32_t v2z) {
    /*
    |a b c| v0x, v0y, v0z
    |d e f| v1x, v1y, v1z
    |g h i| v2x, v2y, v2z
    det = a(ei-fh) + b(fg-di) + c(dh-eg)
    */
    int32_t sub1, sub2, sub3;
    sub1 = fip_mult(v1y, v2z) - fip_mult(v1z, v2y);
    sub2 = fip_mult(v1z, v2x) - fip_mult(v1x, v2z);
    sub3 = fip_mult(v1x, v2y) - fip_mult(v1y, v2x);
    return fip_mult(v0x, sub1) + fip_mult(v0y, sub2) + fip_mult(v0z, sub3);
}


uint32_t fip_norm(Vct_3d_t vct) {
    return fip_sqrt(fip_mult(vct.var[0], vct.var[0]) +
                    fip_mult(vct.var[1], vct.var[1]) +
                    fip_mult(vct.var[2], vct.var[2]));
}

Vct_3d_t fip_normalize(Vct_3d_t vct)
{
    Vct_3d_t normal;

    if (vct.var[0] == 0 && vct.var[1] == 0 && vct.var[2] == 0) {
        normal.var[0] = 0;
        normal.var[1] = 0;
        normal.var[2] = 0;
    }
    else {
        uint32_t norm = fip_norm(vct);
        if (norm == 0) {
            vct.var[0] <<= 2;
            vct.var[1] <<= 2;
            vct.var[2] <<= 2;
            norm = fip_norm(vct);
        }
        normal.var[0] = fip_div(vct.var[0], norm);
        normal.var[1] = fip_div(vct.var[1], norm);
        normal.var[2] = fip_div(vct.var[2], norm);
    }
    return normal;
}
