#include "defs.h"


int32_t fip_mult(int32_t x, int32_t y) {
    int64_t temp_res = (int64_t)x * (int64_t)y;
    return (int32_t)(temp_res >> 16);
}

int32_t fip_div(int32_t x, int32_t y) {
    int64_t temp_dividend = (int64_t)x << 16;
    int64_t temp_res = temp_dividend / y;
    return (int32_t)temp_res;
}

// saturate (i.e. limit to fip bounds).
int32_t fip_sat(int64_t val)
{
    if (val > FIP_MAX) {
        return FIP_MAX;
    } else if (val < FIP_MIN) {
        return FIP_MIN;
    }
    return (int)val;
}

int32_t fip_sat_div(int32_t x, int32_t y)
{
    int64_t temp = (int64_t)x << 16;
    int64_t res = temp / y;
    return fip_sat(res);
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

int32_t fip_det(Vert vert) {
    /*
    |a b c| v0
    |d e f| v1
    |g h i| v2
    det = a(ei-fh) + b(fg-di) + c(dh-eg)
    */
    int32_t sub1, sub2, sub3;
    sub1 = fip_mult(vert.v1[1], vert.v2[2]) - fip_mult(vert.v1[2], vert.v2[1]);
    sub2 = fip_mult(vert.v1[2], vert.v2[0]) - fip_mult(vert.v1[0], vert.v2[2]);
    sub3 = fip_mult(vert.v1[0], vert.v2[1]) - fip_mult(vert.v1[1], vert.v2[0]);
    return fip_mult(vert.v0[0], sub1) + fip_mult(vert.v0[1], sub2) + fip_mult(vert.v0[2], sub3);
}

uint32_t fip_norm(Vct_3d vct) {
    return fip_sqrt(fip_mult(vct.var[0], vct.var[0]) +
                    fip_mult(vct.var[1], vct.var[1]) +
                    fip_mult(vct.var[2], vct.var[2]));
}

Vct_3d fip_normalize(Vct_3d vct)
{
    Vct_3d normal;

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
