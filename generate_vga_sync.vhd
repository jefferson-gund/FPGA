library ieee;
use ieee.std_logic_1164.all;

entity generate_vga_sync is
	
	generic
	(
	 -- Horizontal Scan 800		
		H_a : natural; --:= 96;	 -- Retrace
		H_b : natural;-- := 48;	 -- Left Border
		H_c : natural;-- := 640; -- Display 640
		H_d : natural;-- := 16;	 -- Right Border
		
	 -- Vertical Scan   525	
		V_a : natural; --:= 2;	 -- Retrace
		V_b : natural;-- := 33;	 -- Top Border
		V_c : natural; --:= 480; -- Display 480
		V_d : natural -- := 10	 -- Bottom Border
	);
	
	port
	(
		-- Input ports
		clk	: in  std_logic; -- 25MHz
		reset : in  std_logic;

		-- Output ports
		hsync : out std_logic;
		vsync : out std_logic;
		
		hcount: out integer range 0 to H_a+H_b+H_c+H_d;
		vcount: out integer range 0 to V_a+V_b+H_c+H_d;
		
		video_on: out std_logic
	);
end generate_vga_sync;


architecture comportamental of generate_vga_sync is

	signal h_count: integer range 0 to H_a+H_b+H_c+H_d;
	signal v_count: integer range 0 to V_a+V_b+V_c+V_d;
	
	signal h_video_on : std_logic;
	signal v_video_on : std_logic;
	
begin
	
	process(clk,reset)
	
	begin
		
		if(reset = '0')then
		
			h_count <= 0;
			v_count <= 0;
			
			hsync <= '0';
			vsync <= '0';
			
			h_video_on <= '1';
			v_video_on <= '1';
		
		elsif(clk'event and clk = '1')then

					
			if(h_count < H_a+H_b+H_c+H_d)then
				
				
				h_count <= h_count + 1;
				
			else
			
				h_count <= 1;
				
				if (v_count < V_a+V_b+V_c+V_d-1) then
				
					v_count <= v_count + 1;
					
				else
					
					v_count <= 0;
					
				end if;
			
			end if;
			
			
			if (h_count >= H_c+H_d and h_count < H_c+H_d+H_a) then
			
				hsync <= '0';
			
			else
			
				hsync <= '1';
				
			end if;
			
			
			if (v_count >= V_c+V_d and v_count < V_c+V_d+V_a) then
			
				vsync <= '0';
				
			else
			
				vsync <= '1';
				
			end if;
			
		
			if(h_count = H_a+H_b+H_c+H_d or h_count = 1)then
			
				h_video_on <= '1';
				
			elsif(h_count = H_c)then
			
				h_video_on <= '0';
				
			end if;
			
			if(v_count = 0)then
			
				v_video_on <= '1';
				
			elsif(v_count = V_c)then
			
				v_video_on <= '0';
				
			end if;
			
		end if;
	
	end process;
	
	video_on <= h_video_on and v_video_on;
	hcount <= h_count-1;
	vcount <= v_count;

end comportamental;
