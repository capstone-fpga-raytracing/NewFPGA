// compiling for Cyclone V
#pragma PART "5CSEMA5F31C6"

#include "intN_t.h"
#include "uintN_t.h"

#define STR(s) #s
#define XSTR(s) STR(s)

// Max words readable/writable at a time.
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

// Global avalon_sdr signals. Use these 
// signals to read or write to memory.
// See read_all_bvs for an example.

// address to start reading/writing. Must be a multiple of 4.
uint32_t sdr_baseaddr;
// how many words to read/write
uint30_t sdr_nelems;
// data is read into this buffer
AVSDR_RDDATA_T sdr_readdata;
// data is written from this buffer
AVSDR_WRDATA_T sdr_writedata;

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
    sdrin.baseaddr = sdr_baseaddr;
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

// deserialize data into a bv array
// This can be written in C as well but it's a bit more convenient in VHDL
#pragma FUNC_WIRES pack_bvs
bv_array_9_t pack_bvs(AVSDR_RDDATA_T data)
{
    __vhdl__("\n\
    begin \n\
        i_gen: for i in 0 to 8 generate \n\
            return_output.data(i).cmin(0) <= signed(data((32*(7*i+1)-1) downto (32*7*i))); \n\
            return_output.data(i).cmin(1) <= signed(data((32*(7*i+2)-1) downto (32*(7*i+1)))); \n\
            return_output.data(i).cmin(2) <= signed(data((32*(7*i+3)-1) downto (32*(7*i+2)))); \n\
            return_output.data(i).cmax(0) <= signed(data((32*(7*i+4)-1) downto (32*(7*i+3)))); \n\
            return_output.data(i).cmax(1) <= signed(data((32*(7*i+5)-1) downto (32*(7*i+4)))); \n\
            return_output.data(i).cmax(2) <= signed(data((32*(7*i+6)-1) downto (32*(7*i+5)))); \n\
            return_output.data(i).ntris   <= signed(data((32*(7*i+7)-1) downto (32*(7*i+6)))); \n\
        end generate; \n\
    ");
}

bv_array_9_t read_all_bvs(uint32_t baseaddr, uint8_t num_bv)
{
    // see wiki/FSM-Style for how FSM states are implied.
    // code reference: examples/arty/src/mnist/eth_app.c#L172
    //
    // what I think this synthesizes?
    // while in state 0 of FSM:
    // at every posedge clk:
    // if (!sdr_readend)
    // ... keep baseaddr, nelems, and readstart asserted
    // ... store sdr_readdata into register data
    // ... if readend, transition to next state of FSM (i.e. beyond loop)
    // end
    AVSDR_RDDATA_T data;
    while (!sdr_readend) 
    {
        sdr_baseaddr = baseaddr;
        sdr_nelems = 7 * num_bv;
        sdr_readstart = !sdr_readend;
        data = sdr_readdata;
        __clk();
    }

    return pack_bvs(data);
}

// For testing, return bv array so we can display a value from it on hex.
bv_array_9_t main()
{
    bv_array_9_t BV = read_all_bvs(0, 9);
    __clk();
    return BV;
}

// this indicates that main() is an FSM.
// see wiki/FSM-Style.
#include "main_FSM.h"

// Top level module inputs
typedef struct top_in
{
    avmm_in avin;
    // add more if needed
} top_in;

// Top level module outputs
typedef struct top_out
{
    avmm_out avout;
    uint4_t hex[6];
    // add more if needed
} top_out;

#pragma MAIN_MHZ top 100.0 // clock freq
top_out top(top_in topin)
{
    top_out topout;
    // sets up all the avalon_sdr signals
    // as global variables. See mem.c
    topout.avout = setup_avalon_sdr(topin.avin);

    // instantiating FSMs done this way
    // see wiki/FSM-Style
    main_INPUT_t i;
    i.input_valid = 1;
    i.output_ready = 1;
    main_OUTPUT_t o = main_FSM(i);
    
    topout.hex[0] = (uint4_t)(o.return_output.data[0].cmin[0] & 0xF);
    
    return topout;
}
