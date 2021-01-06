library ieee;
use ieee.std_logic_1164.all;

entity generate_clock is

	port
	(
		-- Input ports
		clk	: in  std_logic;
		reset : in  std_logic;

		-- Output ports
		clk_out : out std_logic
	);
end generate_clock;


architecture comportamental of generate_clock is
	
	signal clk_25MHz : std_logic := '0';
	
begin

		process(clk,reset)
		
		begin
			
			if(reset = '0')then
			
				clk_25MHz <= '0';
			
			elsif(clk'event and clk = '1')then
			
				clk_25MHz <= not clk_25MHz;
			
			end if;
		
		end process;
		
		clk_out <= clk_25MHz;
	
end comportamental;
