library ieee;
use ieee.NUMERIC_STD.all;
use ieee.STD_LOGIC_UNSIGNED.all;
use ieee.std_logic_1164.all;

	-- Add your library and packages declaration here ...

entity sixbitprocessorwithmultiplier_tb is
	-- Generic declarations of the tested unit
		generic(
		instruction_bits : POSITIVE := 7 );
end sixbitprocessorwithmultiplier_tb;

architecture TB_ARCHITECTURE of sixbitprocessorwithmultiplier_tb is
	-- Component declaration of the tested unit
	component sixbitprocessorwithmultiplier
		generic(
		instruction_bits : POSITIVE := 7 );
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
	UUT : sixbitprocessorwithmultiplier
		generic map (
			instruction_bits => instruction_bits
		)

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

configuration TESTBENCH_FOR_sixbitprocessorwithmultiplier of sixbitprocessorwithmultiplier_tb is
	for TB_ARCHITECTURE
		for UUT : sixbitprocessorwithmultiplier
			use entity work.sixbitprocessorwithmultiplier(sixbitprocessorwithmultiplierarch);
		end for;
	end for;
end TESTBENCH_FOR_sixbitprocessorwithmultiplier;

