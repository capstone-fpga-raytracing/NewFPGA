#pragma once

#include "uintN_t.h"
#include "intN_t.h"

#define STR(s) #s
#define XSTR(s) STR(s)

#define CONCAT(x, y) x ## y
#define CONCAT3(x, y, z) x ## y ## z
#define XCONCAT3(x, y, z) CONCAT3(x, y, z)

// Max words readable/writable at a time using avalon_sdr.
// This value is arbitrary, we can increase it later if 
// necessary (although there might be synthesis limits 
// beyond widths of 65536).
#define MAX_NREAD 896
#define MAX_NWRITE 256
#define MAX_NREAD_BITS 28672
#define MAX_NWRITE_BITS 8192

typedef XCONCAT3(uint, MAX_NREAD_BITS, _t) avsdr_rddata_t;
typedef XCONCAT3(uint, MAX_NWRITE_BITS, _t) avsdr_wrdata_t;

// Input from SDRAM controller in Qsys
typedef struct avmm_in
{
    uint1_t reset; 
    uint16_t readdata;
    uint1_t readdatavalid;
    uint1_t waitrequest;
} 
avmm_in;

// Output to SDRAM controller in Qsys
typedef struct avmm_out
{
    uint1_t read;
    uint1_t write;
    uint32_t address;
    uint2_t byteenable;
    uint16_t writedata;
} 
avmm_out;

typedef struct avsdr_in
{
    avmm_in av;
    uint1_t readstart;
    uint1_t writestart;
    uint32_t baseaddr;
    uint30_t nelems;
    avsdr_wrdata_t writedata;
}
avsdr_in;

typedef struct avsdr_out
{
    avmm_out av;
    uint1_t readend;
    uint1_t writeend;
    avsdr_rddata_t readdata;
}
avsdr_out;


typedef struct bv
{
    int32_t cmin[3];
    int32_t cmax[3];
    int32_t ntris;
} bv;

// autogen, see wiki/Automatically-Generated-Functionality
#include "bv_array_N_t.h"

// read upto 128 BVs from memory
// bv_array_128_t read_all_bvs(uint32_t baseaddr, uint8_t num_bv);
