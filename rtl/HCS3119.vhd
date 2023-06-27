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
--		CS310n             : OUT STD_LOGIC;      
		CS314n             : OUT STD_LOGIC;
		CS318n             : OUT STD_LOGIC;
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
	signal PH2_1: std_logic;
   signal PH2_2: std_logic;
   signal PH2_3: std_logic;
   signal PH2_old: std_logic_vector(3 downto 0);
   signal PH2_cntr: std_logic_vector(4 downto 0);
	
	
	SIGNAL EDGE_DETECT : STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL ADR: std_logic_vector (7 downto 0);

begin
         ADR <= A(7 downto 2) & "00";
			-- Reset
			PROCESS (PH2,RnW,WD_REn_INT,CS1793n_INT) IS
			BEGIN
				WD_REn_INT <= NOT RnW or CS1793n_INT;
			   WD_REn <= WD_REn_INT; 
			   WD_WEn <= RnW or CS1793n_INT;

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
			MAPn_INT <= '0' when  PA ="000" and A(15 downto 14) = "11" else '1' ;
			
			--
			MAPn <= MAPn_INT;
         CS1793n <= CS1793n_INT;
			WD_CLK <= PH2_2;

			
			--
			CS300n     <= '0' when (ADR>=x"00") and (ADR<=x"0F") AND IO = '0' else '1';
			CS320n     <= '0' when (ADR>=x"20") and (ADR<=x"2F") AND IO = '0' else '1';
			
			CS1793n_INT<= '0' WHEN (ADR>=x"10") and (ADR<=x"13") AND IO = '0' ELSE '1';
			CS314n     <= '0' WHEN (ADR>=x"14") and (ADR<=x"17") AND IO = '0' ELSE '1';
			CS318n     <= '0' WHEN (ADR>=x"18") and (ADR<=x"1B") AND IO = '0' ELSE '1';
			CS31Cn     <= '0' WHEN (ADR>=x"1C") and (ADR<=x"1F") AND IO = '0' ELSE '1';
			
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
						PH2_2 <= '0';
					ELSIF rising_edge(CLK_SYS) THEN
						PH2_2 <= '0';
						if count = 0 then
							PH2_2 <= '1';
						end if;
						count := count + 1;
					END IF;
				END PROCESS;
				

END Behavioral;