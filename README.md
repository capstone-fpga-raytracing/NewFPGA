# FPGA Core

We designed this for a DE1-SoC FPGA, but it probably works on a DE10 as well. Any CycloneV FPGA should also work after minor changes to the Qsys design.

## Instructions
- Grab Intel's custom DE1-SoC Linux distribution from [here](https://ftp.intel.com/Public/Pub/fpgaup/pub/Teaching_Materials/current/SD_Images/DE1-SoC.zip), flash it onto an SD card and boot from it on the FPGA.  
[This tutorial](https://ftp.intel.com/Public/Pub/fpgaup/pub/Intel_Material/17.0/Tutorials/Linux_On_DE_Series_Boards.pdf) is very helpful.
- Install Intel Quartus 18.1 (later versions do not work under Quartus Lite, since the SDRAM controller we use was removed)
- Open 'Computer System.qsys' in Quartus's Platform Designer and click 'Generate HDL'.
- Add the newly generated ComputerSystem.qip to the Quartus project.
- Hit compile (takes 7-8 mins). A .sof is generated containing the assembled FPGA core.
- Convert the .sof to .rbf using File > Convert Programming Files. Make sure 'Compression' is ticked under Properties (otherwise the program script fails, god knows why)
- Make sure you have the Linux terminal up and running on the FPGA from Step 1.
- Transfer the fpga_program.sh script and the NewHPS repo to FPGA Linux via ethernet. You can use the 'scp' command for this.
  - Remove the hidden .git folder in NewHPS before transferring using scp. scp seems to silently fail when .git/ is present.
- Setup the NewHPS repo by following its README instructions.
