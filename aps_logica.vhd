-- Programa principal: "MAIN"

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.vga_package.all;

entity aps_logica is
	
	port
	(	
		-- Input ports
		clk_in : in  std_logic;
		reset: in std_logic;

		stop     : in std_logic;
		play_pause     : in std_logic;
		esquerda     : in std_logic;
		direita     : in std_logic;
		
		-- Output ports
		R : out  std_logic; 
		G : out  std_logic;
		B : out  std_logic;
		

		
		hsync : out std_logic;
		vsync : out std_logic
			
	);
end aps_logica;

architecture comportamental of aps_logica is

--component LCELL
--	port(a_in:in std_logic;a_out:out std_logic);
--end component;

---------------------------------------------------------------

		--PIN PLANNING PARA PLACA FPGA CYCLONE II - EP2C5T144C8N:
		ATTRIBUTE chip_pin: STRING;
		ATTRIBUTE chip_pin OF clk_in: SIGNAL IS "17";
		ATTRIBUTE chip_pin OF B: SIGNAL IS "120";
		ATTRIBUTE chip_pin OF G: SIGNAL IS "121";
		ATTRIBUTE chip_pin OF R: SIGNAL IS "122";
		ATTRIBUTE chip_pin OF hsync: SIGNAL IS "126";
		ATTRIBUTE chip_pin OF vsync: SIGNAL IS "125";
		ATTRIBUTE chip_pin OF reset: SIGNAL IS "144";--Reset (sw0)
		ATTRIBUTE chip_pin OF stop: SIGNAL IS "143";--Play/Pause (sw1)
		ATTRIBUTE chip_pin OF play_pause: SIGNAL IS "142";--Play/Pause (sw2)
		ATTRIBUTE chip_pin OF esquerda: SIGNAL IS "141";--Move para a esquerda (sw3)
		ATTRIBUTE chip_pin OF direita: SIGNAL IS "139";--Move para a direita (sw4)
		--END PIN PLANE;
----------------------------------------------------------------------------------
		signal clk_25MHz,clk_img,clk_fruta : std_logic := '0';
		signal esquerda_out,direita_out,play_out,stop_out: std_logic := '1';
		signal sw_in : switch := sw;
		signal x_in,x_out_main,x_posicao_in,x_posicao_out,x_out: integer range 0 to 640-hpou;	--tipo definido para x_pos    max. valor (direita)=540; min. valor (esquerda)= 10
		signal flag_pou_fruta_out,flag_pou_fruta_in,game_over_in,game_over_out: std_logic:='0';
		signal estado_in,estado_out: integer range 0 to 3:=0;
		signal vertical_fruta_in,vertical_fruta_out: integer range 0 to ground:=0;
		signal posicoes_frutas_in,posicoes_frutas_out,random_posicoes_on : std_logic_vector (0 to 4);
		signal digitos_pontuacao_in: digitos;
		signal  objetos_in,sorteio_objetos : objetos;--sorteio de quais objetos sao sorteados.
		signal score: integer range 0 to 999;
		signal evento :integer range 0 to 100;
		
		signal s_flag: std_logic := '0';
		
		--signal rand,buffrand: std_logic;
		--signal rand,buffrand: std_logic_vector(6 downto 0);
begin



		sw_in <= sw3 when ((esquerda_out  = '0') and(direita_out = '1') and(play_out = '1') and(stop_out = '1'))	--esquerda
				else 	sw4 when ((esquerda_out  = '1') and(direita_out = '0') and(play_out = '1') and(stop_out = '1')) --direita
				else  sw2 when ((esquerda_out  = '1') and(direita_out = '1') and(play_out = '0') and(stop_out = '1')) --play/pause 
				else  sw1 when ((esquerda_out  = '1') and(direita_out = '1') and(play_out = '1') and(stop_out = '0')) --stop (reset)
				else	sw;
				

	
	instance_0: interface_vga
		port map(clk_in,clk_25MHz,reset,estado_in,estado_out,x_posicao_in,x_posicao_out,vertical_fruta_in,vertical_fruta_out,posicoes_frutas_in,posicoes_frutas_out,digitos_pontuacao_in,objetos_in,flag_pou_fruta_in,flag_pou_fruta_out,game_over_out,R,G,B,hsync,vsync);	
		
	instance_1: debouncing_filter
		port map (esquerda,clk_in,esquerda_out);
			
	instance_2: debouncing_filter
		port map (direita,clk_in,direita_out);
		
	instance_3: debouncing_filter
		port map (play_pause,clk_in,play_out);
			
	instance_4: debouncing_filter
		port map (stop,clk_in,stop_out);
		
	instance_5: generate_clock
		port map(clk_in,reset,clk_25MHz);
			

			
			
--=============================================================================================================================================
------------------------------------------------------------
--					Clock para deslocamento da imagem	do POU --
------------------------------------------------------------	

	
		process(clk_25MHz,reset,sw_in)
			variable  aux : integer range 0 to 10000 := 0;
			variable  aux1 : integer range 0 to 10 := 0;
		begin
			
			if(reset = '0')then
				clk_img <= '0';
				aux:=0;
				aux1:=0;
			elsif(clk_25MHz'event and clk_25MHz = '1' and (sw_in=sw3 or sw_in=sw4))then
				aux:=aux+1;
				if(aux=10000) then
					aux1:=aux1+1;
					aux:=0;
				end if;
				if(aux1=2) then
					clk_img <= not clk_img;
					aux1:=0;
				end if;
			end if;
		
		end process;
	
	

------------------------
-- Máquina de estados --
------------------------
	
--	process(clk_25MHz,reset,new_game,estado_out)
--	begin

--		if(estado_out=0)then
--			new_game<='0';
--			play<='0';
--			pause<='1';
--			game_over<='0';
--		elsif(estado_out=1)then--Se o jogo foi pausado.
--			new_game<='1';
--			play<='0';
--			pause<='1';
--			game_over<='0';
--		elsif(estado_out=2)then--Se foi dado o play.
--			new_game<='1';
--			play<='1';
--			pause<='0';
--			game_over<='0';
--		elsif(estado_out=3) then--Se o jogo acabou.
--			new_game<='1';
--			play<='0';
--			pause<='1';
--			game_over<='1';
--		end if;
--	end process;
	



	
	
-------------------------------------
-- Tratamento da leitura de teclas --
-------------------------------------


	process(reset,clk_25MHz,clk_img,sw_in,estado_out)	
		variable  aux : integer range 0 to 640-hpou:=0;
		variable state :  integer range 0 to 3;
		variable game_over : std_logic:='0';
		
		
	begin						
	
			
		aux:=x_posicao_out;
		state:=estado_out;
		game_over:=game_over_out;
		
		
		if( reset = '0')then
			x_posicao_in<= 255;		--condiçoes de reinício de jogo: estado=0 -> new_game='0' and pause='1' and start_in='0' and game_over_in='0' 
			estado_in<=0;
			
		elsif(clk_img'event and clk_img='1' and (aux >0) and (aux <= 640-hpou) and state=2) then
					if((sw_in = sw3))then
							aux := aux - 1;
					elsif ((sw_in = sw4)) then
							aux := aux + 1;
					end if;
				x_posicao_in<=aux;
					
		elsif(clk_img'event and clk_img='1' and not((aux >0) and (aux <= 640-hpou)) and state=2) then
				if((aux <=0)) then
					aux:=1;
				elsif((aux >640-hpou)) then
					aux:=540;
				end if;
				x_posicao_in<=aux;		
		end if;
		
		--Maquina de estados
		
		
		
			if( (sw_in = sw2) and state=2 and game_over='0')then--se estiver em jogo, pausa.
				estado_in<=1;
			elsif((sw_in = sw1) and (state=1 or state=0) ) then --play
				estado_in<=2;
				
			elsif((sw_in /= sw1) and game_over='1')then
				estado_in<=3;			
			
			elsif((sw_in = sw1) and game_over='1')then
				estado_in<=0;	
			end if;

		
	end process;
	
	
	
	
	
	
	
------------------------------------------------------------
-- 		Clock para deslocamento da imagem das frutas		 --
------------------------------------------------------------	

	
		process(clk_25MHz,reset,vertical_fruta_out,estado_out)
			variable  aux : integer range 0 to 10000 := 0;
			variable  aux1 : integer range 0 to 10 := 0;
		begin
			
			if(reset = '0')then
				clk_fruta <= '0';
				aux:=0;
				aux1:=0;
			elsif(clk_25MHz'event and clk_25MHz = '1')then
				aux:=aux+1;
				if(aux=10000) then
					aux1:=aux1+1;
					aux:=0;
				end if;
				if(aux1=6) then
					clk_fruta <= not clk_fruta;
					aux1:=0;
				end if;
			end if;
		
		end process;
		
	
	
---------------------------------------------------------
--     Tratamento de pontuação e sorteio de frutas	    --
---------------------------------------------------------
	process(reset,clk_25MHz,clk_fruta,vertical_fruta_out,flag_pou_fruta_out,estado_out,score)	
		variable y_fruta : integer range 0 to ground:=0;
		variable  posicao_horizontal_fruta,object_off : std_logic_vector (0 to 4):="00000";
		variable  sorteio : objetos;--sorteio de quais objetos sao sorteados.
		variable state :  integer range 0 to 3;
		--variable  aux : integer range 0 to 10000 := 0;
		variable flag : std_logic:='0';
		
		variable pontuacao : integer range 0 to 999;
		variable centena,dezena,unidade : integer range 0 to 9;
		variable digitos_CDU : digitos;
		
	begin
		
		posicao_horizontal_fruta:=posicoes_frutas_out;
						
		state:=estado_out;
		
		flag:=flag_pou_fruta_out;
		
		if( reset = '0')then
				evento<=0;
			--pontuacao:=0;
			posicoes_frutas_in <= random_posicoes_on;
			objetos_in<=sorteio_objetos;
			--posicao_horizontal_fruta:="11111";--Sorteio de posicoes em que há frutas.
			
		end if;
		
		if(state=0) then
			objetos_in<=sorteio_objetos;
			evento<=0;
			
	
	
		elsif(state=3) then
			evento<=0;
			y_fruta:=380;
		elsif(clk_fruta'event and clk_fruta='1' and state=2 ) then
		
				if((y_fruta >0) and (y_fruta <=ground)) then
					--y_fruta:=vertical_fruta_out;
					y_fruta:=y_fruta-1;
				elsif(not((y_fruta >0) and (y_fruta <=ground))) then
					--y_fruta:=vertical_fruta_out;
					y_fruta:=380;
				end if;
				
		end if;
	
		vertical_fruta_in<=y_fruta;
		
		if(y_fruta/=380 and state=2) then
			posicoes_frutas_in <= (random_posicoes_on and posicao_horizontal_fruta);
		elsif(posicao_horizontal_fruta="00000" and state=2) then
			posicoes_frutas_in <=random_posicoes_on;
		else
			posicoes_frutas_in<=random_posicoes_on;
		end if;
		
	

		objetos_in<=sorteio_objetos;

	
	
	
		if(state/=2 and state/=1) then
				evento<=0;
				pontuacao:=0;
		elsif(flag'event and flag='1' and state=2) then
				score<=score+5;
				
				
				--pontuacao:=987;
		end if;
		
	   centena := integer(score /100);
		dezena := integer((integer(score mod 100)) / 10); -- O resto da divisão por 10 resulta no dígito das dezenas.
		unidade := integer(score mod 10); -- O resto da divisão do número por 10 resulta no valor respectivo ao dígito das unidades.
	
		digitos_CDU:=(centena,dezena,unidade);
		digitos_pontuacao_in<=digitos_CDU;
		
	end process;

	
	
	
	

	process(reset,clk_25MHz,vertical_fruta_out)--
		variable delay : integer range 0 to 200;
	
		variable x: integer range 0 to 4 := 1;
		variable a : integer range 0 to 10_000 := 5;
		variable c : integer range 0 to 10_000 := 9;
		variable m : integer range 0 to 10_000 := 16;
		variable cont : integer range 0 to 100 := 0;
		variable objetos_random : objetos;
		variable i : integer range 0 to 4;--indice para sorteio de objetos.
		variable y_fruta : integer range 0 to ground:=0;
		variable  posicoes_random : std_logic_vector (0 to 4);
		variable valida_sorteio : std_logic:='0';
	
	begin

	
	
		y_fruta:=vertical_fruta_out;

		
		if(clk_25MHz'event and clk_25MHz = '1') then
			x := (a*x + c) mod m;
			cont := cont + 1;
							
			
			if(cont = 9) then
				a := a + 1;
				cont := 0;
				if(a = 50) then
					c := c + 1;
					a := 5;						
				end if;
			end if;

			--x := to_integer(signed(rand));




			if((x>=0 and x<=4) and (i<=4 and i>=0)) then
				objetos_random(i):=x;
				delay:=delay+1;
				if(delay =100) then
					delay:=0;
					i:=i+1;			
				end if;
			elsif(not(i<=4 and i>=0	)) then
				i:=0;
			end if;
			
			
			
			
			
			
			
			if((x=0 or x=1) and (i<=4 and i>=0)) then
				if(x=1) then
					posicoes_random(i):='1';
				elsif(x=0) then
					posicoes_random(i):='0';
				end if;
				delay:=delay+1;
				if(delay = 50) then
					delay:=0;
					i:=i+1;			
				end if;
			elsif(not(i<=4 and i>=0	)) then
				i:=0;
			end if;



			if((objetos_random(0)=3 or objetos_random(0)=4) and (objetos_random(1)=3 or objetos_random(1)=4) and (objetos_random(2)=3 or objetos_random(2)=4) and (objetos_random(3)=3 or objetos_random(3)=4) and (objetos_random(4)=3 or objetos_random(4)=4)) then
				valida_sorteio:='1';
			else 
				valida_sorteio:='0';
			end if;
			


			if(y_fruta=380 and valida_sorteio='0') then --faz novo sorteio de objetos quando os objetos atingem o chao.
				random_posicoes_on<=posicoes_random;
				sorteio_objetos<=objetos_random;
			end if;
			
		end if;
	end process;
	
	
end comportamental;






