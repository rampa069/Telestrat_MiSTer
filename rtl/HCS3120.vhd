-- HCS3120
-- Top Level Entity
-- Copyright 2021 rampa
-- Distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with Cumulus CPLD Core. If not, see .
--

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY HCS3120 IS

	PORT 
	(
		CLK_SYS         : IN std_logic; -- 24 Mhz input clock
		WD_CLK          : IN STD_LOGIC;
		
		-- Oric Expansion Port Signals
		DI              : IN std_logic_vector(7 DOWNTO 0); -- 6502 Data Bus
		DO              : OUT std_logic_vector(7 DOWNTO 0); -- 6502 Data Bus
		--FDC_DAL_OUT     : IN std_logic_vector(7 DOWNTO 0);
 		A               : IN std_logic_vector(15 DOWNTO 0); -- 6502 Address Bus
	
		
		RnW             : IN std_logic; -- 6502 Read-/Write
		nIRQ            : OUT std_logic; -- 6502 /IRQ
		IO              : IN std_logic; -- Oric I/O
		CS314n          : IN std_logic; -- Microdisk registers
		CS318n          : IN std_logic; -- Microdisk registers
		CS1793n         : IN std_logic; -- WD1793 chip select
		--IOCTRL          : OUT std_logic; -- Oric I/O Control  

		-- Additional MCU Interface Lines
		nRESET          : IN std_logic; -- RESET from MCU
		--
		SS              : OUT std_logic; -- side select

		DS0             : OUT std_logic; 
		DS1             : OUT std_logic;
		DS2             : OUT std_logic;
		DS3             : OUT std_logic;

		
		WD_REn          : IN STD_LOGIC;
		WD_IRQ          : IN std_logic;
		WD_DRQ          : IN std_logic;
		WD_HLD          : IN std_logic
	);
END HCS3120;

ARCHITECTURE Behavioral OF HCS3120 IS

	SIGNAL DSEL : std_logic_vector(1 DOWNTO 0); -- Drive Select
 	SIGNAL IRQEN : std_logic; -- IRQ Enable
	
BEGIN 
			-- ORIC Expansion Port Signals
			nIRQ <= '0' WHEN WD_IRQ = '1' AND IRQEN = '1' ELSE '1'; 
          
         DS0 <= '1' when DSEL = "00" and WD_HLD ='1' else '0';
			DS1 <= '1' when DSEL = "01" and WD_HLD ='1' else '0';
			DS2 <= '1' when DSEL = "10" and WD_HLD ='1' else '0';
			DS3 <= '1' when DSEL = "11" and WD_HLD ='1' else '0';
			
			-- Data Bus Control.
			PROCESS (RnW, WD_DRQ, WD_IRQ, CS318n,CS314n)
			BEGIN
					IF Cs318n = '0' THEN
					   DO <= (not WD_DRQ) & "-------"; 
					ELSIF CS314n = '0' THEN
						DO <= (NOT WD_IRQ) & "-------";
					ELSE
					   DO <= "--------"; 
					END IF;
			END PROCESS; 
			
 			-- Control Register.
			PROCESS (WD_CLK,CS314n,RnW,DI,nRESET,DSEL)
				BEGIN
					IF nRESET = '0' THEN
						DSEL  <= "00";
						SS    <= '0';
						IRQEN <= '0';
						
					ELSIF rising_edge(WD_CLK) THEN
						IF CS314n ='0' AND RnW = '0' THEN
							DSEL <= DI(6 DOWNTO 5);
							SS   <= DI(4);
							IRQEN<= DI(0);
						END IF;
					END IF;
				END PROCESS;


END Behavioral;