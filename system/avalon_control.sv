module avalon_control
(
  input logic clk,
  input logic reset,
  
  input logic avs_s0_write,
  input logic avs_s0_read,
  input logic [7:0] avs_s0_writedata,
  output logic [7:0] avs_s0_readdata,
  output logic rdirq,
   
  // external 
  output logic start_rt,
  input logic end_rt,
  // optional status at end of raytracing
  input logic [7:0] end_rtstat,
  
  output logic av_clk,
  output logic av_reset
);

assign av_clk = clk;
assign av_reset = reset;

// without wait request from here, this is 1 cycle only
assign start_rt = avs_s0_write;


// keep irq high until serviced
always_ff @(posedge clk)
begin
   if (reset) begin
      rdirq <= 1'b0;
      avs_s0_readdata <= 8'd0;
   end
   else if (end_rt) begin
      rdirq <= 1'b1;
      avs_s0_readdata <= end_rtstat;
   end
   else if (avs_s0_read) begin
      rdirq <= 1'b0;
      avs_s0_readdata <= avs_s0_readdata;
   end
   else begin
      rdirq <= rdirq;
      avs_s0_readdata <= avs_s0_readdata;
   end
end

endmodule
