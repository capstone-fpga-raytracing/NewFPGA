#ifndef DEFS_H
#define DEFS_H

#include "uintN_t.h"
#include "intN_t.h"

typedef struct bv
{
    int32_t cmin[3];
    int32_t cmax[3];
    int32_t ntris;
} bv;

// autogen, see wiki/Automatically-Generated-Functionality
#include "int32_t_array_N_t.h"
#include "bv_array_N_t.h"

typedef struct avsdr_in
{
    uint1_t reset; 
    uint16_t readdata;
    uint1_t readdatavalid;
    uint1_t waitrequest;
    uint1_t readend;
    uint1_t writend;
} 
avsdr_in;

typedef struct avsdr_out
{
    uint1_t read;
    uint1_t write;
    uint32_t address;
    uint2_t byteenable;
    uint16_t writedata;
    uint1_t readstart;
    uint1_t writestart;
} 
avsdr_out;

typedef struct read_all_bvs_out
{
    avsdr_out avout;
    bv_array_128_t BV;
}
read_all_bvs_out;

// read upto 128 BVs from memory
read_all_bvs_out read_all_bvs(avsdr_in avin, uint32_t baseaddr, uint8_t num_bv);

typedef struct main_in
{
    avsdr_in avin;

} main_in;

typedef struct main_out
{
    avsdr_out avout;

} main_out;



#endif