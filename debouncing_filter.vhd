LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY debouncing_filter IS
	GENERIC(	fclk: NATURAL := 50; --Frequencia do clock em MHz.
				twindow: NATURAL := 20); --Janela de tempo em ms.
	PORT (	sw: IN STD_LOGIC;
			clk: IN STD_LOGIC;
			deb_sw: BUFFER STD_LOGIC);
END ENTITY;

ARCHITECTURE digital_debouncer OF debouncing_filter IS
	CONSTANT max: NATURAL := 1000 * fclk * twindow;
BEGIN
	PROCESS (clk)
		VARIABLE count: NATURAL RANGE 0 TO max;
	BEGIN
		IF (clk'EVENT AND clk='1') THEN
			IF (deb_sw /= sw) THEN
				count := count + 1;
				IF (count=max) THEN
					deb_sw <= sw;
					count := 0;
				END IF;
			ELSE
				count := 0;
			END IF;
		END IF;
	END PROCESS;
END digital_debouncer;