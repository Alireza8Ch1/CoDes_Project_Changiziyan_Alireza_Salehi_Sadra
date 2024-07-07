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
type state_type is (S0,S1, HLT, S2, S3, S4, S5, S6, S7, S8);

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
signal memory_read_address : integer range 0 to 63;	   

begin	   
	
	
	-- 4 Registers (R0,R1,R2,R3)
	Registers : for k in 0 to 3 generate   
		process(clk,reset)
		begin  
			if reset='1' then
				ROUT(k) <= (others => '0');
			elsif (clk'event and clk='1' and LD(k)='1') then
				ROUT(k) <= DataBUS;
			end if;
		end process;					  
		--Set ZR signal
		ZR(k) <= '1' when ROUT(k)="0000000" else '0'; 	 
	end generate Registers;
	
	
	--IR and PC Registers
	process(clk,reset)  
	begin 
		IR <= IR;
		PC <= PC;
		if reset='1' then 
			IR <= (others => '0');
			PC <= (others => '0');
		elsif (clk'event and clk='1') then	
			if LDIR='1' then
				IR <= DataBUS; 	   
			end if;
			
			if LDPC='1' then
				PC <= DataBUS;
			elsif INC='1' then
				PC <= PC+1;
			elsif RST='1' then
				PC <= (others => '0');
			end if;	
		end if;
	end process;
	
	
	
	
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
	
	
	
	memory_read_address <= to_integer(unsigned(PC)); 
	MData <= Memory(memory_read_address);	


	multRes <= ALUIN(0) * ALUIN(1);
		
	-- ALU
	ALURes <= ALUIN(0) + ALUIN(1) when CMD="00" else ALUIN(0) - ALUIN(1) when CMD="01" else multRes(instruction_bits-1 downto 0);
	
	
	process(IR, ZR, state_reg)
	begin		 
	ALUINSelector <= (others => "00");
	LD <= (others => '0');
	BUSSel <= '0';
	LDPC <= '0';
	LDIR <= '0';
	INC <= '0';
	CMD <= "00";
	RST <= '0';
		

	-- control unit states
	case state_reg is
		when S0 =>
			RST <= '1';
			state_next <= S1;
			
		when S1 =>
			LDIR <= '1';
			INC <= '1';
			BUSSel <= '0';
			state_next <=  HLT;
		when HLT =>
			if IR = "1111111" then
				state_next <= S2;	
			elsif IR(6) = '1' then
				state_next <= S8;
			elsif IR(5 downto 4) = "00" then
				state_next <= S3;
			elsif IR(5 downto 4) = "01" then
				state_next <= S4;
			elsif IR(5 downto 4) = "10" then
				state_next <= S5;
			elsif IR(5 downto 4) = "11" then
				if ZR(to_integer(unsigned(IR(3 downto 2)))) = '0' then
					state_next <= S6;
				else
					state_next <= S7;
				end if;
			end if;
		when S2 =>
			state_next <= S2;

		when S3 =>	   
			LD(to_integer(unsigned(IR(3 downto 2))))<='1';
			INC <= '1';
			BUSSel <= '0';	
			state_next <= S1;
			

		when S4 =>
			LD(to_integer(unsigned(IR(3 downto 2))))<='1';
			CMD <= "00";
			ALUINSelector(0) <= IR(3 downto 2);
			ALUINSelector(1) <= IR(1 downto 0);
			BUSSel <= '1';
			state_next <= S1;

		when S5 =>
			LD(to_integer(unsigned(IR(3 downto 2))))<='1';
			CMD <= "01";	 
			ALUINSelector(0) <= IR(3 downto 2);
			ALUINSelector(1) <= IR(1 downto 0);
			BUSSel <= '1';
			state_next <= S1;

		when S6 =>
			LDPC <= '1';
			BUSSel <= '0';
			state_next <= S1;
		when S7 =>	
			INC <= '1';
			state_next <= S1;  
		when S8=>
			LD(to_integer(unsigned(IR(3 downto 2))))<='1'; 
			CMD <= "10";
			ALUINSelector(0) <= IR(3 downto 2);
			ALUINSelector(1) <= IR(1 downto 0);
			BUSSel <= '1';
			state_next <= S1;
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