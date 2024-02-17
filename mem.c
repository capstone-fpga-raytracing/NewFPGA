#include "defs.h"

// Global avalon_sdr signals. Use these 
// signals to read or write to memory.
// See read_all_bvs for an example.

// address to start reading/writing. Must be a multiple of 4.
uint32_t sdr_baseaddr;
// how many words to read/write
uint30_t sdr_nelems;
// data is read into this buffer
avsdr_rddata_t sdr_readdata;
// data is written from this buffer
avsdr_wrdata_t sdr_writedata;

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
	// Instantiate avalon_sdr.
	// I copied this from Computer_System.vhd and modified it for pipelineC
	// see wiki/Raw-HDL-Insertion
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
			sdr_writeend         : out std_logic; \n\
		); \n\
	end component avalon_sdr; \n\
    \n\
	avalon_sdr_0 : component avalon_sdr \n\
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

inline avmm_out setup_avalon_sdr(avmm_in avin)
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

// deserialize data into an array of bv types.
// This can be written in C as well but it's a bit more convenient in VHDL
#pragma FUNC_WIRES pack_bvs
bv_array_128_t pack_bvs(avsdr_rddata_t data)
{
    __vhdl__("\n\
    begin \n\
        i_gen: for i in 0 to 127 generate \n\
            return_output.data(i).cmin(0) <= data((32*(7*i+1)-1) downto (32*7*i)); \n\
            return_output.data(i).cmin(1) <= data((32*(7*i+2)-1) downto (32*(7*i+1))); \n\
            return_output.data(i).cmin(2) <= data((32*(7*i+3)-1) downto (32*(7*i+2))); \n\
            return_output.data(i).cmax(0) <= data((32*(7*i+4)-1) downto (32*(7*i+3))); \n\
            return_output.data(i).cmax(1) <= data((32*(7*i+5)-1) downto (32*(7*i+4))); \n\
            return_output.data(i).cmax(2) <= data((32*(7*i+6)-1) downto (32*(7*i+5))); \n\
            return_output.data(i).ntris   <= data((32*(7*i+7)-1) downto (32*(7*i+6))); \n\
        end generate; \n\
	");
}

bv_array_128_t read_all_bvs(uint32_t baseaddr, uint8_t num_bv)
{
	// see wiki/FSM-Style for how FSM states are implied.
	// code reference: examples/arty/src/mnist/eth_app.c#L172
	//
	// what I think this synthesizes:
	// while in state 0 of FSM:
	// at every posedge clk:
	// if (!sdr_readend)
	// ... keep baseaddr, nelems, and readstart asserted
	// ... store sdr_readdata into register data
	// ... if readend, transition to next state of FSM (i.e. beyond loop)
	// end
    avsdr_rddata_t data;
	while (!sdr_readend) 
	{
		sdr_baseaddr = baseaddr;
		sdr_nelems = sizeof(bv) * num_bv;
		sdr_readstart = !sdr_readend;
		data = sdr_readdata;
		__clk();
	}

    return pack_bvs(data);
}