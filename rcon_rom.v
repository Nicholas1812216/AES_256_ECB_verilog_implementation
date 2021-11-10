`timescale 1ns / 1ps


module rcon_rom(
 input [3:0] address,
 input rd,
 input clk,
 output [31:0] rcon
    );
    

   parameter ROM_WIDTH = 32;

   reg [ROM_WIDTH-1:0] rom;
   assign rcon = rom;
   always @(posedge clk)
      if (rd)
         case (address)
            4'b0001: rom <= 32'h01000000;
            4'b0010: rom <= 32'h02000000;
            4'b0011: rom <= 32'h04000000;
            4'b0100: rom <= 32'h08000000;
            4'b0101: rom <= 32'h10000000;
            4'b0110: rom <= 32'h20000000;
            4'b0111: rom <= 32'h40000000;
         endcase
				
				    
    
endmodule
