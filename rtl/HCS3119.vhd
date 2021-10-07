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
		DI              : IN std_logic_vector(7 DOWNTO 0); -- 6502 Data Bus
 
		A               : IN std_logic_vector(15 DOWNTO 0); -- 6502 Address Bus
		RnW             : IN std_logic; -- 6502 Read-/Write
		nIRQ            : OUT std_logic; -- 6502 /IRQ
		IO              : IN std_logic;
		PH2             : IN std_logic; -- 6502 PH2
		MAPn            : OUT std_logic; -- Oric MAP
		IOCTRL          : OUT std_logic; -- Oric I/O Control 
		nHOSTRST        : OUT std_logic; -- Oric RESET
      -- VIA
		PA              : IN std_logic_vector (2 downto 0) := "111";
      
	   -- CS Lines	
      CS300n             : OUT std_logic;
      CS310n             : OUT std_logic;
      CS320n             : OUT std_logic;
		CS1793n            : OUT std_logic;
      CS0n               : OUT std_logic;
      CS1n               : OUT std_logic;
		CS2n               : OUT std_logic;
      CS3n               : OUT std_logic;
      CS4n               : OUT std_logic;
      CS5n               : OUT std_logic;
      CS6n               : OUT std_logic;
		CSB0n              : OUT STD_LOGIC;
		
		--WD output
		WD_CLK             : OUT std_logic;
      WD_CSn             : OUT std_logic;
		WD_WEn             : OUT std_logic;
		WD_REn             : OUT std_logic;
		WD_DRQ             : IN std_logic;
		WD_IRQ             : IN std_logic;
		
		-- Additional MCU Interface Lines
		nRESET          : IN std_logic -- RESET
 

	);
END HCS3119;

ARCHITECTURE Behavioral OF HCS3119 IS



	-- Status
 
 

 
	SIGNAL U16K : std_logic;
	SIGNAL MAPn_INT : std_logic;
	SIGNAL CS1793n_INT : std_logic;
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
			MAPn <= MAPn_INT;
         CS1793n <= CS1793n_INT;
			
			WD_REn <= CS1793n_INT OR NOT RnW;
			WD_WEn <= CS1793n_INT OR RnW;
			
			CS300n     <= '0' when A(7 downto 4) = "0000" AND IO = '0' else '1';
			CS320n     <= '0' when A(7 downto 4) = "0010" AND IO = '0' else '1';
			CS1793n_INT<= '0' WHEN A(7 DOWNTO 4) = "0001" AND IO = '0' AND A(3 DOWNTO 2) /= "11" ELSE '1';
			CS310n     <= '0' WHEN A(7 DOWNTO 4) = "0001" AND IO = '0' AND A(3 DOWNTO 2) = "11" ELSE '1';
			
			
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