library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity exponentiation is
	generic (
		C_block_size : integer := 256
	);
	port (
		-- input control
		valid_in	: in  std_logic;
		ready_in	: out std_logic;

		-- input data
		message 	: in std_logic_VECTOR(C_block_size-1 downto 0);
		key 		: in std_logic_VECTOR(C_block_size-1 downto 0);
		nega_n    	: in std_logic_VECTOR(C_block_size-1 downto 0);
		nega_2n 	: in std_logic_VECTOR(C_block_size-1 downto 0);

		-- ouput control
		ready_out	: in  std_logic;
		valid_out	: out std_logic;

		-- output data
		result 		: out std_logic_VECTOR(C_block_size-1 downto 0);

		-- utility
		clk 		: in std_logic;
		reset_n 	: in std_logic
	);
end exponentiation;


architecture expBehave of exponentiation is

-- Registers
signal P_r          : std_logic_vector(C_block_size-1 downto 0);
signal C_r          : std_logic_vector(C_block_size-1 downto 0);
signal P_nxt        : std_logic_vector(C_block_size-1 downto 0);
signal C_nxt        : std_logic_vector(C_block_size-1 downto 0);

-- PISO signals
signal bi           : std_logic;
signal store_M      : std_logic;
signal store_P      : std_logic;

-- Blakely signals
signal result_C     : std_logic_vector(C_block_size-1 downto 0);
signal result_P     : std_logic_vector(C_block_size-1 downto 0);

-- FSM signals
signal index        : std_logic_vector(integer(ceil(log2(real(C_block_size))))-1 downto 0);
signal write_mes    : std_logic;

begin   
	-- Instansiate Two Blakely modules
	in_blakely_C : entity work.blakely
	   generic map (
	       C_block_size => C_block_size
	   )
	   port map (
	       -- Inputs
	       clk 		=> clk,
	       rst_n 	=> reset_n,
	       a 		=> C_r,
	       bi 		=> bi,
	       nega_n 	=> nega_n,
	       nega_2n 	=> nega_2n,
	       -- Outputs
	       result 	=> result_C
	   );
	   
	 in_blakely_P : entity work.blakely
	   generic map (
	       C_block_size => C_block_size
	   )
	   port map (
	       -- Inputs
	       clk 		=> clk,
	       rst_n 	=> reset_n,
	       a 		=> P_r,
	       bi 		=> bi,
	       nega_n 	=> nega_n,
	       nega_2n 	=> nega_2n,
	       -- Outputs
	       result 	=> result_P
	   );
	
	
	-- Instansiate FSM
    in_FSM : entity work.FSM
        generic map (
            C_block_size => C_block_size
        )
        port map (
            -- Inputs
            valid_in 	=> valid_in,
			ready_out 	=> ready_out,
			clk 		=> clk,
			rst_n 		=> reset_n,
            -- Outputs
			valid_out 	=> valid_out,
			ready_in 	=> ready_in,
			index 		=> index
        );
    
    
    -- Sequential datapath
    process(clk, reset_n)
    begin
        if (reset_n = '0') then
            C_r <= (0 => '1', others => '0');
			P_r <= (others => '0');
        elsif (rising_edge(clk)) then
            C_r <= C_nxt;
            P_r <= P_nxt;
        end if;
    end process;
    
    -- Combinatorial datapath
    process(index, key, result_C, C_r, write_mes, valid_in)
    begin
        if (write_mes = '1' and valid_in = '1') then
            C_nxt <= (0 => '1', others => '0');
            P_nxt <= message;
        else
            if(key(to_integer(unsigned(index))) = '1') then
                C_nxt <= result_C;
                P_nxt <= result_P;
            else 
                C_nxt <= C_r;
                P_nxt <= result_P;
            end if;
        end if;
    end process;
   
    bi <= P_r(to_integer(unsigned(index)));
    result <= C_r;
   
end expBehave;