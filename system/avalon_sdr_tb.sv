`timescale 1ns / 1ps

//assuming clkin will be 50MHz clock
module rate_divider(input clkin, output reg clkout);

	reg [31:0] counter;

	initial begin
  	  counter = 0;
   	  clkout = 0;
	end
	
	//count down from 50M (1s)
	always @(posedge clkin) begin
   		 if (counter == 0) begin
       			counter <= 10;
       	 		clkout <= ~clkout;
   		 end else begin
       			 counter <= counter -1;
  		end
	end

endmodule

module avalon_sdr_tb;

    // Testbench Signals
    logic clk, reset;
    //logic trigger;
    logic [15:0] avm_m0_readdata;
    logic avm_m0_readdatavalid;
    logic avm_m0_waitrequest;
    logic [31:0] avm_m0_address;
    logic avm_m0_read;
    //logic [14:0] sdr_readdata;
    //logic sdr_readdatavalid, sdr_readend;
	 //logic [4:0] sdr_readoff;

    // logic [223:0] sdr_writedata;
    // initial begin
    //     sdr_writedata = 224'hDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF;
    // end

    // logic sdr_writestart;
    // logic sdr_writeend;

    logic          start_rt;
logic [31:0]   sdr_baseaddr;
logic [29:0]   sdr_nelems;
logic [2047:0] sdr_readdata;
logic sdr_readstart;

    // Instantiate the avalon_sdr module
    avalon_sdr dut (
        .clk(clk),
        .reset(reset),
        .sdr_readstart(sdr_readstart),
        .avm_m0_read(avm_m0_read),
        .avm_m0_address(avm_m0_address),
        .avm_m0_readdata(avm_m0_readdata),
        .avm_m0_readdatavalid(avm_m0_readdatavalid),
        .avm_m0_waitrequest(avm_m0_waitrequest),
        .sdr_baseaddr(sdr_baseaddr),
        .sdr_nelems(sdr_nelems),
        .sdr_readdata(sdr_readdata),
		.sdr_readend(sdr_readend)
		  //.sdr_readoff(sdr_readoff),
        //.avm_m0_read(avm_m0_read)
        
        //.sdr_writedata(sdr_writedata),
        //.sdr_writeend(sdr_writeend),
        //.sdr_writestart(sdr_writestart)
        
        // Connect other signals as needed
    );


// 	logic [14:0][31:0] raydata;

// 	always_ff @(posedge clk) 
// 	begin
// 		 if (!sdr_readend && sdr_readdatavalid) 
// 		 begin
// 			  if (sdr_readoff % 2 == 0)
// 					raydata[sdr_readoff >> 1][15:0] <= sdr_readdata;
// 			  else
// 					raydata[sdr_readoff >> 1][31:16] <= sdr_readdata;
// 		 end
// 	end
// logic raytest, raytest_clk;
// logic [9:0] raytest_addr;
// logic [31:0] raytest_data;

// assign raytest = sdr_readend;

// rate_divider rd ( clk, raytest_clk);

// always_ff @(posedge raytest_clk) 
// begin
// 	if (reset)
// 		raytest_addr <= 10'd0;
// 	else begin
// 		 if (raytest && raytest_addr != 10'd15) begin    
// 			  raytest_data <= raydata[raytest_addr];
// 			  raytest_addr <= raytest_addr + 10'd1;
// 		 end
//    end
// end

wire sdr_clk;
wire sdr_reset;

assign sdr_clk = clk;
assign sdr_reset = reset;

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
         sdr_nelems <= 30'd2;
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

rate_divider rd ( clk, raytest_clk);

always_ff @(posedge raytest_clk or posedge sdr_reset) 
begin
   if (sdr_reset) begin
      raytest_addr <= 10'd0;
      raytest_data <= 32'hDEAD;
   end else if (raytest_clk) begin
      if (raytest && raytest_addr != 10'd2) begin    
           raytest_data <= raydata[32*raytest_addr +: 32];
           raytest_addr <= raytest_addr + 10'd1;
      end
   end
end



    // Clock Generation
    always #5 clk = ~clk; // 100 MHz clock

    // Testbench Logic
    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;
        //trigger = 0;
        //avm_m0_readdata = 0;
        avm_m0_readdatavalid = 0;
        avm_m0_waitrequest = 0;
        //sdr_writestart = 0;

        #20 reset = 0;

        #5 start_rt = 1;
        #20 avm_m0_waitrequest = 1;
        #10 avm_m0_waitrequest = 0;
        
        #20 avm_m0_waitrequest = 1;
        avm_m0_readdata = 20;
        avm_m0_readdatavalid = 1;

        #10 avm_m0_waitrequest = 0;
        avm_m0_readdatavalid = 0;
		avm_m0_readdata = 16'hDEAD; // nonsense

        #10 avm_m0_waitrequest = 1;
        #10 avm_m0_waitrequest = 0;

        #10 avm_m0_readdatavalid = 1;
        avm_m0_readdata = 30;
        #10 avm_m0_readdata = 40;
        #10 avm_m0_readdatavalid = 0;
        avm_m0_readdata = 16'hDEAD; // nonsense

        #20 avm_m0_readdatavalid = 1;
        avm_m0_readdata = 50;
        #10 avm_m0_readdatavalid = 0;
        avm_m0_readdata = 16'hDEAD; // nonsense

        // avm_m0_readdata = 30;
        // #10 avm_m0_waitrequest = 1;
		//   avm_m0_readdata = 16'hDEAD;

        // #20 avm_m0_waitrequest = 0;
        // avm_m0_readdata = 40;
        // #10 avm_m0_waitrequest = 1;
		//   avm_m0_readdata = 16'hDEAD;

        // #20 avm_m0_waitrequest = 0;
        // avm_m0_readdata = 50;
        // #10 avm_m0_waitrequest = 1;
		//   avm_m0_readdata = 16'hDEAD;

        /*
        #10 trigger = 1;
		  #10 trigger = 0;

        // Start test scenarios
        // Example: Simulate a read operation
        #15 avm_m0_readdatavalid = 1;
        avm_m0_readdata = 16'h1234;
        #10 avm_m0_readdatavalid = 0;

		  
        // #10 do_read = 1;
        #30 avm_m0_readdatavalid = 1;
        avm_m0_readdata = 16'hFFFF;
        #10 avm_m0_readdatavalid = 0;
		  

        // #10 do_read = 1;
        #30 avm_m0_readdatavalid = 1;
        avm_m0_readdata = 16'h2222;
        #10 avm_m0_readdatavalid = 0;
		  

        // #10 do_read = 1;
        #30 avm_m0_readdatavalid = 1;
        avm_m0_readdata = 16'h2221;
        #10 avm_m0_readdatavalid = 0;
		  

        // #10 do_read = 1;
        #30 avm_m0_readdatavalid = 1;
        avm_m0_readdata = 16'h2223;
        #10 avm_m0_readdatavalid = 0;
		  

        // #10 do_read = 1;
        #30 avm_m0_readdatavalid = 1;
        avm_m0_readdata = 16'h2225;
        #10 avm_m0_readdatavalid = 0;
		  

        // #10 do_read = 1;
        #30 avm_m0_readdatavalid = 1;
        avm_m0_readdata = 16'h2227;
        */

        // Finish the simulation
        #5000 $finish;
    end

    // Additional test scenarios, checks and monitors

endmodule
