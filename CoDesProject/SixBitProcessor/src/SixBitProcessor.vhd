library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL; 

entity SixBitProcessor is						 
	port(
		clk, reset : in STD_LOGIC);
end SixBitProcessor; 


architecture SixBitProcessorArch of SixBitProcessor is	 

type Memory_TYPE is array (63 downto 0) of std_logic_vector(5 downto 0);
type State_t is (S0,S1, HaltCheck, S2, S3, S4, S5, S6, S7);

signal Memory : Memory_TYPE := 
( 		 
   -- PART 1:
       --0     => "000000", -- Load R0,
       --1     => "000111", -- 7
       --2     => "000100", -- Load R1,
       --3     => "000100", -- 4
       --4     => "010001", -- Add, R0, R1
       --others => "111111" -- Halt	 
        --PART 2:
        0  => "000000", 
        1  => "000110",	
        2  => "000100",	
        3  => "001000",	
        4  => "001000",	
        5  => "000001",	
        6  => "001100",	
        7  => "000000",	
        8  => "011100", 
        9  => "100110",
        10 => "110100",
        11 => "001000",
        others => "111111"   
);

--FSM
signal state_reg, state_next : State_t;  
-- Registers
type std_logic_vector_array	is array (natural range <>) of std_logic_vector(5 downto 0);
type std_logic_array	is array (natural range <>) of std_logic;
signal ROUT,RIN : std_logic_vector_array(0 to 3);
signal LD,ZR : std_logic_array(0 to 3);
signal IR,PC : std_logic_vector (5 downto 0);			 
signal IRNext,PCNext : std_logic_vector (5 downto 0);
--signal R0,R1,R2,R3,IR,PC : std_logic_vector (5 downto 0); 
--signal R0Next,R1Next,R2Next,R3Next,IRNext,PCNext : std_logic_vector (5 downto 0);

-- Controls
signal MData, DataBUS, ALURes: std_logic_vector(5 downto 0);
type std_logic_array_2Bit	is array (natural range <>) of std_logic_vector(1 downto 0);
signal ALUINSelector: std_logic_array_2Bit(1 downto 0);
signal ALUIN : std_logic_vector_array(1 downto 0);
signal BUSSel,LDPC,LDIR,INC,RST,CMD : std_logic; 
 
--Helpers for simpler code
signal Z : std_logic_vector(3 downto 0);	 
signal index : integer;	

begin	   
	
	
	index <= to_integer(unsigned(IR(3 downto 2)));
	
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
		ZR(k) <= '1' when ROUT(k)="000000" else '0'; 
			
		RIN(k) <= DataBUS when LD(k)='1' else ROUT(k);	 
		Z(k) <= ZR(k);
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
	
	PCNext <= DataBUS when LDPC='1' else PC+1 when INC='1' else "000000" when RST='1' else PC;
	IRNext <= DataBUS when LDIR='1' else IR;
	
	process(clk,reset)  
	begin 	
		if reset='1' then 
			state_reg <= s0;
		elsif (rising_edge(clk)) then			
			state_reg <= state_next;
		end if;
	end process; 
	
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



		

	ALURes <= ALUIN(0)+ALUIN(1) when CMD='0' else ALUIN(0)-ALUIN(1);
	 
	
	process(IR, Z, state_reg)
	begin
	-- Initialize signals
	CMD <= '0';
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

	-- State transitions
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
			elsif IR(5 downto 4) = "00" then
				state_next <= s3;
			elsif IR(5 downto 4) = "01" then
				state_next <= s4;
			elsif IR(5 downto 4) = "10" then
				state_next <= s5;
			elsif IR(5 downto 4) = "11" then
				if Z(to_integer(unsigned(IR(3 downto 2)))) = '0' then
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
			CMD <= '0';
			ALUINSelector(0) <= IR(3 downto 2);
			ALUINSelector(1) <= IR(1 downto 0);
			BUSSel <= '1';
			state_next <= s1;

		when s5 =>
			LD(to_integer(unsigned(IR(3 downto 2))))<='1';
			CMD <= '1';	 
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

	end case;
	end process;
	
end SixBitProcessorArch;