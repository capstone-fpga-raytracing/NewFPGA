module avalon_control(
  input logic clk,
  input logic reset,
  input logic [31:0] avs_s0_writedata,
  input logic avs_s0_write,
  
  // external
  output logic start_rt,
  output logic av_clk,
  output logic av_reset
);

assign av_clk = clk;
assign av_reset = reset;
// Start raytracing.
// Without a waitrequest from this module, 
// start_rt is asserted for exactly one cycle.
assign start_rt = avs_s0_write;

endmodule
