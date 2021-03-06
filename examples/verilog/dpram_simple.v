/**
 * this is a simple dpram, intended for implemented as distributed ram in 
 * xilinx fpga.
 */
module dpram_simple(clk, din, we, dout, addr_in, addr_out);
   parameter depth_width = 4;
   parameter width = 8;
   parameter depth = (1<<depth_width);

   input     clk;
   input [width-1:0] din;
   input             we;
   input [depth_width-1:0] addr_in;
   input [depth_width-1:0] addr_out;
   output [width-1:0]      dout;

   reg [width-1:0]         mem[depth-1:0]; /* synthesis syn_ramstyle="select_ram"*/
   // writing
   always @(posedge clk)
     if (we)
       mem[addr_in] <= din;

   // reading, unclocked
   wire [width-1:0] dout = mem[addr_out];
endmodule // dpram_simple
