library ieee;
use ieee.std_logic_1164.all;

package vga_package is

--Tamanho da imagem do objeto "Pou_rom"
constant vpou : natural := 99;--100-1
constant hpou : natural := 99;--100-1

--Tamanho da imagem das frutas
constant vsymbol : natural := 39;--40-1
constant hsymbol : natural := 39;--40-1

--Tamanho da imagem dos menus
constant vplay : natural := 79;--80-1
constant hplay : natural := 149; --150-1

--Tamanho da imagem dos numeros
constant vnum : natural := 39;--40-1
constant hnum : natural := 39; --40-1
-------------------------------------------------------------------------------

--Limite vertical para o "chão" do objeto "POU"
constant ground : natural := 380;

--Coordenadas de posicao da imagem dos menus
constant x_menu : natural := 230;
constant y_menu : natural := 200;--A posicao vertical do menu fica: 480 - y_menu
 
--Coordenadas de posicao da imagem dos numeros
constant x_centena : natural := 220;
constant x_dezena : natural := 290;
constant x_unidade : natural := 360;
constant y_numero : natural := 30;--A posicao vertical do menu fica: 480 - y_centena


--Coordenadas de posicao da imagem das frutas
constant x_f1 : natural := 15;
constant x_f2 : natural := 155;
constant x_f3 : natural := 290;
constant x_f4 : natural := 440;
constant x_f5 : natural := 580;

-------------------------------------------------------------------------------------

type matrix_play is array(0 to vplay, 0 to hplay) of std_logic_vector(2 downto 0);--Definicao do tipo de dados das figuras de menu.
type matrix_pou is array(0 to vpou, 0 to hpou) of std_logic_vector(2 downto 0);--Definicao do tipo de dados da matriz do objeto "Pou_rom"
type matrix_symbol is array(0 to hsymbol, 0 to vsymbol) of std_logic_vector(2 downto 0);--Definicao do tipo de dados da matriz de figuras para os alimentos do jogo.
type matrix_num is array(0 to hnum, 0 to vnum) of std_logic_vector(2 downto 0);--Definicao do tipo de dados da matriz de figuras para os alimentos do jogo.

type digitos is array (0 TO 2) of integer range 0 TO 9;

type objetos is array (0 TO 4) of integer range 0 TO 4;

type switch is (sw0,sw1,sw2,sw3,sw4,sw);



		
------------------------------------------------------------------------		

	component generate_clock is
	
		port(
			clk	  : in  std_logic;
			reset   : in  std_logic;
			clk_out : out std_logic
		);
	
	end component;


	component generate_vga_sync is
		
		generic(	
			H_a : natural := 96;	 -- Retrace
			H_b : natural := 48;	 -- Left Border
			H_c : natural := 640; -- Display 640
			H_d : natural := 16;	 -- Right Border
			V_a : natural := 3;	 -- Retrace
			V_b : natural := 32;	 -- Top Border
			V_c : natural := 480; -- Display 480
			V_d : natural := 10	 -- Bottom Border
		);		
		port(
			clk	: in  std_logic; -- 25MHz
			reset : in  std_logic;
			hsync : out std_logic;
			vsync : out std_logic;			
			hcount: out integer range 0 to H_a+H_b+H_c+H_d;
			vcount: out integer range 0 to V_a+V_b+H_c+H_d;			
			video_on: out std_logic
		);
		
	end component;
---------------------------------------------------
	
	component interface_vga is

		port(
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
		--objetos_out : out objetos;
		

		flag_pou_fruta_in : in std_logic;
		flag_pou_fruta_out : out std_logic;
		
		--game_over_in : in std_logic;
		game_over_out : out std_logic;
		
		-- Output ports VGA type
		R : out std_logic;
		G : out std_logic;
		B : out std_logic; 
		
		hsync : out std_logic;
		vsync : out std_logic
	);	
	
	end component;
		
---------------------------------------------------
		component rom_symbols is
	
		port(
			index : in integer range 0 to 4;
			x_symbol : in integer range 0 to hsymbol;
			y_symbol : in integer range 0 to vsymbol;
			rgb_color : out std_logic_vector(2 downto 0)
		);		
		
	end component;
	
	
	component rom_num is
	
	port
	(
		-- Input ports
		index : in integer range 0 to 9;
		x_num : in integer range 0 to hnum;
		y_num : in integer range 0 to vnum;
		-- Output ports
		rgb_num : out std_logic_vector(2 downto 0) 
	);
	end component;
	
	component play_symbols is
	
		port(
			index : in integer range 0 to 2;
			x_play : in integer range 0 to hplay;
			y_play : in integer range 0 to vplay;
			rgb_colour : out std_logic_vector(2 downto 0)
		);		
		
	end component;
	
	component pou_rom is
	
		port(
			x_pou : in integer range 0 to hpou;
			y_pou : in integer range 0 to vpou;
			rgb_pou : out std_logic_vector(2 downto 0) 
		);		
		
	end component;
	
	-- Filtro para Botão ou Chave

	component debouncing_filter is
	
		port(
			sw : in std_logic;
			clk : in  std_logic;
			deb_sw : buffer std_logic
		);
		
	end component;
	
	
	component Key_read is
	
		port(	

		-- Input ports
		clk_in : in  std_logic;
		clk_25MHz : in  std_logic;
		reset: in std_logic;
		
		x_pos_in: in integer range 0 to 640-hpou :=265;
		x_pos_out: out integer range 0 to 640-hpou :=265;
		chaves: in switch;
		
		pause_on_in : in std_logic;	--Pausar o jogo
		pause_on_out : out std_logic	--Pausar o jogo
		);
	end component;	
	

end vga_package;