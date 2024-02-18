// Minimum reproduction of PipelineC bug
// This should compile but it doesn't, failing on old avalon_sdr.

#pragma PART "5CSEMA5F31C6"

#include "intN_t.h"
#include "uintN_t.h"

#define STR(s) #s
#define XSTR(s) STR(s)

#define MAX_NREAD 64
#define MAX_NWRITE 64
#define MAX_NREAD_BITS 2048
#define MAX_NWRITE_BITS 2048

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
    uint2048_t writedata;
}
avsdr_in;

typedef struct avsdr_out
{
    avmm_out av;
    uint1_t readend;
    uint1_t writeend;
    uint2048_t readdata;
}
avsdr_out;

// Global avalon_sdr signals. Use these 
// signals to read or write to memory.

// address to start reading/writing. Must be a multiple of 4.
uint32_t sdr_baseaddr;
// how many words to read/write
uint30_t sdr_nelems;
// data is read into this buffer
uint2048_t sdr_readdata;
// data is written from this buffer
uint2048_t sdr_writedata;

// start a read operation
uint1_t sdr_readstart = 0;
// start a write operation
uint1_t sdr_writestart = 0;

// true if read operation has ended
uint1_t sdr_readend;
// true if write operation has ended
uint1_t sdr_writeend;


#pragma FUNC_BLACKBOX avalon_sdr
avsdr_out avalon_sdr(avsdr_in inputs)
{
    __vhdl__("\n\
    component avalon_sdr is \n\
        generic ( \n\
            MAX_NREAD            : integer := 1; \n\
            MAX_NWRITE           : integer := 1 \n\
        ); \n\
        port ( \n\
            clk                  : in  std_logic; \n\
            reset                : in  std_logic; \n\
            avm_m0_read          : out std_logic; \n\
            avm_m0_write         : out std_logic; \n\
            avm_m0_writedata     : out std_logic_vector(15 downto 0); \n\
            avm_m0_address       : out std_logic_vector(31 downto 0); \n\
            avm_m0_readdata      : in  std_logic_vector(15 downto 0); \n\
            avm_m0_readdatavalid : in  std_logic; \n\
            avm_m0_byteenable    : out std_logic_vector(1 downto 0); \n\
            avm_m0_waitrequest   : in  std_logic; \n\
            sdr_baseaddr         : in  std_logic_vector(31 downto 0); \n\
            sdr_nelems           : in  std_logic_vector(29 downto 0); \n\
            sdr_readdata         : out std_logic_vector((" XSTR(MAX_NREAD_BITS) "-1) downto 0); \n\
            sdr_writedata        : in  std_logic_vector((" XSTR(MAX_NWRITE_BITS) "-1) downto 0); \n\
            sdr_readstart        : in  std_logic; \n\
            sdr_readend          : out std_logic; \n\
            sdr_writestart       : in  std_logic; \n\
            sdr_writeend         : out std_logic \n\
        ); \n\
    end component; \n\
    \n\
    begin \n\
    inst : avalon_sdr \n\
        generic map ( \n\
            MAX_NREAD                   =>" XSTR(MAX_NREAD) ", \n\
            MAX_NWRITE                  =>" XSTR(MAX_NWRITE) " \n\
        ) \n\
        port map ( \n\
            clk                         => clk, \n\
            reset                       => inputs.av.reset(0), \n\
            avm_m0_read                 => return_output.av.read(0), \n\
            avm_m0_write                => return_output.av.write(0), \n\
            unsigned(avm_m0_writedata)  => return_output.av.writedata, \n\
            unsigned(avm_m0_address)    => return_output.av.address, \n\
            avm_m0_readdata             => std_logic_vector(inputs.av.readdata), \n\
            avm_m0_readdatavalid        => inputs.av.readdatavalid(0), \n\
            unsigned(avm_m0_byteenable) => return_output.av.byteenable, \n\
            avm_m0_waitrequest          => inputs.av.waitrequest(0), \n\
            sdr_baseaddr                => std_logic_vector(inputs.baseaddr), \n\
            sdr_nelems                  => std_logic_vector(inputs.nelems), \n\
            unsigned(sdr_readdata)      => return_output.readdata, \n\
            sdr_writedata               => std_logic_vector(inputs.writedata), \n\
            sdr_readstart               => inputs.readstart(0), \n\
            sdr_readend                 => return_output.readend(0), \n\
            sdr_writestart              => inputs.writestart(0), \n\
            sdr_writeend                => return_output.writeend(0) \n\
        ); \n\
    ");
}

avmm_out setup_avalon_sdr(avmm_in avin)
{
    avsdr_in sdrin;
    sdrin.av = avin;
    sdrin.baseaddr = sdr_baseaddr + 1;
    sdrin.nelems = sdr_nelems;
    sdrin.writedata = sdr_writedata;
    sdrin.readstart = sdr_readstart;
    sdrin.writestart = sdr_writestart;

    avsdr_out sdrout = avalon_sdr(sdrin);

    sdr_readdata = sdrout.readdata;
    sdr_readend = sdrout.readend;
    sdr_writeend = sdrout.writeend;	
    return sdrout.av;
}

#pragma MAIN_MHZ top 100.0
avmm_out top(avmm_in avin)
{
    avmm_out avout = setup_avalon_sdr(avin);

    return avout;
}
