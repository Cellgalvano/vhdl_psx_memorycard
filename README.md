# vhdl_psx_memorycard
VHDL replication of the PSX Memory Card

This project tries to implement a PS1 / PSX Memory Card with the help of an FPGA or CPLD.
In my current setup the code is running on a Digilent Basys 3 (Artix-7 35T) Board.
It seems to work with MemcardRex and MemCARDuino, read and write commands are implemented and tested. 
PSX Memory Cards are 128KB (1Mb) in size so the FPGA needs a minimum of 131072 bytes of BRAM.

Next step will be to create the circuit required to attach the PSX voltage levels (3.6V) to the FPGA (3.3V) with Tri-State Outputs.
In my first test with real hardware the bus arbitration was not working and the controller could not be used. 

Resources
- Nocash PSX Specifications http://problemkaputt.de/psx-spx.htm#controllersandmemorycards
- MemcardRex https://github.com/ShendoXT/memcardrex
- MemCARDuino https://github.com/ShendoXT/memcarduino
