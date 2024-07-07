library ieee;
use ieee.NUMERIC_STD.all;
use ieee.STD_LOGIC_UNSIGNED.all;
use ieee.std_logic_1164.all;

	-- Add your library and packages declaration here ...

entity sixbitprocessor_tb is
end sixbitprocessor_tb;

architecture TB_ARCHITECTURE of sixbitprocessor_tb is
	-- Component declaration of the tested unit
	component sixbitprocessor
	port(
		clk : in STD_LOGIC;
		reset : in STD_LOGIC );
	end component;

	-- Stimulus signals - signals mapped to the input and inout ports of tested entity
	signal clk : STD_LOGIC;
	signal reset : STD_LOGIC;
	-- Observed signals - signals mapped to the output ports of tested entity

	-- Add your code here ...

begin

	-- Unit Under Test port map
	UUT : sixbitprocessor
		port map (
			clk => clk,
			reset => reset
		);

	-- Add your stimulus here ...
	      reset <= '1', '0' after 10ns;
   
   process
   begin
        clk <= '0';
        wait for 10ns;  
        clk <= '1';
        wait for 10ns;  
   end process;
end TB_ARCHITECTURE;

configuration TESTBENCH_FOR_sixbitprocessor of sixbitprocessor_tb is
	for TB_ARCHITECTURE
		for UUT : sixbitprocessor
			use entity work.sixbitprocessor(sixbitprocessorarch);
		end for;
	end for;
end TESTBENCH_FOR_sixbitprocessor;

