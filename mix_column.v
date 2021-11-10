`timescale 1ns / 1ps


module mix_column(
  input [7:0] two,
  input [7:0] three,
  input [7:0] one_1,
  input [7:0] one_2,  
  output [7:0] res
    );
    wire [31:0] column_in = {two,three,one_1,one_2};
    wire [31:0] two_mult,two_temp,three_temp, three_mult;
    
    assign two_temp = {column_in[30:24],1'b0};
    assign three_temp = {column_in[22:16],1'b0} ^ column_in[23:16];
    assign two_mult = column_in[31] ? two_temp ^ 8'h1b : two_temp;
    assign three_mult = column_in[23] ? three_temp ^ 8'h1b : three_temp;
    assign res = one_1 ^ one_2 ^ two_mult ^ three_mult;
endmodule
