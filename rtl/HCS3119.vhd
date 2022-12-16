-- HCS3119
-- Top Level Entity
-- Copyright 2021 rampa
--
-- This is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License,
-- or any later version.
--
--

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY HCS3119 IS

	PORT 
	(
		CLK_SYS         : IN std_logic; -- 24 Mhz input clock
		-- Oric Expansion Port Signals
		A               : IN std_logic_vector(15 DOWNTO 0); -- 6502 Address Bus
		RnW             : IN std_logic; -- 6502 Read-/Write
		IO              : IN std_logic;
		PH2             : IN std_logic; -- 6502 PH2
		MAPn            : OUT std_logic; -- Oric MAP
		nHOSTRST        : OUT std_logic; -- Oric RESET
      -- VIA
		PA              : IN std_logic_vector (2 downto 0) := "111";
      
	   -- CS Lines	
      CS300n             : OUT std_logic;
		CS310n             : OUT STD_LOGIC;
		CS314n             : OUT STD_LOGIC;
		CS31Cn             : OUT STD_LOGIC;
      CS320n             : OUT std_logic;
		CS1793n            : OUT std_logic;
      CS0n               : OUT std_logic;
      CS1n               : OUT std_logic;
		CS2n               : OUT std_logic;
      CS3n               : OUT std_logic;
      CS4n               : OUT std_logic;
      CS5n               : OUT std_logic;
      CS6n               : OUT std_logic;
		
		--WD output
		WD_CLK             : OUT std_logic;
		WD_WEn             : OUT std_logic;
		WD_REn             : OUT std_logic;
		WD_DRQ             : IN std_logic;
		WD_IRQ             : IN std_logic;
		
		-- Additional MCU Interface Lines
		nRESET          : IN std_logic -- RESET
 

	);
END HCS3119;

ARCHITECTURE Behavioral OF HCS3119 IS


	SIGNAL U16K : std_logic;
	SIGNAL MAPn_INT : std_logic;
	SIGNAL CS1793n_INT : std_logic;
	SIGNAL CS310n_INT : std_logic;
	SIGNAL WD_REn_INT  : std_logic;
	
	SIGNAL EDGE_DETECT : STD_LOGIC_VECTOR(1 DOWNTO 0);

begin
			-- Reset
			PROCESS (PH2) IS
			BEGIN
			  if RISING_EDGE(PH2) THEN
			    EDGE_DETECT <= EDGE_DETECT(0) & nRESET;
				 IF EDGE_DETECT = "10" THEN
				    nHOSTRST <= '0';
			    ELSIF EDGE_DETECT = "01" THEN
				    nHOSTRST <='1';
				 END IF;
			  END IF;
			END PROCESS;
			
			--MAP signal
			MAPn_INT <= '0' when (PH2='1' and PA ="000" and A(15 downto 14) = "11") else '1' ;
			
			--
			MAPn <= MAPn_INT;
         CS1793n <= CS1793n_INT;
			CS310n <= CS310n_INT;
			--
			WD_REn_INT <= CS1793n_INT AND NOT RnW;
			WD_REn <= WD_REn_INT; 
			WD_WEn <= CS1793n_INT AND  RnW;

			--

			CS300n     <= '0' when A(15 downto 4) = x"030" AND IO = '0' else '1';
			CS320n     <= '0' when A(15 downto 4) = x"032" AND IO = '0' else '1';
			CS310n_INT <= '0' WHEN A(15 DOWNTO 4) >= x"0310" AND A(15 DOWNTO 4) <= x"0313" AND IO ='0'  ELSE '1';
			CS314n     <= '0' WHEN A(15 DOWNTO 4) >= x"0314" AND A(15 DOWNTO 4) <= x"0318" AND IO ='0'  ELSE '1';
			CS31Cn     <= '0' WHEN A(15 DOWNTO 4) >= x"031C" AND A(15 DOWNTO 4) <= x"031F" AND IO = '0' ELSE '1';
			CS1793n_INT<= '0' WHEN CS310n_INT = '0' AND PH2 ='1' ELSE '1';
			
			
			-- 
			U16K <= '1' when A(15 downto 14) = "11" and MAPn_INT ='1'   else '0';
			
			
			CS6n    <= '0' when PA = "111" and U16K = '1'  else '1';
			CS5n    <= '0' when PA = "110" and U16K = '1'  else '1';
			CS4n    <= '0' when PA = "101" and U16K = '1'  else '1';
			CS3n    <= '0' when PA = "100" and U16K = '1'  else '1';
			CS2n    <= '0' when PA = "011" and U16K = '1'  else '1';
			CS1n    <= '0' when PA = "010" and U16K = '1'  else '1';
			CS0n    <= '0' when PA = "001" and U16K = '1'  else '1';
			
			-- FDC clock enable: 24/6 = 4MHz
			PROCESS (nRESET, CLK_SYS)
				VARIABLE count: integer range 0 to 5;
				BEGIN
					IF nRESET = '0' THEN
						count := 0;
						WD_CLK <= '0';
					ELSIF rising_edge(CLK_SYS) THEN
						WD_CLK <= '0';
						if count = 0 then
							WD_CLK <= '1';
						end if;
						count := count + 1;
					END IF;
				END PROCESS;

END Behavioral;