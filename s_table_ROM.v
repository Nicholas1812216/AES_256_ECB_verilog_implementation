`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/29/2021 07:01:36 PM
// Design Name: 
// Module Name: s_table_ROM
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module s_table_ROM(
 input clk,
 input rd,
 input [7:0] address,
 output [7:0] sub_val
    );
    

   parameter ROM_WIDTH = 8;
   parameter ROM_ADDR_BITS = 8;

   (* rom_style="{distributed | block}" *)
   reg [ROM_WIDTH-1:0] substitution_table [(2**ROM_ADDR_BITS)-1:0];
   reg [ROM_WIDTH-1:0] s_value;

   wire [ROM_ADDR_BITS-1:0] rom_address = address;
   assign sub_val = s_value;
   initial
      $readmemh("C:/Users/19259/Documents/AES_256/substitution_table.txt", substitution_table, 0, (2**ROM_ADDR_BITS)-1);

   always @(posedge clk)
      if (rd)
         s_value <= substitution_table[rom_address];
				
				    
    
endmodule
