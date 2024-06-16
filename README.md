# FPGA Core

## Instructions
1. Connect your PC to the DE1-SoC via Ethernet cable.
2. Grab Intel's custom DE1-SoC Linux distribution from [here](https://ftp.intel.com/Public/Pub/fpgaup/pub/Teaching_Materials/current/SD_Images/DE1-SoC.zip), and follow [this tutorial](https://ftp.intel.com/Public/Pub/fpgaup/pub/Intel_Material/17.0/Tutorials/Linux_On_DE_Series_Boards.pdf) to set it up and open a remote shell to the DE1 on your PC.
3. Install Intel Quartus 18.1 and open the `raytracer.qpf` project in Quartus.
   - (versions after 18.1 do not work under Quartus Lite, since the SDRAM controller we use was removed)
5. Open 'Computer System.qsys' in Quartus's Platform Designer and click 'Generate HDL'.
6. Add the newly generated ComputerSystem.qip to the Quartus project.
7. Hit compile (takes 7-8 mins). A .sof is generated containing the assembled FPGA core.
8. Convert the .sof to .rbf using File > Convert Programming Files. Make sure 'Compression' is ticked under Properties! You may encounter [cryptic timeouts](https://community.intel.com/t5/Intel-High-Level-Design/altera-fpga-manager-ff706000-fpgamgr-timeout/m-p/1146465) later on if you don't.
9. Transfer the fpga_program.sh script, the compiled .rbf and the NewHPS repo to the DE1-SoC using `scp`, eg. `scp -r srcFolder root@de1soclinux:~/targetFolder`
    - (remove the hidden .git folder in NewHPS first. scp on Windows seems to silently fail otherwise)
11. Setup the NewHPS repo on the DE1 by following its README instructions. 
