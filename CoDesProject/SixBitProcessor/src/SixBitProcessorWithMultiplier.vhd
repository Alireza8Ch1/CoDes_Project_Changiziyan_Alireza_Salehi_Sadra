library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL; 

entity SixBitProcessorWithMultiplier is
	generic (instruction_bits : positive := 7);
	port(
		clk, reset : in STD_LOGIC);
end SixBitProcessorWithMultiplier; 


architecture SixBitProcessorWithMultiplierArch of SixBitProcessorWithMultiplier is	 

-- signals			  										  
-- "state_type" is type for control unit states
type state_type is (S0,S1, HaltCheck, S2, S3, S4, S5, S6, S7, S8);
-- "std_logic_vector_array" is a type with 6 bits used for declare an array of 6bit values
type std_logic_vector_array	is array (natural range <>) of std_logic_vector(instruction_bits - 1 downto 0);
-- "std_logic_array" is a type with 1 bit used for declare an array of 1 bit values
type std_logic_array	is array (natural range <>) of std_logic;  						
-- "std_logic_array_2Bit" is a type with 2 bit used for declare an array of 2 bit values
type std_logic_array_2Bit	is array (natural range <>) of std_logic_vector(1 downto 0);
-- control unit states
signal state_reg, state_next : state_type;
-- "ROUT" and "RIN" in order are registers output and inputs that thier
-- type is an array of 6 bit values with array size 4 (number of registers is 4)
signal ROUT,RIN : std_logic_vector_array(0 to 3);
-- "LD" and "ZR" are registers load and zero input that their type is
-- an array of 1 bit values with array size 4
signal LD,ZR : std_logic_array(0 to 3);		 
-- "IRNext" and "PCNext" are inputs for IR and PC registers
signal IRNext,PCNext : std_logic_vector (instruction_bits-1 downto 0);		 
-- MUX inputs and outputs and selector for selecting BUS value
signal MData, DataBUS, ALURes: std_logic_vector(instruction_bits-1 downto 0);
signal BUSSel : std_logic; 													 
-- ALU MUXs' selectors that "ALUINSelector" is an array with size 2 with 2 bit values
signal ALUINSelector: std_logic_array_2Bit(1 downto 0);
-- ALU IN1 and IN2 that "ALUIN" is an array with size 2 with 6 bit values
signal ALUIN : std_logic_vector_array(1 downto 0);
-- ALU CMD for selecting operator
signal CMD : std_logic_vector(1 downto 0);	
-- "IR" and "PC" are outputs for IR and PC registers
signal IR,PC : std_logic_vector (instruction_bits -1 downto 0);
-- other IR and PC inputs
signal LDPC,LDIR,INC,RST : std_logic;

-- Memory
type Memory_TYPE is array (63 downto 0) of std_logic_vector(instruction_bits-1 downto 0);


signal Memory : Memory_TYPE := 
( 		 
  --PART 3:
    0 => "0000000",	-- Load R0,
	1 => "0000110",	-- 6
	2 => "0000100",	-- Load R1, 
	3 => "0001000",	-- 8
	4 => "1000001",	-- Mult, R0, R1
	others => "1111111" -- Halt  
);

signal multRes : std_logic_vector(instruction_bits*2-1 downto 0);

begin	   
	
	
	-- 4 Registers (R0,R1,R2,R3)
	Registers : for k in 0 to 3 generate   
		process(clk,reset)
		begin  
			if reset='1' then
				ROUT(k) <= (others => '0');
			elsif (clk'event and clk='1') then
				ROUT(k) <= RIN(k);
			end if;
		end process;					  
		--Set ZR signal
		ZR(k) <= '1' when ROUT(k)="0000000" else '0'; 
			
		RIN(k) <= DataBUS when LD(k)='1' else ROUT(k);	 
	end generate Registers;
	
	--IR and PC Registers
	process(clk,reset)  
	begin 	
		if reset='1' then 
			IR <= (others => '0');
			PC <= (others => '0');
		elsif (rising_edge(clk)) then			
			IR <= IRNext;
			PC <= PCNext;
		end if;
	end process;
	
	PCNext <= DataBUS when LDPC='1' else PC+1 when INC='1' else "0000000" when RST='1' else PC;
	IRNext <= DataBUS when LDIR='1' else IR;
	
	
	
	
	-- MUXs
	ALUMUXs : for k in 0 to 1 generate	 
		process(ROUT,ALUINSelector(k))
		begin  
			case ALUINSelector(k) is 
				when "00" => 
					ALUIN(k) <= ROUT(0);
				when "01" =>
				   ALUIN(k) <= ROUT(1);
				when "10" => 
				   ALUIN(k) <= ROUT(2);
				when "11" =>
				   ALUIN(k) <= ROUT(3);
				when others =>
				   ALUIN(k) <= (others => '0');
		    end case;			
		end process;
	end generate ALUMUXs;
	
	BUSMUX: process(MData, ALURes, BUSSel)
	begin 
		case BUSSel is 
			when '0' => 
		 	   DataBUS <= MData; 
			when '1' =>
			   DataBUS <= ALURes;
			when others =>
			   DataBUS <= (others => '0');
	    end case;	
	end process; 
	
	
	
	
	MData <= Memory(to_integer(unsigned(PC)));	


	multRes <= ALUIN(0) * ALUIN(1);
		
	-- ALU
	ALURes <= ALUIN(0) + ALUIN(1) when CMD="00" else ALUIN(0) - ALUIN(1) when CMD="01" else multRes(instruction_bits-1 downto 0);
	
	
	process(IR, ZR, state_reg)
	begin
	CMD <= "00";
	INC <= '0';
	RST <= '0';
	LD(0) <= '0';
	LD(1) <= '0';
	LD(2) <= '0';
	LD(3) <= '0';
	LDPC <= '0';
	LDIR <= '0';
	ALUINSelector(0) <= "00";
	ALUINSelector(1) <= "00";
	BUSSel <= '0';

	-- control unit states
	case state_reg is
		when s0 =>
			RST <= '1';
			state_next <= s1;
			
		when s1 =>
			LDIR <= '1';
			INC <= '1';
			BUSSel <= '0';
			state_next <=  HaltCheck;
		when HaltCheck =>
			if IR = "111111" then
				state_next <= s2;	
			elsif IR(6) = '1' then
				state_next <= s8;
			elsif IR(5 downto 4) = "00" then
				state_next <= s3;
			elsif IR(5 downto 4) = "01" then
				state_next <= s4;
			elsif IR(5 downto 4) = "10" then
				state_next <= s5;
			elsif IR(5 downto 4) = "11" then
				if ZR(to_integer(unsigned(IR(3 downto 2)))) = '0' then
					state_next <= s6;
				else
					state_next <= s7;
				end if;
			end if;
		when s2 =>
			state_next <= s2;

		when s3 =>	   
			LD(to_integer(unsigned(IR(3 downto 2))))<='1';
			INC <= '1';
			BUSSel <= '0';	
			state_next <= s1;
			

		when s4 =>
			LD(to_integer(unsigned(IR(3 downto 2))))<='1';
			CMD <= "00";
			ALUINSelector(0) <= IR(3 downto 2);
			ALUINSelector(1) <= IR(1 downto 0);
			BUSSel <= '1';
			state_next <= s1;

		when s5 =>
			LD(to_integer(unsigned(IR(3 downto 2))))<='1';
			CMD <= "01";	 
			ALUINSelector(0) <= IR(3 downto 2);
			ALUINSelector(1) <= IR(1 downto 0);
			BUSSel <= '1';
			state_next <= s1;

		when s6 =>
			
			LDPC <= '1';
			BUSSel <= '0';
			state_next <= s1;
		when s7 =>	
			INC <= '1';
			state_next <= s1;  
		when s8=>
			LD(to_integer(unsigned(IR(3 downto 2))))<='1'; 
			CMD <= "10";
			ALUINSelector(0) <= IR(3 downto 2);
			ALUINSelector(1) <= IR(1 downto 0);
			BUSSel <= '1';
			state_next <= s1;
	end case;
	end process;
	
	-- process for setting control unit states
	process(clk,reset)  
	begin 	
		if reset='1' then 
			state_reg <= s0;
		elsif (rising_edge(clk)) then			
			state_reg <= state_next;
		end if;
	end process;  
	
end SixBitProcessorWithMultiplierArch;