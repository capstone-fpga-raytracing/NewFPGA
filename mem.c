#include "defs.h"

#pragma FUNC_WIRES pack_bvs
bv_array_128_t pack_bvs(int32_t_array_896_t in)
{
    __vhdl__("\
    begin \n\
        i_gen: for i in 0 to 127 generate \n\
            return_output.data(i).cmin(0) <= in.data(7*i); \n\
            return_output.data(i).cmin(1) <= in.data(7*i + 1); \n\
            return_output.data(i).cmin(2) <= in.data(7*i + 2); \n\
            return_output.data(i).cmax(0) <= in.data(7*i + 3); \n\
            return_output.data(i).cmax(1) <= in.data(7*i + 4); \n\
            return_output.data(i).cmax(2) <= in.data(7*i + 5); \n\
            return_output.data(i).ntris <= in.data(7*i + 6); \n\
        end generate; \n\
");
}

typedef struct avmm_read_bv_out
{
    int32_t_array_896_t data;
    avsdr_out avout;
} avmm_read_bv_out;

#pragma FUNC_BLACKBOX avmm_read_bv
avmm_read_bv_out avmm_read_bv(avsdr_in avin, uint32_t baseaddr, uint8_t num_bv)
{
    __vhdl__("\
    component avalon_sdr is \n\
		generic ( \n\
			MAX_NREAD            : integer := 896; \n\
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
			sdr_baseaddr         : in std_logic_vector(31 downto 0); \n\
            sdr_nelems           : in std_logic_vector(29 downto 0); \n\
            output logic [MAX_NREAD][31:0] sdr_readdata,
            input  logic [MAX_NWRITE][31:0] sdr_writedata,
            input  logic sdr_readstart,
            output logic sdr_readend,
            input  logic sdr_writestart,
            output logic sdr_writeend
		);
	end component avalon_sdr;
    component avalon_sdr
		generic map (
			NREAD          => 15,
			NWRITE         => 2,
			READ_BASEADDR  => "00000000000000000000000000000000",
			WRITE_BASEADDR => "00000000000000000000000000100000"
		)
		port map (
			clk                  => system_pll_sys_clk_clk,
			reset                => rst_controller_003_reset_out_reset,
			avm_m0_read          => avalon_sdr_0_m0_read,
			avm_m0_write         => avalon_sdr_0_m0_write,
			avm_m0_writedata     => avalon_sdr_0_m0_writedata,
			avm_m0_address       => avalon_sdr_0_m0_address,
			avm_m0_readdata      => avalon_sdr_0_m0_readdata,
			avm_m0_readdatavalid => avalon_sdr_0_m0_readdatavalid,
			avm_m0_byteenable    => avalon_sdr_0_m0_byteenable,
			avm_m0_waitrequest   => avalon_sdr_0_m0_waitrequest,
			sdr_readdata         => sdr_readdata_export,
			sdr_readstart        => avalon_control_0_do_read_export,
			sdr_readend          => sdr_readend_export,
			sdr_clk              => sdr_clk_clk,
			sdr_writedata        => sdr_writedata_export,
			sdr_writestart       => sdr_writestart_export,
			sdr_writeend         => sdr_writeend_export
		);
    ");
}


read_all_bvs_out read_all_bvs(avsdr_in avin)
{
    int32_t_array_896_t words;

    read_all_bvs_out out;
    out.BV = pack_bvs(words);
    out.avout 
}