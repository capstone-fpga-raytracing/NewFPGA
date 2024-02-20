-- verilog compatible binding, update this when top module from pipelinec changes

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.c_structs_pkg.all;

entity top_v is
port(
  clk100         : in std_logic;
  start          : in std_logic;
  sdr_readend    : in std_logic;
  sdr_writeend   : in std_logic;
  sdr_readdata   : in std_logic_vector(2047 downto 0);
  sdr_readstart  : out std_logic;
  sdr_writestart : out std_logic;
  sdr_baseaddr   : out std_logic_vector(31 downto 0);
  sdr_nelems     : out std_logic_vector(29 downto 0);
  sdr_writedata  : out std_logic_vector(2047 downto 0);
  hex            : out std_logic_vector(3 downto 0);
  hex_valid      : out std_logic
  );
end top_v;

architecture arch of top_v is

signal top_topin : top_in;
signal top_topout : top_out;

-- stupid conversion fn required by vhdl
function sl2unsigned (x: std_logic) return unsigned is
begin
   if x='1' then 
      return to_unsigned(1,1); 
   else 
      return to_unsigned(0,1); 
   end if;
end;

begin

top : entity work.top port map (
   clk100,
   top_topin,
   top_topout
);

top_topin.start <= sl2unsigned(start);
top_topin.sdrin.readend <= sl2unsigned(sdr_readend);
top_topin.sdrin.writeend <= sl2unsigned(sdr_writeend);
top_topin.sdrin.readdata <= unsigned(sdr_readdata);
sdr_readstart <= top_topout.sdrout.readstart(0);
sdr_writestart <= top_topout.sdrout.writestart(0);
sdr_baseaddr <= std_logic_vector(top_topout.sdrout.baseaddr);
sdr_nelems <= std_logic_vector(top_topout.sdrout.nelems);
sdr_writedata <= std_logic_vector(top_topout.sdrout.writedata);
hex <= std_logic_vector(top_topout.hex);
hex_valid <= top_topout.hex_valid(0);

end arch;
