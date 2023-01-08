# [Oric Telestrat](https://fr.wikipedia.org/wiki/Oric_Telestrat) for MiSTer FPGA


Oric Telestrat re-implementation on a modern FPGA.

### Background:

  This project started on 2020, based on the initial Oric core (from SEILEBOST) and have gained components and testing over this years. I hope youll 
 enjoy this as i have enjoyed recreating it.

### What is implemented ?

* **ULA HCS10017**.
* **ULA HCS3119**.
* **ULA HCS3120**.
* **VIA 6522** X2.
* **CPU 6502**.
* 128KB of **RAM**.
* up to 64 K of rom (Via cartridges)
* Sound (**AY-3-8912**).
* Tape loading working (via audio cable on **ADC**  and OSD TAP file loading).
* **WD1793** disk controller with two floppy drives.
* Disc Read / Write operations fully supported with EDSK (The same as Amstrad CPC) format and IMG raw disks.
* ACIA **6551** (implemented but not conected)
* MIDI socket (implemented but not connected)


### TODO
 * Find information on **MIDI** and **MINITEL** hardware.




### HOW TO INSTALL

* **Create a directory called TeleStrat under /media/fat/games put inside:**
     * ROM cartridges
     * Disk images (not the MFM from the emulator, but raw images or edsk images)
     * TAP files.
     
   * Once the core is launched:

   Keyboard Shorcuts:
   * F11 - Reset.
   * F12 - OSD Main Menu.

   * Select an Image from (try STRATSED.img) for booting.



## Thanks to:

   * Ron Rodritty:  [retrowiki.es](https://www.retrowiki.es)
   * Chema Enguita.
   * SiliceBit.
   * The RW FPGA DEV Team.
   * [Defence force forum](https://forum.defence-force.org)

## About disk images

  Despite the .dsk extension, Disk images must use the defacto standard **edsk** for disk preservation (also known as "AMSTRAD CPC EXTENDED FORMAT") or RAW disk images (if the disk is 17 sectors per track).
  To convert images:
  * From the Oric "dsk" to the needed "edsk" or "img" you need the [HxCFloppyEmulator](https://hxc2001.com/download/floppy_drive_emulator/HxCFloppyEmulator_soft.zip) tool.
  * For .img, you can also use MFM2RAW from euphoric emulator
 

  Load the Oric disk and export it as **CPC DSK file** or **IMG File (Raw sector file format) The resulting image should load flawlessly on the Oric. Always use a `.dsk` or `.img` extension for your output file
  These images are also compatible with fastfloppy firmware on gothek, cuamana reborn, etc. working with real Orics.

## ROM cartridges

 ROM cartridges are a concatenation  of BANK7+BANK6+BANK5+BANK4 ROMS. 

Cartridge      |   Description
---------------|---------------------------------
ATMOS.ROM      | Oric ATMOS cartridge... use this to get maximum atmos compatibility (no disks)
TELETEST-V2-1  | Telestrat service tests
TELEASS        | Telestrat mode. TELMON,HYPERBASIC and TELEASS
TELEFORTH      | Telestrat mode. TELMON ant TELEFORTH
TELEMATIC      | Minitel server
STRATORIC-X.X  | Mode ATMOS with disk modes. (STRATORIC+ATMOS ROM+ORIC1 ROM

