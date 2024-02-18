#pragma once

// compiling for Cyclone V
#pragma PART "5CSEMA5F31C6"

#include "intN_t.h"
#include "uintN_t.h"

#define STR(s) #s
#define XSTR(s) STR(s)

// Max words readable/writable at a time.
// This is a pipelinec limitation, avalon_sdr technically 
// allows for much larger sizes (upto 2048 words, not bits).
#define MAX_NREAD 64
#define MAX_NWRITE 64
#define MAX_NREAD_BITS 2048
#define MAX_NWRITE_BITS 2048

#define FIP_POINT_5 0x00008000
#define FIP_ALMOST_ONE 0x0000ffff // largest below 1
#define FIP_ONE 0x00010000 // 1
#define FIP_MIN (-2147483647 - 1) // -32768.0 (min)
#define FIP_MAX 2147483647 // 32767.99998 (max)

#define ABS(x) (((x) > 0) ? (x) : -(x))
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define MAX(a, b) ((a) > (b) ? (a) : (b))


#define AVSDR_RDDATA_T uint2048_t
#define AVSDR_WRDATA_T uint2048_t

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
    AVSDR_WRDATA_T writedata;
}
avsdr_in;

typedef struct avsdr_out
{
    avmm_out av;
    uint1_t readend;
    uint1_t writeend;
    AVSDR_RDDATA_T readdata;
}
avsdr_out;

typedef struct Ray
{
    int32_t origin[3];
    int32_t dir[3];
} Ray;

// ray intersect tri out
typedef struct ritri_out {
	int32_t t;
	uint1_t flag; // Intersect bool
} ritri_out;

typedef struct bv
{
    int32_t cmin[3];
    int32_t cmax[3];
    int32_t ntris;
} bv;

// 3d vector structs

// 3x1
typedef struct Vct_3d {
    int32_t var[3];
} Vct_3d;

// 3x2
typedef struct Ray {
    int32_t origin[3];
    int32_t dir[3];
} Ray;

typedef struct Light {
    int32_t src[3];
    int32_t color[3];
} Light;

// 3x3
typedef struct Vert {
    int32_t v0[3];
    int32_t v1[3];
    int32_t v2[3];
} Vert;

typedef struct Material {
    int32_t ka[3];
    int32_t kd[3];
    int32_t ks[3];
} Material;

// autogen, see wiki/Automatically-Generated-Functionality
#include "bv_array_N_t.h"
