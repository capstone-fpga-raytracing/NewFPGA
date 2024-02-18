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


typedef struct bv
{
    int32_t cmin[3];
    int32_t cmax[3];
    int32_t ntris;
} bv;

// autogen, see wiki/Automatically-Generated-Functionality
#include "bv_array_N_t.h"

