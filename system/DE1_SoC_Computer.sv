

module DE1_SoC_Computer (
   ////////////////////////////////////
   // FPGA Pins
   ////////////////////////////////////

   // Clock pins
   CLOCK_50,
   CLOCK2_50,
   CLOCK3_50,
   CLOCK4_50,
   
   // SDRAM
   DRAM_ADDR,
   DRAM_BA,
   DRAM_CAS_N,
   DRAM_CKE,
   DRAM_CLK,
   DRAM_CS_N,
   DRAM_DQ,
   DRAM_LDQM,
   DRAM_RAS_N,
   DRAM_UDQM,
   DRAM_WE_N,

   // 40-Pin Headers
   GPIO_0,
   GPIO_1,
   
   // Seven Segment Displays
   HEX0,
   HEX1,
   HEX2,
   HEX3,
   HEX4,
   HEX5,

   // IR
   IRDA_RXD,
   IRDA_TXD,

   // LEDs
   LEDR,


   ////////////////////////////////////
   // HPS Pins
   ////////////////////////////////////
   
   // DDR3 SDRAM
   HPS_DDR3_ADDR,
   HPS_DDR3_BA,
   HPS_DDR3_CAS_N,
   HPS_DDR3_CKE,
   HPS_DDR3_CK_N,
   HPS_DDR3_CK_P,
   HPS_DDR3_CS_N,
   HPS_DDR3_DM,
   HPS_DDR3_DQ,
   HPS_DDR3_DQS_N,
   HPS_DDR3_DQS_P,
   HPS_DDR3_ODT,
   HPS_DDR3_RAS_N,
   HPS_DDR3_RESET_N,
   HPS_DDR3_RZQ,
   HPS_DDR3_WE_N,

   // Ethernet
   HPS_ENET_GTX_CLK,
   HPS_ENET_INT_N,
   HPS_ENET_MDC,
   HPS_ENET_MDIO,
   HPS_ENET_RX_CLK,
   HPS_ENET_RX_DATA,
   HPS_ENET_RX_DV,
   HPS_ENET_TX_DATA,
   HPS_ENET_TX_EN,

   // Flash
   HPS_FLASH_DATA,
   HPS_FLASH_DCLK,
   HPS_FLASH_NCSO,

   // Accelerometer
   HPS_GSENSOR_INT,
      
   // General Purpose I/O
   HPS_GPIO,
      
   // I2C
   HPS_I2C_CONTROL,
   HPS_I2C1_SCLK,
   HPS_I2C1_SDAT,
   HPS_I2C2_SCLK,
   HPS_I2C2_SDAT,

   // Pushbutton
   HPS_KEY,

   // LED
   HPS_LED,
      
   // SD Card
   HPS_SD_CLK,
   HPS_SD_CMD,
   HPS_SD_DATA,

   // SPI
   HPS_SPIM_CLK,
   HPS_SPIM_MISO,
   HPS_SPIM_MOSI,
   HPS_SPIM_SS,

   // UART
   HPS_UART_RX,
   HPS_UART_TX,

   // USB
   HPS_CONV_USB_N,
   HPS_USB_CLKOUT,
   HPS_USB_DATA,
   HPS_USB_DIR,
   HPS_USB_NXT,
   HPS_USB_STP
);

//=======================================================
//  PARAMETER declarations
//=======================================================


//=======================================================
//  PORT declarations
//=======================================================

////////////////////////////////////
// FPGA Pins
////////////////////////////////////

// Clock pins
input                CLOCK_50;
input                CLOCK2_50;
input                CLOCK3_50;
input                CLOCK4_50;


// SDRAM
output      [12: 0]  DRAM_ADDR;
output      [ 1: 0]  DRAM_BA;
output               DRAM_CAS_N;
output               DRAM_CKE;
output               DRAM_CLK;
output               DRAM_CS_N;
inout       [15: 0]  DRAM_DQ;
output               DRAM_LDQM;
output               DRAM_RAS_N;
output               DRAM_UDQM;
output               DRAM_WE_N;


// 40-pin headers
inout       [35: 0]  GPIO_0;
inout       [35: 0]  GPIO_1;

// Seven Segment Displays
output      [ 6: 0]  HEX0;
output      [ 6: 0]  HEX1;
output      [ 6: 0]  HEX2;
output      [ 6: 0]  HEX3;
output      [ 6: 0]  HEX4;
output      [ 6: 0]  HEX5;

// IR
input                IRDA_RXD;
output               IRDA_TXD;

// LEDs
output      [ 9: 0]  LEDR;


////////////////////////////////////
// HPS Pins
////////////////////////////////////
   
// DDR3 SDRAM
output      [14: 0]  HPS_DDR3_ADDR;
output      [ 2: 0]  HPS_DDR3_BA;
output               HPS_DDR3_CAS_N;
output               HPS_DDR3_CKE;
output               HPS_DDR3_CK_N;
output               HPS_DDR3_CK_P;
output               HPS_DDR3_CS_N;
output      [ 3: 0]  HPS_DDR3_DM;
inout       [31: 0]  HPS_DDR3_DQ;
inout       [ 3: 0]  HPS_DDR3_DQS_N;
inout       [ 3: 0]  HPS_DDR3_DQS_P;
output               HPS_DDR3_ODT;
output               HPS_DDR3_RAS_N;
output               HPS_DDR3_RESET_N;
input                HPS_DDR3_RZQ;
output               HPS_DDR3_WE_N;

// Ethernet
output               HPS_ENET_GTX_CLK;
inout                HPS_ENET_INT_N;
output               HPS_ENET_MDC;
inout                HPS_ENET_MDIO;
input                HPS_ENET_RX_CLK;
input       [ 3: 0]  HPS_ENET_RX_DATA;
input                HPS_ENET_RX_DV;
output      [ 3: 0]  HPS_ENET_TX_DATA;
output               HPS_ENET_TX_EN;

// Flash
inout       [ 3: 0]  HPS_FLASH_DATA;
output               HPS_FLASH_DCLK;
output               HPS_FLASH_NCSO;

// Accelerometer
inout                HPS_GSENSOR_INT;

// General Purpose I/O
inout       [ 1: 0]  HPS_GPIO;

// I2C
inout                HPS_I2C_CONTROL;
inout                HPS_I2C1_SCLK;
inout                HPS_I2C1_SDAT;
inout                HPS_I2C2_SCLK;
inout                HPS_I2C2_SDAT;

// Pushbutton
inout                HPS_KEY;

// LED
inout                HPS_LED;

// SD Card
output               HPS_SD_CLK;
inout                HPS_SD_CMD;
inout       [ 3: 0]  HPS_SD_DATA;

// SPI
output               HPS_SPIM_CLK;
input                HPS_SPIM_MISO;
output               HPS_SPIM_MOSI;
inout                HPS_SPIM_SS;

// UART
input                HPS_UART_RX;
output               HPS_UART_TX;

// USB
inout                HPS_CONV_USB_N;
input                HPS_USB_CLKOUT;
inout       [ 7: 0]  HPS_USB_DATA;
input                HPS_USB_DIR;
input                HPS_USB_NXT;
output               HPS_USB_STP;

//=======================================================
//  Intersector
//=======================================================

//wire         [31: 0]  hex3_hex0;
//wire         [15: 0]  hex5_hex4;
//
//assign HEX0 = ~hex3_hex0[ 6: 0];
//assign HEX1 = ~hex3_hex0[14: 8];
//assign HEX2 = ~hex3_hex0[22:16];
//assign HEX3 = ~hex3_hex0[30:24];
//assign HEX4 = ~hex5_hex4[ 6: 0];
//assign HEX5 = ~hex5_hex4[14: 8];


//logic sdr_clk;
//logic [479:0] sdr_readdata;
//logic [4:0] sdr_readoff;
//logic sdr_readend, sdr_readdatavalid;
//
//
//
//


//logic sdr_readstart;
//assign sdr_readstart = 1'b0;

//logic sdr_writestart;
//logic write_started;
//logic sdr_writeend;
//
//wire [63:0] sdr_writedata;
//assign sdr_writedata = 64'hBEEFD00DDEADBEEF;
//always_ff @(posedge sdr_clk)
//begin
// if(!write_started)
// begin
//    sdr_writestart <= 1'b1;
//    write_started <= 1'b1;
// end
// else
//    sdr_writestart <= 1'b0;
//end

//assign LEDR[9] = sdr_writeend;
//
//assign LEDR[7] = sdr_readend;
//=======================================================
//  Testing
//=======================================================

wire sdr_clk;
logic sdr_reset;

logic [2047:0] raydata;
assign raydata = sdr_readdata;

localparam READINIT = 3'd0,
           READSTART = 3'd1,
           READ_ASSERT = 3'd2,
           READ_DONE = 3'd3;

logic [2:0] cur_state, next_state;

always_ff @(posedge sdr_clk) begin
   if (sdr_reset) cur_state <= READINIT;
   else cur_state <= next_state;
end

reg rddone;
     
always @*
begin
   rddone <= 1'b0;
   sdr_readstart <= 1'b0;
   sdr_baseaddr <= 'hDEAD;
   sdr_nelems <= 'd0;

   case(cur_state)
      READINIT:
         next_state <= start_rt ? READSTART : READINIT;
         
      READSTART: begin
         sdr_readstart <= 1'b1;
         next_state <= READ_ASSERT;
      end
      
      READ_ASSERT: begin
         sdr_baseaddr <= 'b0;
         sdr_nelems <= 30'd15;
			rddone <= sdr_readend;
         next_state <= sdr_readend ? READ_DONE : READ_ASSERT;
      end
      
      READ_DONE: begin
         rddone <= 1'b1;
         next_state <= READ_DONE;
      end
   endcase

end


logic raytest, raytest_clk;
logic [9:0] raytest_addr;
logic [31:0] raytest_data;

assign raytest = rddone;

rate_divider rd ( CLOCK_50, raytest_clk);

always_ff @(posedge raytest_clk or posedge sdr_reset) 
begin
   if (sdr_reset) begin
      raytest_addr <= 10'd0;
      raytest_data <= 32'hDEAD;
   end else if (raytest_clk) begin
      if (raytest && raytest_addr != 10'd15) begin    
           raytest_data <= raydata[32*raytest_addr +: 32];
           raytest_addr <= raytest_addr + 10'd1;
      end
   end
end

assign LEDR[0] = rddone;


//logic [31:0] sdr_finaladdr;
//logic [15:0] sdr_writtendata;

        
hex_decoder h0(.hex_digit(raytest_data[3:0]),.segments(HEX0));
hex_decoder h1(.hex_digit(raytest_data[7:4]),.segments(HEX1));
hex_decoder h2(.hex_digit(raytest_data[11:8]),.segments(HEX2));
hex_decoder h3(.hex_digit(raytest_data[15:12]),.segments(HEX3));
hex_decoder h4(.hex_digit(raytest_data[19:16]),.segments(HEX4));
hex_decoder h5(.hex_digit(raytest_data[23:20]),.segments(HEX5));

//assign LEDR[8:0] = raytest_addr[8:0];

//wire [255:0] fpga_leds_internal;
//wire [255:0] fpga_hex_internal;
//wire [9:0] leds_export;
//wire out_do_read_export;
//wire [31:0] q;

//assign LEDR[7:1] = fpga_leds_internal[6:0] | leds_export[6:0];
//assign LEDR[9] = out_do_read_export;

logic          start_rt;
logic [31:0]   sdr_baseaddr;
logic [29:0]   sdr_nelems;
logic [2047:0] sdr_readdata;
logic          sdr_readend;
logic          sdr_readstart;
logic [2047:0] sdr_writedata;
logic          sdr_writeend;
logic          sdr_writestart;

logic [3:0]    hex0_bcd;
logic          hex0_valid;
wire [6:0]     hex0_wire;
reg [6:0]      hex0_reg;

hex_decoder h0dec(.hex_digit(hex0_bcd),.segments(hex0_wire));
always @(posedge CLOCK_50)
begin
   if (hex0_valid)
      hex0_reg <= hex0_wire;
end
//assign HEX0 = hex0_reg;




//top_v rt(
//   .clk100(CLOCK_50),
//   .start(start_rt),
//   .sdr_readend(sdr_readend),
//   .sdr_writeend(sdr_writeend),
//   .sdr_readdata(sdr_readdata),
//   .sdr_readstart(sdr_readstart),
//   .sdr_writestart(sdr_writestart),
//   .sdr_baseaddr(sdr_baseaddr),
//   .sdr_nelems(sdr_nelems),
//   .sdr_writedata(sdr_writedata),
//   .hex(hex0_bcd),
//   .hex_valid(hex0_valid)
//);



Computer_System The_System (
   ////////////////////////////////////
   // FPGA Side
   ////////////////////////////////////

   // Global signals
   .system_pll_ref_clk_clk             (CLOCK_50),
   .system_pll_ref_reset_reset         (1'b0),
   .video_pll_ref_clk_clk        (CLOCK2_50),
   .video_pll_ref_reset_reset    (1'b0),

   // Expansion JP1
   .expansion_jp1_export               ({GPIO_0[35:19], GPIO_0[17], GPIO_0[15:3], GPIO_0[1]}),

   // Expansion JP2
   .expansion_jp2_export               ({GPIO_1[35:19], GPIO_1[17], GPIO_1[15:3], GPIO_1[1]}),

   // LEDs
   .leds_export                        (leds_export),

   // SDRAM
   .sdram_clk_clk                      (DRAM_CLK),
   .sdram_addr                         (DRAM_ADDR),
   .sdram_ba                           (DRAM_BA),
   .sdram_cas_n                        (DRAM_CAS_N),
   .sdram_cke                          (DRAM_CKE),
   .sdram_cs_n                         (DRAM_CS_N),
   .sdram_dq                           (DRAM_DQ),
   .sdram_dqm                          ({DRAM_UDQM,DRAM_LDQM}),
   .sdram_ras_n                        (DRAM_RAS_N),
   .sdram_we_n                         (DRAM_WE_N),
   
   ////////////////////////////////////
   // HPS Side
   ////////////////////////////////////
   // DDR3 SDRAM
   .memory_mem_a        (HPS_DDR3_ADDR),
   .memory_mem_ba       (HPS_DDR3_BA),
   .memory_mem_ck       (HPS_DDR3_CK_P),
   .memory_mem_ck_n     (HPS_DDR3_CK_N),
   .memory_mem_cke      (HPS_DDR3_CKE),
   .memory_mem_cs_n     (HPS_DDR3_CS_N),
   .memory_mem_ras_n    (HPS_DDR3_RAS_N),
   .memory_mem_cas_n    (HPS_DDR3_CAS_N),
   .memory_mem_we_n     (HPS_DDR3_WE_N),
   .memory_mem_reset_n  (HPS_DDR3_RESET_N),
   .memory_mem_dq       (HPS_DDR3_DQ),
   .memory_mem_dqs      (HPS_DDR3_DQS_P),
   .memory_mem_dqs_n    (HPS_DDR3_DQS_N),
   .memory_mem_odt      (HPS_DDR3_ODT),
   .memory_mem_dm       (HPS_DDR3_DM),
   .memory_oct_rzqin    (HPS_DDR3_RZQ),
        
   // Ethernet
   .hps_io_hps_io_gpio_inst_GPIO35  (HPS_ENET_INT_N),
   .hps_io_hps_io_emac1_inst_TX_CLK (HPS_ENET_GTX_CLK),
   .hps_io_hps_io_emac1_inst_TXD0   (HPS_ENET_TX_DATA[0]),
   .hps_io_hps_io_emac1_inst_TXD1   (HPS_ENET_TX_DATA[1]),
   .hps_io_hps_io_emac1_inst_TXD2   (HPS_ENET_TX_DATA[2]),
   .hps_io_hps_io_emac1_inst_TXD3   (HPS_ENET_TX_DATA[3]),
   .hps_io_hps_io_emac1_inst_RXD0   (HPS_ENET_RX_DATA[0]),
   .hps_io_hps_io_emac1_inst_MDIO   (HPS_ENET_MDIO),
   .hps_io_hps_io_emac1_inst_MDC    (HPS_ENET_MDC),
   .hps_io_hps_io_emac1_inst_RX_CTL (HPS_ENET_RX_DV),
   .hps_io_hps_io_emac1_inst_TX_CTL (HPS_ENET_TX_EN),
   .hps_io_hps_io_emac1_inst_RX_CLK (HPS_ENET_RX_CLK),
   .hps_io_hps_io_emac1_inst_RXD1   (HPS_ENET_RX_DATA[1]),
   .hps_io_hps_io_emac1_inst_RXD2   (HPS_ENET_RX_DATA[2]),
   .hps_io_hps_io_emac1_inst_RXD3   (HPS_ENET_RX_DATA[3]),

   // Flash
   .hps_io_hps_io_qspi_inst_IO0  (HPS_FLASH_DATA[0]),
   .hps_io_hps_io_qspi_inst_IO1  (HPS_FLASH_DATA[1]),
   .hps_io_hps_io_qspi_inst_IO2  (HPS_FLASH_DATA[2]),
   .hps_io_hps_io_qspi_inst_IO3  (HPS_FLASH_DATA[3]),
   .hps_io_hps_io_qspi_inst_SS0  (HPS_FLASH_NCSO),
   .hps_io_hps_io_qspi_inst_CLK  (HPS_FLASH_DCLK),

   // Accelerometer
   .hps_io_hps_io_gpio_inst_GPIO61  (HPS_GSENSOR_INT),

   // General Purpose I/O
   .hps_io_hps_io_gpio_inst_GPIO40  (HPS_GPIO[0]),
   .hps_io_hps_io_gpio_inst_GPIO41  (HPS_GPIO[1]),

   // I2C
   .hps_io_hps_io_gpio_inst_GPIO48  (HPS_I2C_CONTROL),
   .hps_io_hps_io_i2c0_inst_SDA     (HPS_I2C1_SDAT),
   .hps_io_hps_io_i2c0_inst_SCL     (HPS_I2C1_SCLK),
   .hps_io_hps_io_i2c1_inst_SDA     (HPS_I2C2_SDAT),
   .hps_io_hps_io_i2c1_inst_SCL     (HPS_I2C2_SCLK),

   // Pushbutton
   .hps_io_hps_io_gpio_inst_GPIO54  (HPS_KEY),

   // LED
   .hps_io_hps_io_gpio_inst_GPIO53  (HPS_LED),

   // SD Card
   .hps_io_hps_io_sdio_inst_CMD  (HPS_SD_CMD),
   .hps_io_hps_io_sdio_inst_D0   (HPS_SD_DATA[0]),
   .hps_io_hps_io_sdio_inst_D1   (HPS_SD_DATA[1]),
   .hps_io_hps_io_sdio_inst_CLK  (HPS_SD_CLK),
   .hps_io_hps_io_sdio_inst_D2   (HPS_SD_DATA[2]),
   .hps_io_hps_io_sdio_inst_D3   (HPS_SD_DATA[3]),

   // SPI
   .hps_io_hps_io_spim1_inst_CLK    (HPS_SPIM_CLK),
   .hps_io_hps_io_spim1_inst_MOSI   (HPS_SPIM_MOSI),
   .hps_io_hps_io_spim1_inst_MISO   (HPS_SPIM_MISO),
   .hps_io_hps_io_spim1_inst_SS0    (HPS_SPIM_SS),

   // UART
   .hps_io_hps_io_uart0_inst_RX  (HPS_UART_RX),
   .hps_io_hps_io_uart0_inst_TX  (HPS_UART_TX),

   // USB
   .hps_io_hps_io_gpio_inst_GPIO09  (HPS_CONV_USB_N),
   .hps_io_hps_io_usb1_inst_D0      (HPS_USB_DATA[0]),
   .hps_io_hps_io_usb1_inst_D1      (HPS_USB_DATA[1]),
   .hps_io_hps_io_usb1_inst_D2      (HPS_USB_DATA[2]),
   .hps_io_hps_io_usb1_inst_D3      (HPS_USB_DATA[3]),
   .hps_io_hps_io_usb1_inst_D4      (HPS_USB_DATA[4]),
   .hps_io_hps_io_usb1_inst_D5      (HPS_USB_DATA[5]),
   .hps_io_hps_io_usb1_inst_D6      (HPS_USB_DATA[6]),
   .hps_io_hps_io_usb1_inst_D7      (HPS_USB_DATA[7]),
   .hps_io_hps_io_usb1_inst_CLK     (HPS_USB_CLKOUT),
   .hps_io_hps_io_usb1_inst_STP     (HPS_USB_STP),
   .hps_io_hps_io_usb1_inst_DIR     (HPS_USB_DIR),
   .hps_io_hps_io_usb1_inst_NXT     (HPS_USB_NXT),
   
   
	.sdr_clk_clk          (sdr_clk),
   .sdr_reset_export     (sdr_reset),
   .sdr_baseaddr_export  (sdr_baseaddr),
   .sdr_nelems_export    (sdr_nelems),
   .sdr_readdata_export  (sdr_readdata),
   .sdr_readend_export   (sdr_readend),
   .sdr_readstart_export (sdr_readstart),
   .sdr_writedata_export (sdr_writedata),
   .sdr_writeend_export  (sdr_writeend),
   .sdr_writestart_export(sdr_writestart),
	.start_rt_export      (start_rt)
);


endmodule
