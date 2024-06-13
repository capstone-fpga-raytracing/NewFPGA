# FPGA Core

We designed this for a DE1-SoC, but it probably works on a DE10 as well. Any CycloneV FPGA should also work after some changes to the Qsys design.

## Instructions
1. Connect your PC to the DE1-SoC via Ethernet cable.
2. Grab Intel's custom DE1-SoC Linux distribution from [here](https://ftp.intel.com/Public/Pub/fpgaup/pub/Teaching_Materials/current/SD_Images/DE1-SoC.zip), and follow [this tutorial](https://ftp.intel.com/Public/Pub/fpgaup/pub/Intel_Material/17.0/Tutorials/Linux_On_DE_Series_Boards.pdf) to set it up and open a remote shell to the DE1-SoC on your PC.
3. Install Intel Quartus 18.1 (later versions do not work under Quartus Lite, since the SDRAM controller we use was removed)
4. Open 'Computer System.qsys' in Quartus's Platform Designer and click 'Generate HDL'.
5. Add the newly generated ComputerSystem.qip to the Quartus project.
6. Hit compile (takes 7-8 mins). A .sof is generated containing the assembled FPGA core.
7. Convert the .sof to .rbf using File > Convert Programming Files. Make sure 'Compression' is ticked under Properties (otherwise the program script will fail)
8. Transfer the fpga_program.sh script and the NewHPS repo to the DE1-SoC, using the scp command (remove the hidden .git folder in NewHPS first, scp on Windows silently fails otherwise)
9. Setup the NewHPS repo by following its README instructions.
