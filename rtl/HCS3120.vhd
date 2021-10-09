-- HCS3120
-- Top Level Entity
-- Copyright 2010 Retromaster
--
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
		
		-- Oric Expansion Port Signals
		DI              : IN std_logic_vector(7 DOWNTO 0); -- 6502 Data Bus
		DO              : OUT std_logic_vector(7 DOWNTO 0); -- 6502 Data Bus
 
		A               : IN std_logic_vector(15 DOWNTO 0); -- 6502 Address Bus
		RnW             : IN std_logic; -- 6502 Read-/Write
		nIRQ            : OUT std_logic; -- 6502 /IRQ
		PH2             : IN std_logic; -- 6502 PH2
		IO              : IN std_logic; -- Oric I/O
		IOCTRL          : OUT std_logic; -- Oric I/O Control  

		-- Additional MCU Interface Lines
		nRESET          : IN std_logic; -- RESET from MCU
		--
		SS              : OUT std_logic;

		DS0             : OUT std_logic;
		DS1             : OUT std_logic;
		DS2             : OUT std_logic;
		DS3             : OUT std_logic;


  		DAL_IN          : OUT std_logic_vector(7 DOWNTO 0); -- 6502 Data Bus
		DAL_OUT         : IN  std_logic_vector(7 DOWNTO 0); -- 6502 Data Bus
		
		WD_REn          : IN STD_LOGIC;
		WD_IRQ          : IN  std_logic;
		WD_DRQ          : IN  std_logic

		
		
 
	);
END HCS3120;

ARCHITECTURE Behavioral OF HCS3120 IS

	SIGNAL sel : std_logic; 
	SIGNAL u16k : std_logic;
	SIGNAL DSEL : std_logic_vector(1 DOWNTO 0); -- Drive Select
 	SIGNAL IRQEN : std_logic; -- IRQ Enable
	SIGNAL DSK_ACTIVE : std_logic;

BEGIN
			-- Select signal (Address Range 031-)
			--sel <= '1' WHEN A(7 DOWNTO 4) = "0001" AND IO = '0' AND A(3 DOWNTO 2) /= "11" ELSE '0';
         sel <= not IO;
 
			-- ORIC Expansion Port Signals
			IOCTRL <= '0' WHEN sel = '1' ELSE '1';
			nIRQ <= '0' WHEN WD_IRQ = '1' AND IRQEN = '1' ELSE '1'; 
          
         DS0 <= '1' when DSEL = "00" and sel ='1' else '0';
			DS1 <= '1' when DSEL = "01" and sel ='1' else '0';
			DS2 <= '1' when DSEL = "10" and sel ='1' else '0';
			DS3 <= '1' when DSEL = "11" and sel ='1' else '0';
			
			DSK_ACTIVE <= '0' WHEN sel = '1' AND A(3 DOWNTO 2) = "00" ELSE '1';

			-- Data Bus Control.
			PROCESS (RnW, DAL_OUT, WD_DRQ, WD_IRQ, WD_REn, A, DSK_ACTIVE )
			BEGIN
				IF RnW = '1' THEN 
					IF A(3 DOWNTO 2) = "10" THEN
						   DO <= (NOT WD_DRQ) & "-------";
						ELSIF A(3 DOWNTO 2) = "01" THEN
							DO <= (NOT WD_IRQ) & "-------";
						ELSIF WD_REn = '0' AND DSK_ACTIVE = '0' THEN
							DO <= DAL_OUT; 
					   ELSE
						   DO <= "--------"; 
					END IF;
				ELSE
					DO <= "ZZZZZZZZ"; 
				END IF;
			END PROCESS; 
			
 			-- Control Register.
			PROCESS (sel, A, RnW, DI, nRESET,DSEL,CLK_SYS)
				BEGIN
					IF nRESET = '0' THEN
						DSEL <= "00";
						SS <= '0';
						IRQEN <= '0'; 
					ELSIF rising_edge(CLK_SYS) THEN
						IF sel = '1' AND A(3 DOWNTO 2) = "01" AND RnW = '0' THEN
							DSEL <= DI(6 DOWNTO 5);
							SS <= DI(4);
							IRQEN <= DI(0);
						END IF;
					END IF;
				END PROCESS;


END Behavioral;