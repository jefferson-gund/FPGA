library ieee;
use ieee.std_logic_1164.all;
library work;
use work.vga_package.all;

entity interface_vga is

	generic
	(
	-- Horizontal Scan 800:		
		constant Ha : natural := 96;	-- Retrace
		constant Hb : natural := 48;	-- Left Border
		constant Hc : natural := 640; -- Display 640
		constant Hd : natural := 16;	-- Right Border
		
	-- Vertical Scan 525:	
		constant Va : natural := 2;	-- Retrace
		constant Vb : natural := 33;	-- Top Border
		constant Vc : natural := 480; -- Display 480
		constant Vd : natural := 10	-- Bottom Border
		
	);
	
	port						
	(
		-- Input ports
		clk : in  std_logic;		
		clk_25MHz	: in  std_logic;	
		reset : in  std_logic;
		
		estado_in : in integer range 0 to 3;
		estado_out :out integer range 0 to 3;
		
		x_posicao_in : in integer range 0 to 640-hpou;	--tipo definido para x_pos
		x_posicao_out : out integer range 0 to 640-hpou;	--tipo definido para x_pos
			
		vertical_fruta_in : in integer range 0 to ground;
		vertical_fruta_out : out integer range 0 to ground;
	
		posicoes_frutas_in : in std_logic_vector (0 to 4);--cinco posicoes horizontais fixas para as frutas.
		posicoes_frutas_out : out std_logic_vector  (0 to 4);
		
		digitos_pontuacao_in: in digitos;
		--digitos_pontuacao_out: out digitos;

		objetos_in : in objetos;
	--	objetos_out : out objetos;
		
		
		flag_pou_fruta_in : in std_logic;
		flag_pou_fruta_out : out std_logic;
		
	--	game_over_in : in std_logic;
		game_over_out : out std_logic;
		
		-- Output ports VGA type
		R : out std_logic;
		G : out std_logic;
		B : out std_logic; 
		
		hsync : out std_logic;
		vsync : out std_logic
	);
	
end interface_vga;


architecture comportamental of interface_vga is

	signal x_pou : integer range 0 to hpou := 0;
	signal y_pou : integer range 0 to vpou := 0;
	
	signal x_start : integer range 0 to hplay := 0;
	signal y_start : integer range 0 to vplay := 0;
	
	
	signal x_fruta : integer range 0 to hsymbol := 0;
	signal y_fruta : integer range 0 to vsymbol := 0;
	
	signal y_pos_fruta : integer range 0 to ground := 0;
	
	signal x_pts : integer range 0 to hnum := 0;
	signal y_pts : integer range 0 to vnum := 0;
	
	signal hcount : integer range 0 to Ha+Hb+Hc+Hd;
	signal vcount : integer range 0 to Va+Vb+Vc+Vd;
	
	signal image_pou_on,imagem_menu,imagem_fruta,imagem_num,fruta_on: std_logic := '0';

	signal indice_menu : integer range 0 to 2;
	signal indice_fruta : integer range 0 to 4;
	signal indice_pontuacao : integer range 0 to 4;
	
	
	signal video_on : std_logic := '0';
   signal symbol : integer :=0;
	signal RGB : std_logic_vector(2 downto 0);
	signal rgb_pou,rgb_menu,rgb_fruta,rgb_pontos: std_logic_vector(2 downto 0);
	--signal estado_vga_in,estado_vga_out : integer range 0 to 3;
	signal menu,jogo,fruta,pontuacao : std_logic:='0';
	
	
begin

--==========================================================================================================================================================
--Inicio
--Posiciona e imprime o objeto "Pou_rom" na saida VGA
--se:
--new_game_in='1' and  pause_in='0' and start_in='1' and game_over_out='0' 
--a imagem "pou" é mostrada na tela.
	



------------------------------------------------------------
-- Mapeia a posicao e escrita da imatem do Pou no eixo x  --
------------------------------------------------------------
	

  process(clk_25MHz,reset,hcount)
		variable x_pos : integer range 0 to 640-hpou:=255;	--tipo definido para x_pos
		variable estado : integer range 0 to 3;
		variable posicoes_sorteadas : std_logic_vector (0 to 4);
		variable objetos_off : std_logic_vector (0 to 4);
		variable flag : std_logic;
		variable object : objetos;
		
		
	begin

		estado:=estado_in;
		estado_out<=estado;


		posicoes_sorteadas:=posicoes_frutas_in;
		
		object:=objetos_in; 
		
		x_pos:=x_posicao_in;
		
		

		
	
		
		if(reset = '0')then
			x_pou <= 0;
			x_pos:=255;
			estado_out<=0;
		--	game_over_out<='0';
			
		elsif((clk_25MHz'event and clk_25MHz = '1'))then

					if(estado=2) then
						jogo<='1';
						menu<='0';
					elsif(estado=0 or estado=1 or estado=3) then
						jogo<='0';
						menu<='1';
						game_over_out<='0';
						objetos_off:="11111";--teste - joga valor inicial para as posicoes
					end if;
				
				    if(vertical_fruta_in=380)then
						objetos_off:="11111";
					end if;
		
				
					if((x_pou <= hpou) and (hcount >= (x_pos) and hcount <= (x_pos+ hpou)) and (vcount < ground and vcount >=(ground-vpou))) then --a posicao "350 px" é o limite do "chao" do jogo.
				
						image_pou_on<='1';
						x_pou <= x_pou+1;
						
					else
						image_pou_on<='0';
						x_pou<=3;	
					end if;	
					x_posicao_out<=x_pos;
					
					
					
					
					

-----------------------------------------------------------------------------------		

								--Testa se houve encontro do pou com frutas.
					if(estado=2) then
					
						if (((x_pos>=x_f1 and x_pos<=(x_f1 + hsymbol)) or ((x_pos + hpou)>=x_f1 and (x_pos+ hpou)<=(x_f1 + hsymbol)) or (x_pos <=x_f1 and (x_pos+ hpou)>=(x_f1 + hsymbol))) and posicoes_sorteadas(0)='1' and y_pos_fruta<=vpou and (object(0)=0 or object(0)=1 or object(0)=2)) then
								flag:='1';
								objetos_off(0):='0';
						
						elsif (((x_pos>=x_f2 and x_pos<=(x_f2 + hsymbol)) or ((x_pos + hpou)>=x_f2 and (x_pos+ hpou)<=(x_f2 + hsymbol)) or (x_pos <=x_f2 and (x_pos+ hpou)>=(x_f2 + hsymbol))) and posicoes_sorteadas(1)='1' and y_pos_fruta<=vpou and (object(1)=0 or object(1)=1 or object(1)=2)) then
								flag:='1';
								objetos_off(1):='0';
									
						elsif (((x_pos>=x_f3 and x_pos<=(x_f3 + hsymbol)) or ((x_pos + hpou)>=x_f3 and (x_pos+ hpou)<=(x_f3 + hsymbol)) or (x_pos <=x_f3 and (x_pos+ hpou)>=(x_f3 + hsymbol))) and posicoes_sorteadas(2)='1' and y_pos_fruta<=vpou and (object(2)=0 or object(2)=1 or object(2)=2)) then
								flag:='1';
								objetos_off(2):='0';
						
						elsif (((x_pos>=x_f4 and x_pos<=(x_f4 + hsymbol)) or ((x_pos + hpou)>=x_f4 and (x_pos+ hpou)<=(x_f4 + hsymbol)) or (x_pos <=x_f4 and (x_pos+ hpou)>=(x_f4 + hsymbol))) and posicoes_sorteadas(3)='1' and y_pos_fruta<=vpou and (object(3)=0 or object(3)=1 or object(3)=2)) then
								flag:='1';
								objetos_off(3):='0';
									
						elsif (((x_pos>=x_f5 and x_pos<=(x_f5 + hsymbol)) or ((x_pos + hpou)>=x_f5 and (x_pos+ hpou)<=(x_f5 + hsymbol)) or (x_pos <=x_f5 and (x_pos+ hpou)>=(x_f5 + hsymbol))) and posicoes_sorteadas(4)='1' and y_pos_fruta<=vpou and (object(4)=0 or object(4)=1 or object(4)=2)) then
								flag:='1';
								objetos_off(4):='0';	

								
								--------------------------------------------------------------------//-------------------------------//-------------------------------
											
						elsif (((x_pos>=x_f1 and x_pos<=(x_f1 + hsymbol)) or ((x_pos + hpou)>=x_f1 and (x_pos+ hpou)<=(x_f1 + hsymbol)) or (x_pos <=x_f1 and (x_pos+ hpou)>=(x_f1 + hsymbol))) and posicoes_sorteadas(0)='1' and y_pos_fruta<=vpou and (object(0)=3 or object(0)=4)) then
								game_over_out<='1';
								flag:='0';
						
						elsif (((x_pos>=x_f2 and x_pos<=(x_f2 + hsymbol)) or ((x_pos + hpou)>=x_f2 and (x_pos+ hpou)<=(x_f2 + hsymbol)) or (x_pos <=x_f2 and (x_pos+ hpou)>=(x_f2 + hsymbol))) and posicoes_sorteadas(1)='1' and y_pos_fruta<=vpou and (object(1)=3 or object(1)=4)) then
								game_over_out<='1';
								flag:='0';
									
						elsif (((x_pos>=x_f3 and x_pos<=(x_f3 + hsymbol)) or ((x_pos + hpou)>=x_f3 and (x_pos+ hpou)<=(x_f3 + hsymbol)) or (x_pos <=x_f3 and (x_pos+ hpou)>=(x_f3 + hsymbol))) and posicoes_sorteadas(2)='1' and y_pos_fruta<=vpou and (object(2)=3 or object(2)=4)) then
								game_over_out<='1';
								flag:='0';
						
						elsif (((x_pos>=x_f4 and x_pos<=(x_f4 + hsymbol)) or ((x_pos + hpou)>=x_f4 and (x_pos+ hpou)<=(x_f4 + hsymbol)) or (x_pos <=x_f4 and (x_pos+ hpou)>=(x_f4 + hsymbol))) and posicoes_sorteadas(3)='1' and y_pos_fruta<=vpou and (object(3)=3 or object(3)=4)) then
								game_over_out<='1';
								flag:='0';
									
						elsif (((x_pos>=x_f5 and x_pos<=(x_f5 + hsymbol)) or ((x_pos + hpou)>=x_f5 and (x_pos+ hpou)<=(x_f5 + hsymbol)) or (x_pos <=x_f5 and (x_pos+ hpou)>=(x_f5 + hsymbol))) and posicoes_sorteadas(4)='1' and y_pos_fruta<=vpou and (object(4)=3 or object(4)=4)) then
								game_over_out<='1';
								flag:='0';
						else
								game_over_out<='0';
								flag:='0';
						end if;

				 posicoes_frutas_out<=(objetos_off and posicoes_sorteadas);--No momento em que a imagem do pou intercepta algum dos objetos, a imagem e retirada da tela.
				flag_pou_fruta_out<=flag;	
			 end if;--fim de if(estado=2)
-------------------------------------------------------------------------------------------------------------------------				
						
		end if;
			--	posicoes_frutas_out<=(objetos_off and posicoes_sorteadas);--No momento em que a imagem do pou intercepta algum dos objetos, a imagem e retirada da tela.
			--	flag_pou_fruta_out<=flag;
			
	end process;
	
------------------------------------------------------------
-- Mapeia a posicao e escrita da imagem do Pou no eixo y  --
------------------------------------------------------------	

	process(clk_25MHz,reset,vcount)
		
	begin
		if(reset = '0')then
			y_pou <= 0;
			
		elsif(clk_25MHz'event and clk_25MHz = '1')then
			
			if((Y_pou <= vpou) and (vcount < ground and vcount >=(ground - vpou)))then
					y_pou <= vcount - (ground - vpou);
			else
					y_pou<=0;			
			end if;
		
		end if;
		
	end process;
	
	
-----------------------------------------------
-- Varredura da Posição do Teclado na Matriz --
-----------------------------------------------

		instance_symbol: pou_rom
			port map(x_pou,y_pou,rgb_pou);

--Fim
--==========================================================================================================================================================

	


--==========================================================================================================================================================
--inicio
--Posiciona a imagem de cada menu na tela.

--Condicoes de inicio de jogo:
--new_game='0'
--pause='1'
--start(representa o play)='0'
--game_over(representa fim de jogo)='0'


process(clk_25MHz,reset,hcount)
	variable state : integer range 0 to 3:=0;
		
	begin
		state:=estado_in;
	
		if(state=0) then
			indice_menu<=0;--Mostra o botao "Jogar" na tela.
		elsif(state=1) then
			indice_menu<=1;--Mostra o botao "Pause" na tela.
		elsif(state=3) then
			indice_menu<=2;--Mostra "Game Over" na tela.
		end if;
	
	--	indice_menu<=1;
	
		if(reset = '0')then
			x_start <= 0;
		elsif(clk_25MHz'event and clk_25MHz = '1')then
		   if( (x_start <= hplay) and ((hcount >= (x_menu+10) and hcount < (x_menu+10+ hplay)) and (vcount < (ground-y_menu) and vcount >=(ground-y_menu-vplay)))) then
				imagem_menu<='1';
				x_start <= x_start+1;
				
			else
				imagem_menu<='0';
				x_start <=0;
			end if;	
		end if;
	end process;
	
------------------------------------------------------------
-- Mapeia a posicao e escrita da imagem dos menus no eixo y  --
------------------------------------------------------------	

	process(clk_25MHz,reset,vcount)
		
	begin
		
		if(reset = '0')then
			y_start <= 0;
			
		elsif(clk_25MHz'event and clk_25MHz = '1')then
			if((y_start <= vplay) and (vcount < (ground-y_menu) and vcount >=(ground - vplay- y_menu)))then
					y_start <= vcount - (ground - y_menu -vplay);
			else
					y_start<=0;			
			end if;
		
		end if;
		
	end process;




	instance_play: play_symbols 
		port map(indice_menu,x_start,y_start,rgb_menu);--Índice =0 -> Imagem "start"





--fim
--==========================================================================================================================================================






--==========================================================================================================================================================
--inicio
--Posiciona a imagem de cada fruta na tela.

--Condicoes de inicio de jogo:
--new_game='0'
--pause='1'
--start(representa o play)='0'
--game_over(representa fim de jogo)='0'


process(clk_25MHz,reset,hcount)
		variable fruta_onoff : std_logic:='0';
		variable posicoes_sorteadas : std_logic_vector (0 to 4);
		variable objetos_sorteados: objetos;

	begin
		indice_fruta<=0;
		fruta<='1';--teste
		
		posicoes_sorteadas :=posicoes_frutas_in;

			
		objetos_sorteados:=objetos_in;
	--	objetos_out<=objetos_sorteados;
		
		if(hcount >= (x_f1) and hcount < (x_f1 + hsymbol) and posicoes_sorteadas(0)='1') then
			indice_fruta<=objetos_sorteados(0);
			fruta_onoff:='1';
			fruta_on<='1';
		elsif(hcount >= (x_f2) and hcount < (x_f2+ hsymbol)  and posicoes_sorteadas(1)='1') then
			indice_fruta<=objetos_sorteados(1);
			fruta_onoff:='1';
			fruta_on<='1';
		elsif(hcount >= (x_f3) and hcount < (x_f3+ hsymbol)  and posicoes_sorteadas(2)='1') then
			indice_fruta<=objetos_sorteados(2);
			fruta_onoff:='1';
			fruta_on<='1';
		elsif(hcount >= (x_f4) and hcount < (x_f4 + hsymbol)  and posicoes_sorteadas(3)='1') then
			indice_fruta<=objetos_sorteados(3);
			fruta_onoff:='1';
			fruta_on<='1';
		elsif(hcount >= (x_f5) and hcount < (x_f5 + hsymbol)  and posicoes_sorteadas(4)='1') then
			indice_fruta<=objetos_sorteados(4);
			fruta_onoff:='1';
			fruta_on<='1';
		else
			fruta_onoff:='0';
			fruta_on<='0';
		end if;
		
		
		
		
		
		
		if(reset = '0')then
			x_fruta <= 0;
		elsif(clk_25MHz'event and clk_25MHz = '1')then
		   if( (x_fruta <= hsymbol) and (fruta_onoff='1' and (vcount < (ground-y_pos_fruta) and vcount >=(ground-vsymbol-y_pos_fruta)))) then
				imagem_fruta<='1';
				x_fruta <= x_fruta+1;
				
			else
				imagem_fruta<='0';
				x_fruta <=0;
			end if;	
		end if;
	end process;
	
------------------------------------------------------------
-- Mapeia a posicao e escrita da imagem das frutas no eixo y  --
------------------------------------------------------------	

	process(clk_25MHz,reset,vcount)
		variable  posicao_fruta : integer range 0 to ground;
	begin
		posicao_fruta:=vertical_fruta_in;
		y_pos_fruta<=posicao_fruta;--y_pos_fruta e usado no process do POU para verificar encontro das imagens do pou com as frutas.
		
		if(reset = '0')then
			y_fruta <= 0;
			
		elsif(clk_25MHz'event and clk_25MHz = '1')then
			if((y_fruta <= vsymbol) and (vcount < (ground-posicao_fruta) and vcount >=(ground - vsymbol-posicao_fruta)))then
					y_fruta <= vcount - (ground - vsymbol-posicao_fruta);									--vsymbol= tamanho vertical da imagem da fruta
			else
					y_fruta<=0;			
			end if;
		   vertical_fruta_out<=posicao_fruta;
		end if;
		
	end process;




	instance_fruta: rom_symbols
		port map(indice_fruta,x_fruta,y_fruta,rgb_fruta);





--fim
--==========================================================================================================================================================





--==========================================================================================================================================================
--inicio
--Posiciona a imagem de cada número de pontuação na tela.

--Condicoes de inicio de jogo:
--new_game='0'
--pause='1'
--start(representa o play)='0'
--game_over(representa fim de jogo)='0'


process(clk_25MHz,reset,hcount)
		variable num_onoff : std_logic:='0';
		variable digitos_CDU:  digitos;
		
	begin
	
		
		pontuacao<='1';--teste
		
		digitos_CDU:=digitos_pontuacao_in;

		
		if(hcount >= (x_centena) and hcount < (x_centena + hnum)) then
			indice_pontuacao<=digitos_CDU(0);
			num_onoff:='1';
		elsif(hcount >= (x_dezena) and hcount < (x_dezena+ hnum)) then
			indice_pontuacao<=digitos_CDU(1);
			num_onoff:='1';
		elsif(hcount >= (x_unidade) and hcount < (x_unidade+ hnum)) then
			indice_pontuacao<=digitos_CDU(2);
			num_onoff:='1';
		else
			num_onoff:='0';
		end if;
		
	
		if(reset = '0')then
			x_pts <= 0;
		elsif(clk_25MHz'event and clk_25MHz = '1')then
		   if( (x_pts <= hnum) and (num_onoff='1' and (vcount > (ground+y_numero) and vcount <=(ground+vnum+y_numero)))) then
				imagem_num<='1';
				x_pts <= x_pts+1;
			else
				imagem_num<='0';
				x_pts <=0;
			end if;	
		end if;
	end process;

------------------------------------------------------------
-- Mapeia a posicao e escrita da imagem dos menus no eixo y  --
------------------------------------------------------------	

	process(clk_25MHz,reset,vcount)
	begin
		
		if(reset = '0')then
			y_pts <= 0;
			
		elsif(clk_25MHz'event and clk_25MHz = '1')then
			if((y_pts <= vnum) and (vcount > (ground +y_numero) and vcount <=(ground + vnum +y_numero)))then
					y_pts <= vcount - (ground+y_numero);
			else
					y_pts<=0;			
			end if;
		
		end if;
		
	end process;




	instance_pontos: rom_num 
		port map(indice_pontuacao,x_pts,y_pts,rgb_pontos);--Índice =0 -> Imagem "start"





--fim
--==========================================================================================================================================================







--==========================================================================================================================================================
--inicio
--Saída VGA







	instance_sync: generate_vga_sync
		generic map(Ha,Hb,Hc,Hd,Va,Vb,Vc,Vd)
		port map(clk_25MHz,reset,hsync,vsync,hcount,vcount,video_on);
		

		
	RGB <= rgb_pou when ( jogo='1' and image_pou_on ='1' ) else --Se play='1' o jogo está rodando.
			 rgb_menu when (menu='1' and imagem_menu ='1'  ) else --mostra a imagem dos menus.
			 rgb_fruta when (fruta='1' and imagem_fruta ='1'  ) else --mostra a imagem das frutas.
			 rgb_pontos when (pontuacao='1' and imagem_num ='1'  ) else --mostra a imagem das frutas.
			 "000";
		
												
	
		
				
	R <= 		   RGB(2) when ( (jogo='1' and image_pou_on ='1')   and (hcount >= 0 and hcount < 640 and vcount < 480 and video_on = '1'))  --Imagem do pou quando estiver on.
			else	RGB(2) when ( (menu='1' and imagem_menu ='1' )   and (hcount >= 0 and hcount < 640 and vcount < 480 and video_on = '1')) --Imagem do menu quando estiver on.
			else	RGB(2) when ( (jogo='1' and imagem_fruta ='1' )   and (hcount >= 0 and hcount < 640 and vcount < 480 and video_on = '1')) --Imagem da fruta quando estiver on.
			else	RGB(2) when ( (jogo='1' and imagem_num ='1' )   and (hcount >= 0 and hcount < 640 and vcount < 480 and video_on = '1')) --Imagem da pontuacao quando estiver on.
			else '0' when ( ( jogo='1'  and image_pou_on ='0') and (hcount >= 0 and hcount < 640 and vcount < ground and video_on = '1')) --fundo azul rgb=001 para status "jogando"
			else '0' when ( ( (jogo='1' and pontuacao='1') and imagem_num ='0') and (hcount >= 0 and hcount < 640 and vcount >=ground and video_on = '1')) --fundo verde rgb=010 para status "jogando"
			else '0' when ( ( menu='1'  and imagem_menu ='0') and (hcount >= 0 and hcount < 640 and vcount < ground and video_on = '1')) --fundo azul rgb=001 para status "Menu"
			else '0' when ((menu='1' and imagem_menu ='0') and (hcount >= 0 and hcount < 640 and vcount >=ground and video_on = '1')) --fundo azul para start, pause ou game over(parte de baixo)
			else '0';
					
	G <=  	   RGB(1) when ( (jogo='1' and image_pou_on ='1')   and (hcount >= 0 and hcount < 640 and vcount < 480 and video_on = '1'))  --Imagem do pou quando estiver on.
			else	RGB(1) when ( (menu='1' and imagem_menu ='1' )   and (hcount >= 0 and hcount < 640 and vcount < 480 and video_on = '1')) --Imagem do menu quando estiver on.
			else	RGB(1) when ( (jogo='1' and imagem_fruta ='1' )   and (hcount >= 0 and hcount < 640 and vcount < 480 and video_on = '1')) --Imagem da fruta na quando estiver on.
			else	RGB(1) when ( (jogo='1' and imagem_num ='1' )   and (hcount >= 0 and hcount < 640 and vcount < 480 and video_on = '1')) --Imagem da pontuacao na quando estiver on.
			else '0' when ( ( jogo='1'  and image_pou_on ='0') and (hcount >= 0 and hcount < 640 and vcount < ground and video_on = '1')) --fundo azul rgb=001 para status "jogando"
			else '1' when ( ( (jogo='1' and pontuacao='1') and imagem_num ='0') and (hcount >= 0 and hcount < 640 and vcount >=ground and video_on = '1')) --fundo verde rgb=010 para status "jogando"
			else '0' when ( ( menu='1'  and imagem_menu ='0') and (hcount >= 0 and hcount < 640 and vcount < ground and video_on = '1')) --fundo azul rgb=001 para status "Menu"
			else '0' when ((menu='1' and imagem_menu ='0') and (hcount >= 0 and hcount < 640 and vcount >=ground and video_on = '1')) --fundo azul para start, pause ou game over(parte de baixo)
			else '0';
					
	B <=  	   RGB(0) when ( (jogo='1' and image_pou_on ='1')   and (hcount >= 0 and hcount < 640 and vcount < 480 and video_on = '1'))  --Imagem do pou  quando estiver on.
			else	RGB(0) when ( (menu='1' and imagem_menu ='1' )   and (hcount >= 0 and hcount < 640 and vcount < 480 and video_on = '1')) --Imagem da menu quando estiver on.
			else	RGB(0) when ( (jogo='1' and imagem_fruta ='1' )   and (hcount >= 0 and hcount < 640 and vcount < 480 and video_on = '1')) --Imagem da fruta  quando estiver on.
			else	RGB(0) when ( (jogo='1' and imagem_num ='1' )   and (hcount >= 0 and hcount < 640 and vcount < 480 and video_on = '1')) --Imagem da pontuacao na quando estiver on.
			else '1' when ( ( jogo='1'  and image_pou_on ='0') and (hcount >= 0 and hcount < 640 and vcount < ground and video_on = '1')) --fundo azul rgb=001 para status "jogando"
			else '0' when ( ( (jogo='1' and pontuacao='1') and imagem_num ='0') and (hcount >= 0 and hcount < 640 and vcount >=ground and video_on = '1')) --fundo verde rgb=010 para status "jogando"
			else '1' when ( ( menu='1'  and imagem_menu ='0') and (hcount >= 0 and hcount < 640 and vcount < ground and video_on = '1')) --fundo azul rgb=001 para status "Menu"
			else '1' when ((menu='1' and imagem_menu ='0') and (hcount >= 0 and hcount < 640 and vcount >=ground and video_on = '1')) --fundo azul para start, pause ou game over(parte de baixo)
			else '0';


end comportamental;