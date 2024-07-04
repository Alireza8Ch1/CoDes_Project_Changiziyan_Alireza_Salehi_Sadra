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
	type Memory_TYPE is array (63 downto 0) of std_logic_vector(5 downto 0);
	signal Memory : Memory_TYPE := 
    ( 		 
       -- PART 1:
       0     => "000000", -- Load R0,
       1     => "000111", -- 7
       2     => "000100", -- Load R1,
       3     => "000100", -- 4
       4     => "010001", -- Add, R0, R1
       others => "111111" -- Halt	 
        --PART 2:
        --0  => "000000", 
        --1  => "000110",	
        --2  => "000100",	
        --3  => "001000",	
        --4  => "001000",	
        --5  => "000001",	
        --6  => "001100",	
        --7  => "000000",	
        --8  => "011100", 
        --9  => "100110",
        --10 => "110100",
        --11 => "001000",
        --others => "111111"   
    );
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
	 reset <= '1', '0' after 50ns;
   
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

