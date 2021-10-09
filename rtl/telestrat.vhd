--
-- A simulation model of ORIC TELESTRAT hardware
-- Based on the ORIC ATMOS Core (initial  Copyright (c) SEILEBOST - March 2006)
-- 
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS CODE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- You are responsible for any legal issues arising from your use of this code.
--
-- The latest version of this file can be found at: passionoric.free.fr
--
-- Email seilebost@free.fr
--
--

  library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

  
entity telestrat is
  port (
    CLK_IN            : in    std_logic;
	 CLK_ACIA          : in    std_logic;
	 CLK_DISK          : in    std_logic;
    RESET             : in    std_logic;
	 key_pressed       : in    std_logic;
	 key_extended      : in    std_logic;
	 key_code          : in    std_logic_vector(7 downto 0);
	 key_strobe        : in    std_logic;
    K7_TAPEIN         : in    std_logic;
    K7_TAPEOUT        : out   std_logic;
    K7_REMOTE         : out   std_logic;
	 PSG_OUT           : out   std_logic_vector(9 downto 0);
    PSG_OUT_A         : out   std_logic_vector(7 downto 0);
    PSG_OUT_B         : out   std_logic_vector(7 downto 0);
    PSG_OUT_C         : out   std_logic_vector(7 downto 0);
	 STEREO            : in    std_logic;
    VIDEO_R           : out   std_logic;
    VIDEO_G           : out   std_logic;
    VIDEO_B           : out   std_logic;
    VIDEO_HSYNC       : out   std_logic;
    VIDEO_VSYNC       : out   std_logic;
    VIDEO_VBLANK      : out   std_logic;
    VIDEO_HBLANK      : out   std_logic;
	 VIDEO_CLK         : out  std_logic;
	 ram_ad            : out std_logic_vector(15 downto 0);
	 ram_d             : out std_logic_vector( 7 downto 0);
	 ram_q             : in  std_logic_vector( 7 downto 0);
	 ram_cs            : out std_logic;
	 ram_oe            : out std_logic;
	 ram_we            : out std_logic;
	 phi2              : out std_logic;
	 fd_led            : out std_logic;
	 fdd_ready         : in std_logic_vector(1 downto 0);
	 fdd_busy          : out std_logic;
	 fdd_reset         : in std_logic;
	 fdd_layout        : in std_logic;
	 joystick_0        : in std_logic_vector( 7 downto 0);
	 joystick_1        : in std_logic_vector( 7 downto 0);
	 pll_locked        : in std_logic;
	 disk_enable       : in std_logic;
	 rom               : in std_logic;
	 img_mounted:     in std_logic_vector (1 downto 0);
	 img_wp:          in std_logic;
	 img_size:        in std_logic_vector (31 downto 0);
	 sd_lba:          out std_logic_vector (31 downto 0);
	 sd_rd:           out std_logic;
	 sd_wr:           out std_logic;
	 sd_ack:          in std_logic;
	 sd_buff_addr:    in std_logic_vector (8 downto 0);
	 sd_dout:         in std_logic_vector (7 downto 0);
	 sd_din:          out std_logic_vector (7 downto 0);
	 sd_dout_strobe:  in std_logic;
	 sd_din_strobe:   in std_logic
	 );
end;

architecture RTL of telestrat is
  
    -- Gestion des resets
	 signal RESETn        		: std_logic;
    signal reset_dll_h        : std_logic;
    signal delay_count        : std_logic_vector(7 downto 0) := (others => '0');
    signal clk_cnt            : std_logic_vector(2 downto 0) := "000";

    -- cpu
    signal cpu_ad             : std_logic_vector(23 downto 0);
    signal cpu_di             : std_logic_vector(7 downto 0);
    signal cpu_do             : std_logic_vector(7 downto 0);
    signal cpu_rw             : std_logic;
    signal via1_irq           : std_logic;
	 signal via2_irq           : std_logic;
      
	-- VIA 1
	SIGNAL via1_pa_out_oe : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL via1_pa_in : STD_LOGIC_VECTOR(7 DOWNTO 0)  ;
	SIGNAL via1_pa_out : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL via1_pa_in_from_psg : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL via1_ca2_out : STD_LOGIC;
	SIGNAL via1_cb1_out : STD_LOGIC;
	SIGNAL via1_cb1_oe_l : STD_LOGIC;
	SIGNAL via1_cb2_out : STD_LOGIC;
	SIGNAL via1_cb2_oe_l : STD_LOGIC;
	SIGNAL via1_pb_in : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL via1_pb_out : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL via1_pb_oe_l : STD_LOGIC_VECTOR(7 DOWNTO 0); 
	SIGNAL VIA1_DO : STD_LOGIC_VECTOR(7 DOWNTO 0);

	-- VIA 2
		
	SIGNAL via2_pa_out_oe : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL via2_pa_in : STD_LOGIC_VECTOR(7 DOWNTO 0) ;
	SIGNAL via2_pa_out : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL via2_pa_in_from_psg : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL via2_cb1_out : STD_LOGIC;
	SIGNAL via2_cb1_in  : STD_LOGIC;
	SIGNAL via2_cb1_oe_l : STD_LOGIC;
	SIGNAL via2_cb2_out : STD_LOGIC;
	SIGNAL via2_cb2_oe_l : STD_LOGIC;
	SIGNAL via2_pb_in : STD_LOGIC_VECTOR(7 DOWNTO 0) ;
	SIGNAL via2_pb_out: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL via2_pb_out_oe : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL VIA2_DO : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL VIA2_DO_OE : STD_LOGIC;
	-- WDC
	SIGNAL WD_CLK : STD_LOGIC;
	SIGNAL WD_CSn : STD_LOGIC;
	SIGNAL WD_REn : STD_LOGIC;
	SIGNAL WD_WEn : STD_LOGIC;
	SIGNAL WD_IRQ : STD_LOGIC;
	SIGNAL WD_DRQ : STD_LOGIC;
	
	-- FDC
	SIGNAL FDC_DAL_0_IN : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL FDC_DAL_1_IN : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL FDC_DAL_2_IN : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL FDC_DAL_3_IN : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL FDC_DAL_0_OUT : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL FDC_DAL_1_OUT : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL FDC_DAL_2_OUT : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL FDC_DAL_3_OUT : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL DS0    : STD_LOGIC;
	SIGNAL DS1    : STD_LOGIC;
	SIGNAL DS2    : STD_LOGIC;
	SIGNAL DS3    : STD_LOGIC;
	SIGNAL SS     : STD_LOGIC; 
	-- CS 
	SIGNAL CS300n : STD_LOGIC;
	SIGNAL CS310n : STD_LOGIC;
	SIGNAL CS320n : STD_LOGIC;
	SIGNAL CS0n   : STD_LOGIC;
	SIGNAL CS1n   : STD_LOGIC;
	SIGNAL CS2n   : STD_LOGIC;
	SIGNAL CS3n   : STD_LOGIC;
	SIGNAL CS4n   : STD_LOGIC;
	SIGNAL CS5n   : STD_LOGIC;
	SIGNAL CS6n   : STD_LOGIC;
	SIGNAL CS1793n: STD_LOGIC;
	-- ACIA
	signal ACIA_DO: STD_LOGIC_VECTOR(7 downto 0);
	signal acia_irq: STD_LOGIC;
	signal XTLI    : STD_LOGIC;
	signal RXD    : STD_LOGIC;
	signal TXD    : STD_LOGIC;
	signal CTS    : STD_LOGIC;
  	signal RTS    : STD_LOGIC;
	signal DTR    : STD_LOGIC;
	
   -- Controller
	 signal cont_D_OUT         : std_logic_vector(7 downto 0);
	 signal cont_ECE           : std_logic;
    signal cont_nOE           : std_logic;
	 signal cont_irq           : std_logic;
	 signal cont_MAPn          : std_logic;
	 signal IOCONTn            : std_logic;
    -- Keyboard PS2
    signal KEY_HIT            : std_logic;
    signal KEYB_RESETn        : std_logic;
    signal KEYB_NMIn          : std_logic;
	 SIGNAL KEY_ROW : STD_LOGIC_VECTOR(7 DOWNTO 0);

    -- PSG
    signal ym_ioa_out         : std_logic_vector (7 downto 0);
    signal psg_do             : std_logic_vector (7 downto 0);
    signal psg_bidir          : std_logic;
	 signal ym_o_ioa           : std_logic_vector (7 downto 0);
    -- ULA 1
    signal ula_phi2           : std_logic;
    signal ula_CSIOn          : std_logic;
    signal ula_CSROMn         : std_logic;
	 signal ula_CSRAMn         : std_logic;
    signal ula_AD_SRAM        : std_logic_vector(15 downto 0);
    signal ula_CE_SRAM        : std_logic;
    signal ula_OE_SRAM        : std_logic;
    signal ula_WE_SRAM        : std_logic;
	 signal ula_LATCH_SRAM     : std_logic;
	 signal ula_MAPn           : std_logic;
    signal ula_CLK_4          : std_logic;
    signal ula_CLK_4_en       : std_logic;
    signal ula_MUX            : std_logic;
    signal ula_RW_RAM         : std_logic;
	 signal ula_VIDEO_R        : std_logic;
	 signal ula_VIDEO_G        : std_logic;
	 signal ula_VIDEO_B        : std_logic;
	 

--	 signal lSRAM_D            : std_logic_vector(7 downto 0);
	 signal ENA_1MHZ           : std_logic;
	 --- ROM
    signal ROM_TELMON_DO   	: std_logic_vector(7 downto 0);
	 signal ROM_HYPERBAS_DO    : std_logic_vector(7 downto 0);
	 signal ROM_TELEASS_DO     : std_logic_vector(7 downto 0);
	 signal ROM_TELMATIC_DO    : std_logic_vector(7 downto 0);
	 signal ROM_STRATORIC_DO   : std_logic_vector(7 downto 0);
	 --
	 signal ROM_ATMOS_DO       : std_logic_vector(7 downto 0);
	 signal ROM_ORIC1_DO       : std_logic_vector(7 downto 0);
	 
	 -- RAM
	 signal RAM_BANK0_DO       :std_logic_vector(7 downto 0);
	 signal RAM_BANK1_DO       :std_logic_vector(7 downto 0);
	 signal RAM_BANK2_DO       :std_logic_vector(7 downto 0);
	 signal RAM_BANK3_DO       :std_logic_vector(7 downto 0);
	 signal RAM_BANK4_DO       :std_logic_vector(7 downto 0);
	 --- Printer port
	 signal PRN_STROBE			: std_logic;
	 signal PRN_DATA           : std_logic_vector(7 downto 0);


	 signal SRAM_DO            : std_logic_vector(7 downto 0);
	 
	 signal swnmi           	: std_logic;
	 signal swrst              : std_logic;
	 
	 signal joya               : std_logic_vector(4 downto 0);
	 signal joyb               : std_logic_vector(4 downto 0);
	 signal joy_mux            : std_logic_vector(4 downto 0);
	 
	 
		 
COMPONENT keyboard
	PORT
	(
		clk_sys      : IN STD_LOGIC;
		key_pressed  : IN STD_LOGIC;
		key_extended : IN STD_LOGIC;
		key_strobe   : IN STD_LOGIC;
		key_code     : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		row          : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
		col          : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		key_hit      : OUT STD_LOGIC;
		swnmi        : OUT STD_LOGIC;
		swrst        : OUT STD_LOGIC
	);
END COMPONENT;

COMPONENT wd1793
	GENERIC 
	(
		RWMODE          : INTEGER := 1;
		EDSK            : INTEGER := 0
	);
	PORT 
	(
		clk_sys       : IN std_logic;
		ce            : IN std_logic;

		reset         : IN std_logic;
		io_en         : IN std_logic;
		rd            : IN std_logic;
		wr            : IN std_logic;
		addr          : IN std_logic_vector (1 DOWNTO 0);
		din           : IN std_logic_vector (7 DOWNTO 0);
		dout          : OUT std_logic_vector (7 DOWNTO 0);

		intrq         : OUT std_logic;
		drq           : OUT std_logic;

		busy          : OUT std_logic;
		ready         : IN std_logic;
		layout        : IN std_logic;
		side          : IN std_logic;

		img_mounted   : IN std_logic;

		wp            : IN std_logic;
		img_size      : IN std_logic_vector (19 DOWNTO 0);
		sd_lba        : OUT std_logic_vector (31 DOWNTO 0);
		sd_rd         : OUT std_logic;
		sd_wr         : OUT std_logic;
		sd_ack        : IN std_logic;
		sd_buff_addr  : IN std_logic_vector (8 DOWNTO 0);
		sd_buff_dout  : IN std_logic_vector (7 DOWNTO 0);
		sd_buff_din   : OUT std_logic_vector (7 DOWNTO 0);
		sd_buff_wr    : IN std_logic;

		prepare       : OUT std_logic;
		size_code     : IN std_logic_vector (2 DOWNTO 0); 
		
		input_active  : IN std_logic;
		input_addr    : IN std_logic_vector (19 DOWNTO 0);
		input_data    : IN std_logic_vector (7 DOWNTO 0);
		input_wr      : IN std_logic;
		buff_addr     : OUT std_logic_vector (19 DOWNTO 0);	  
		buff_read     : OUT std_logic;	  
		buff_din      : IN std_logic_vector (7 DOWNTO 0)

	);
END COMPONENT;

COMPONENT jt49_bus
			 PORT (
						clk : IN STD_LOGIC;
						clk_en : IN STD_LOGIC;
						rst_n : IN STD_LOGIC;
						bdir : IN STD_LOGIC;
						bc1 : IN STD_LOGIC;
						sel : IN STD_LOGIC;
						din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
						dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
						sound : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
						A : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
						B : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
						C : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
						sample : OUT STD_LOGIC;
						IOA_In : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
						IOA_Out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
						IOB_In : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
						IOB_Out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
			 );
END COMPONENT;

begin

--RESETn <= (not RESET and KEYB_RESETn);
inst_cpu : entity work.T65
	port map (
		Mode    		=> "00",
      Res_n   		=> RESETn,
      Enable  		=> ENA_1MHZ,
      Clk     		=> CLK_IN,
      Rdy     		=> '1',
      Abort_n 		=> '1',
      IRQ_n   		=> via1_irq and via2_irq  and acia_irq and cont_irq, 
      NMI_n   		=> '1',
      SO_n    		=> '1',
      R_W_n   		=> cpu_rw,
      A       		=> cpu_ad,
      DI      		=> cpu_di,
      DO      		=> cpu_do
);


ram_ad  <= ula_AD_SRAM when (ula_PHI2 = '0')else cpu_ad(15 downto 0);


ram_d   <= cpu_do;
SRAM_DO <= ram_q;
ram_cs  <= '0' when RESETn = '0' else ula_CE_SRAM;
ram_oe  <= '0' when RESETn = '0' else ula_OE_SRAM;
ram_we  <= '0' when RESETn = '0' else ula_WE_SRAM;
phi2    <= ula_PHI2;


inst_atmos : entity work.BASIC11A  -- Oric Atmos ROM
	port map (
		clk  			=> CLK_IN,
		addr 			=> cpu_ad(13 downto 0),
		data 			=> ROM_ATMOS_DO
);
inst_oric1 : entity work.BASIC10  -- Oric 1 ROM
	port map (
		clk  			=> CLK_IN,
		addr 			=> cpu_ad(13 downto 0),
		data 			=> ROM_ORIC1_DO
);
inst_stratoric : entity work.stratoric  -- Telmon24
	port map (
		clock			=> CLK_IN,
		address		=> cpu_ad(13 downto 0),
		q 			   => ROM_STRATORIC_DO
);

inst_telmon : entity work.telmon24  -- Telmon24
	port map (
		clock			=> CLK_IN,
		address		=> cpu_ad(13 downto 0),
		q 			   => ROM_TELMON_DO
);
inst_hyperbas : entity work.hyperbas  -- Hyperbasic
	port map (
		clock			=> CLK_IN,
		address		=> cpu_ad(13 downto 0),
		q 			   => ROM_HYPERBAS_DO
);
inst_teleass : entity work.teleass 
	port map (
		clock			=> CLK_IN,
		address		=> cpu_ad(13 downto 0),
		q 			   => ROM_TELEASS_DO
);
inst_telmatic : entity work.telmatic
	port map (
		clock			=> CLK_IN,
		address		=> cpu_ad(13 downto 0),
		q 			   => ROM_TELMATIC_DO
);


inst_ram1 : entity work.ram16k
	port map (
		clock			=> CLK_IN,
		address		=> cpu_ad(13 downto 0),
		data        => cpu_do,
		wren        => not CS0n and not cpu_rw, 
		q 			   => RAM_BANK1_DO
);
inst_ram2 : entity work.ram16k
	port map (
		clock			=> CLK_IN,
		address		=> cpu_ad(13 downto 0),
		data        => cpu_do,
		wren        => not CS1n and not cpu_rw, 
		q 			   => RAM_BANK2_DO
);
inst_ram3 : entity work.ram16k
	port map (
		clock			=> CLK_IN,
		address		=> cpu_ad(13 downto 0),
		data        => cpu_do,
		wren        => not CS2n and not cpu_rw, 
		q 			   => RAM_BANK3_DO
);
inst_ram4 : entity work.ram16k
	port map (
		clock			=> CLK_IN,
		address		=> cpu_ad(13 downto 0),
		data        => cpu_do,
		wren        => not CS3n and not cpu_rw, 
		q 			   => RAM_BANK4_DO
);



inst_via1 : entity work.M6522
	port map (
		I_RS        => cpu_ad(3 downto 0),
		I_DATA      => cpu_do(7 downto 0),
		O_DATA      => VIA1_DO,
		I_RW_L      => cpu_rw,
		I_CS1       => '1',
		I_CS2_L     => CS300n,
		
		O_IRQ_L     => via1_irq, 

      --PORT A		
		I_CA1       => '1',       -- PRT_ACK
		I_CA2       => '1',       -- psg_bdir
		O_CA2       => via1_ca2_out,
		O_CA2_OE_L  => open,
		
		I_PA        => via1_pa_in,
		O_PA        => via1_pa_out,
		O_PA_OE_L   => via1_pa_out_oe,
		
		-- PORT B
		I_CB1       => K7_TAPEIN,
		O_CB1       => via1_cb1_out,
      O_CB1_OE_L  => via1_cb1_oe_l,
		
		I_CB2       => '1',
		O_CB2       => via1_cb2_out,
		O_CB2_OE_L  => open,
		
		I_PB        => via1_pb_in,
		O_PB        => via1_pb_out,

		RESET_L     => RESETn, 
		I_P2_H      => ula_phi2,
		ENA_4       => ula_CLK_4_en,
		CLK         => CLK_IN
);

inst_via2 : entity work.M6522_1
	port map (
		I_RS        => cpu_ad(3 downto 0),
		I_DATA      => cpu_do(7 downto 0),
		O_DATA      => VIA2_DO,
		O_DATA_OE_L => VIA2_DO_OE,
		I_RW_L      => cpu_rw,
		I_CS1       => '1',
		I_CS2_L     => CS320n,
		
		O_IRQ_L     => via2_irq, 

      --PORT A		
		I_CA1       => '1',       
		I_CA2       => '1',       
		O_CA2       => open,
		O_CA2_OE_L  => open,
		
		I_PA        => via2_pa_in,
		O_PA        => via2_pa_out,
		O_PA_OE_L   => via2_pa_out_oe,
		
		-- PORT B
		I_CB1       => '1',
		O_CB1       => open,
      O_CB1_OE_L  => open,
		
		I_CB2       => '1',
		O_CB2       => open,
		O_CB2_OE_L  => open,
		
		I_PB        => via2_pb_in,
		O_PB        => via2_pb_out,
		O_PB_OE_L   => via2_pb_out_oe,
		RESET_L     => RESETn, 
		I_P2_H      => ula_phi2,
		ENA_4       => ula_CLK_4_en,
		CLK         => CLK_IN
);


-- PSG
inst_psg : jt49_bus
  PORT MAP(
		 clk => CLK_IN,
		 clk_en => ENA_1MHZ,
		 sel => '1',
		 rst_n => '1', --RESETn,
		 bc1 =>  via1_ca2_out,
		 bdir => via1_cb2_out,
		 din =>  via1_pa_out,
		 dout => psg_do,
		 sample => open,
		 sound => PSG_OUT,
		 A => PSG_OUT_A,
		 B => PSG_OUT_B,
		 C => PSG_OUT_C,
		 IOA_In => (OTHERS => '0'),
		 IOA_Out => ym_o_ioa,
		 IOB_In => (OTHERS => '0')
 );


inst_key : keyboard
	port map(
		clk_sys      => CLK_IN,
		key_pressed  => key_pressed,
		key_extended => key_extended,
		key_strobe   => key_strobe,
		key_code     => key_code,
		row          => via1_pb_out (2 downto 0),
		col          => ym_o_ioa,
		key_hit      => KEY_HIT,
		swnmi        => swnmi,
		swrst        => swrst
);

KEYB_NMIn <= NOT swnmi;
KEYB_RESETn <= NOT swrst;

HCS3119: work.HCS3119 
    port map( 
          CLK_SYS   => CLK_IN,
                                                            -- Oric Expansion Port Signa
			 A         => cpu_ad (15 downto 0),                -- 6502 Address Bus
          RnW       => cpu_rw,                              -- 6502 Read-/Write
			 IO        => ula_CSIOn,
          PH2       => ula_PHI2,                            -- 6502 PH2 
          MAPn      => ula_MAPn,                            -- Oric MAP
          PA        => via2_pa_out (2 downto 0),            -- VIA1 PA Lines

          CS300n    => CS300n,
          CS310n    => CS310n,
          CS320n    => CS320n,
			 CS1793n   => CS1793n,
          CS0n      => CS0n,
          CS1n      => CS1n,
          CS2n      => CS2n,
          CS3n      => CS3n,
          CS4n      => CS4n,
          CS5n      => CS5n,
          CS6n      => CS6n,
 
          WD_CLK    => WD_CLK,
			 WD_CSn    => WD_CSn,
			 WD_REn    => WD_REn,
			 WD_WEn    => WD_WEn,
			 WD_DRQ    => WD_DRQ,
			 WD_IRQ    => WD_IRQ,
			 nRESET    => not RESET AND KEYB_RESETn,
			 nHOSTRST  => RESETn                                -- RESET from MCU
         );

HCS3120: work.HCS3120 
    port map( 
          CLK_SYS   => CLK_DISK,
                                                         -- Oric Expansion Port Signals
          DI        => cpu_do,                              -- 6502 Data Bus
          DO        => CONT_D_OUT,                              -- 6502 Data Bus
          A         => cpu_ad (15 downto 0),                -- 6502 Address Bus
          RnW       => cpu_rw,                              -- 6502 Read-/Write
          nIRQ      => cont_irq,                            -- 6502 /IRQ
          PH2       => ula_PHI2,                            -- 6502 PH2 
          IO        => CS1793n,                             -- Oric I/O 
          IOCTRL    => IOCONTn,                             -- Oric I/O Control           
                                                            -- Additional MCU Interface Lines
          nRESET    => RESETn,                              -- RESET from MCU
          
          SS          =>  SS,
			 DS0         =>  DS0,
			 DS1         =>  DS1,
			 DS2         =>  DS2,
			 DS3         =>  DS3,
			 DAL_OUT     =>  FDC_DAL_0_OUT,  
			 WD_IRQ      =>  WD_IRQ,
			 WD_DRQ      =>  WD_IRQ,
			 WD_REn      =>  WD_REn
         );
			
			
HCS10017 : entity work.HCS10017
   port map (
      CLK        	=> CLK_IN,
      PHI2       	=> ula_phi2,
		PHI2_EN     => ENA_1MHZ,
      CLK_4      	=> ula_CLK_4,
		CLK_4_EN    => ula_CLK_4_en,
      RW         	=> cpu_rw,
      RESETn     	=> not RESET,
		MAPn      	=> ula_MAPn,
      DB         	=> SRAM_DO,
      ADDR       	=> cpu_ad(15 downto 0),
      SRAM_AD    	=> ula_AD_SRAM,
		SRAM_OE    	=> ula_OE_SRAM,
		SRAM_CE    	=> ula_CE_SRAM,
		SRAM_WE    	=> ula_WE_SRAM,
		LATCH_SRAM 	=> ula_LATCH_SRAM,
		CSIOn       => ula_CSIOn,
      CSROMn     	=> ula_CSROMn,
      CSRAMn     	=> ula_CSRAMn,
      R          	=> VIDEO_R,
      G          	=> VIDEO_G,
      B          	=> VIDEO_B,
		HBLANK      => VIDEO_HBLANK,
		VBLANK      => VIDEO_VBLANK,
		CLK_PIX     => VIDEO_CLK,
		HSYNC      	=> VIDEO_HSYNC,
		VSYNC      	=> VIDEO_VSYNC		
);

inst_ACIA : work.ACIA
   port map(
          RESET  => RESETn,
			 PHI2   => ula_phi2,
			 CS     => CS310n,
			 RWN    => cpu_rw,
			 RS     => cpu_ad(1 downto 0),
			 DATAIN => cpu_do,
			 DATAOUT=> ACIA_DO,
			 XTLI   => CLK_ACIA,
			 RTSB   => RTS,
			 CTSB   => CTS,
			 DTRB   => DTR, 
			 RXD    => RXD,
			 TXD    => TXD,
			 IRQn   => acia_irq

);
RXD <= TXD; -- LOOPBACK.
CTS <= RTS; -- LOOPBACK


fdc0 : wd1793
	GENERIC MAP
	(
	EDSK => 1, 
	RWMODE => 1
	)
	PORT MAP
	(
		clk_sys       => CLK_DISK, 
		ce            => WD_CLK, 

		reset         => NOT RESETn, 
		io_en         => not WD_CSn, 
		rd            => not WD_REn,
		wr            => NOT WD_WEn,
		addr          => cpu_ad (1 DOWNTO 0), 
		din           => CPU_DO, 
		dout          => FDC_DAL_0_OUT, 

		intrq         => WD_IRQ, 
		drq           => WD_DRQ, 

		ready         => '1', --fdd_ready(0), 
		busy          => fd_led, 

		layout        => '0' , --fdd_layout, 
		size_code     => "001", 
		side          => SS,
		prepare       => fdd_busy,
		img_mounted   => img_mounted(0), 
		wp            => img_wp, 
		img_size      => img_size (19 downto 0), 
		sd_lba        => sd_lba, 
		sd_rd         => sd_rd, 
		sd_wr         => sd_wr, 
		sd_ack        => sd_ack, 
		sd_buff_addr  => sd_buff_addr, 
		sd_buff_dout  => sd_dout, 
		sd_buff_din   => sd_din,
		sd_buff_wr    => sd_dout_strobe,
	
		input_active  => '0',
		input_addr    => (others => '0'),	
		input_data    => (others => '0'),
		input_wr      => '0',
		buff_din      => (others => '0')
		
		); 
 

via1_pa_in <= (via1_pa_out and not via1_pa_out_oe) or (psg_do and via1_pa_out_oe);
via1_pb_in(2 downto 0) <= via1_pb_out(2 downto 0);
via1_pb_in(3) <= KEY_HIT;
via1_pb_in(4) <=via1_pb_out(4);
via1_pb_in(5) <= 'Z';
via1_pb_in(6) <=via1_pb_out(6);
via1_pb_in(7) <=via1_pb_out(7);

K7_TAPEOUT  <= via1_pb_out(7);
K7_REMOTE   <= via1_pb_out(6);
PRN_STROBE  <= via1_pb_out(4);
PRN_DATA    <= via1_pa_out;


joya <= joystick_0(4 downto 0);
joyb <= joystick_1(4 downto 0);

joy_mux <= not joya when via2_pb_out(7) = '1' else
           not joyb when via2_pb_out(6) = '1' else
			  "11111";
			  
via2_pb_in  <=  via2_pb_out(7) & via2_pb_out(6) & via2_pb_out(5) & joy_mux;
via2_pa_in  <= '1' & '1' & '1' & via2_pa_out(4) & '1' & via2_pa_out(2 downto 0);

process begin
	wait until rising_edge(clk_in);
	  	-- EXPANSION
      if    cpu_rw = '1' and ula_PHI2 = '1' and CS1793n = '0'  then
        CPU_DI <= cont_D_OUT;
		
      -- VIA1
		elsif cpu_rw = '1' and ula_phi2 = '1' and CS300n = '0' and IOCONTn='1' then
			cpu_di <= VIA1_DO ;
      -- VIA2
		elsif cpu_rw = '1' and ula_phi2 = '1' and CS320n = '0' and IOCONTn='1'then
			cpu_di <= VIA2_DO ;
      -- ACIA
		elsif cpu_rw = '1' and ula_phi2 = '1' and CS310n = '0' and IOCONTn='1' then
			cpu_di <= ACIA_DO;
	
	   elsif cpu_rw = '1' and ula_phi2 = '1' and CS6n = '0' and rom = '0' then
			cpu_di <= ROM_TELMON_DO;
	   elsif cpu_rw = '1' and ula_phi2 = '1' and CS6n = '0' and rom = '1' then
			cpu_di <= ROM_STRATORIC_DO;
		elsif cpu_rw = '1' and ula_phi2 = '1' and CS5n = '0' and rom = '0' then
			cpu_di <= ROM_HYPERBAS_DO;
		elsif cpu_rw = '1' and ula_phi2 = '1' and CS5n = '0' and rom = '1' then
			cpu_di <= ROM_ATMOS_DO;
		elsif cpu_rw = '1' and ula_phi2 = '1' and CS4n = '0' and rom = '0' then
			cpu_di <= ROM_TELEASS_DO;
		elsif cpu_rw = '1' and ula_phi2 = '1' and CS4n = '0' and rom = '1' then
			cpu_di <= ROM_ORIC1_DO;
		elsif cpu_rw = '1' and ula_phi2 = '1' and CS3n = '0'  then 
			cpu_di <= RAM_BANK4_DO;
		elsif cpu_rw = '1' and ula_phi2 = '1' and CS2n = '0'  then
			cpu_di <= RAM_BANK3_DO;
		elsif cpu_rw = '1' and ula_phi2 = '1' and CS1n = '0'  then
			cpu_di <= RAM_BANK2_DO;
		elsif cpu_rw = '1' and ula_phi2 = '1' and CS0n = '0'  then
			cpu_di <= RAM_BANK1_DO;
		-- RAM

		elsif cpu_rw = '1' and ula_phi2 = '1' and ula_CSRAMn = '0' and ula_LATCH_SRAM = '0' then
			cpu_di <= SRAM_DO; 	
		end if;
end process;

end RTL;
