library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Responsible for managing the program counter.
entity CtrlFetch is
port ( 
	i_clk:			in std_logic;
	i_reset:			in std_logic;
	-- control path
	i_mode12K:		in std_logic_vector(1 downto 0); -- if 00 adder +1, 01 adder +2, 10 adder 1 + K <i_K>
	i_modeAddZA:	in std_logic_vector(1 downto 0); -- if 0 PC load from Adder, 01 load from Z to PC (for IJMP), 10 load from A(for ret) 
	i_modePCZ:		in std_logic; -- if 1, will load Z reg to PM address (for command)
	i_loadPC:		in std_logic; -- if 1, will load value to PC from MUX <modeAddZA>
	i_loadIR:		in std_logic; -- if 1, will load value from 
	-- data mem <i_PMDATA> to <s_IR> and at the next clk data will be at <o_IR>
	i_K:				in unsigned(15 downto 0); -- input constant for RJMP K, PC WILL be k+1
	i_A:				in unsigned(15 downto 0);
	i_Z:				in unsigned(15 downto 0);
	o_IR:				out unsigned(15 downto 0);
	o_PMDATA:		out unsigned(15 downto 0); --out of program memory (direct from <i_pmdata>>
	-- memory interface
	o_PMADDR:		out unsigned(15 downto 0); -- connected to addr input of memory
	i_PMDATA:		in unsigned(15 downto 0) --connected to the output of program mem
);
end CtrlFetch;

architecture Behavioral of CtrlFetch is

-- registers
signal s_PC: unsigned(15 downto 0);
signal s_IR: unsigned(15 downto 0);

-- asynchronous internal signals
signal s_adderInput1: unsigned(15 downto 0);
signal s_adderOutput: unsigned(15 downto 0);
signal s_pcInput: unsigned(15 downto 0);
signal s_addr: unsigned(15 downto 0);

begin

-- adder with multiplexer for second operand (1, 2, K)
s_adderOutput <= s_adderInput1 + s_PC;
s_adderInput1 <= 
	"0000000000000001" when i_mode12K = "00" else 
	"0000000000000010" when i_mode12K = "01" else 
	i_K;

-- input multiplexer for PC
s_pcInput <=
	i_Z when i_modeAddZA = "10" else
	i_A when i_modeAddZA = "11" else
	s_adderOutput;

-- multiplexer for the PM address
s_addr <=
	s_PC when i_modePCZ = '0' else
	i_Z;

-- memory interface
o_PMADDR <= s_addr;
o_PMDATA <= i_PMDATA; -- preview of next instruction word

o_IR <= s_IR;

-- synchronously loading PC and IR
process (i_clk)
begin
	if rising_edge(i_clk) then
		if i_reset = '1' then
			s_PC <= (others => '0');
			s_IR <= (others => '0');
		else
			if i_loadPC = '1' then
				s_PC <= s_pcInput;
			end if;
			if i_loadIR = '1' then
				s_IR <= i_PMDATA;
			end if;
		end if;
	end if;
end process;

end Behavioral;
