`timescale 1ns / 1ps


module AES_ecb_top(
  input clk,
  input reset,
  input start,
  input [31:0] key_word,
  input valid_word,
  input [127:0] plain_text,
  
  output done,
  output reg [127:0] cipher_text
    );
    
   parameter RST  = 4'b0000;
   parameter IDLE = 4'b0001;
   parameter RD_KEY  = 4'b0010;
   parameter SUB_BYTES = 4'b0011;
   parameter SHIFT_ROWS = 4'b0100;
   parameter ADD_KEY  = 4'b0101;
   parameter MIX_COLUMNS  = 4'b0110;
   parameter DONE  = 4'b0111;
   parameter RD_ROM = 4'b1000;
   parameter FINAL_KEY_ADD = 4'b1001;
   parameter WT_KEY = 4'b1010;
   //parameter <state12> = 4'b1011;
   //parameter <state13> = 4'b1100;
   //parameter <state14> = 4'b1101;
   //parameter <state15> = 4'b1110;
   //parameter <state16> = 4'b1111;

   reg [3:0] aes_fsm_state = RST;
   reg [127:0] plain_text_int, key_int, add_key_reg,sub_reg, shift_row_reg;
   reg [5:0] index = 0;
   wire [5:0] key_addr;
   wire [31:0] key;
   reg [1:0] delay = 0;
   wire busy;
   wire [31:0] s_val_temp_wrd_0,s_val_temp_wrd_1,s_val_temp_wrd_2,s_val_temp_wrd_3;
   wire ROM_rd;
   wire [7:0] s00_res, s10_res,s20_res,s30_res;
   wire [7:0] s01_res, s11_res,s21_res,s31_res;
   wire [7:0] s02_res, s12_res,s22_res,s32_res;
   wire [7:0] s03_res, s13_res,s23_res,s33_res;
       
   
   
   always @(posedge clk)
      if (reset) begin
         aes_fsm_state <= RST;
      end
      else
         case (aes_fsm_state)
           RST : begin
             aes_fsm_state <= IDLE;
           end
           
           IDLE : begin
             if(start) begin
               aes_fsm_state <= WT_KEY;
             end
           end
           
           WT_KEY : begin
             if(!busy) begin
               aes_fsm_state <= RD_KEY;
             end
           end
           
           RD_KEY : begin
             if(delay == 2'b11) begin
               if(index == 14) begin
                 aes_fsm_state <= FINAL_KEY_ADD;
               end
               else begin
                 aes_fsm_state <= ADD_KEY;
               end
             end
           end
           
           ADD_KEY : begin
             aes_fsm_state <= RD_ROM;
           end
           
           RD_ROM : begin
             aes_fsm_state <= SUB_BYTES;
           end
           
           SHIFT_ROWS : begin
             aes_fsm_state <= MIX_COLUMNS;
           end
           
           SUB_BYTES : begin
             aes_fsm_state <= SHIFT_ROWS;
           end
           
           MIX_COLUMNS : begin
             aes_fsm_state <= RD_KEY;
           end
           
           FINAL_KEY_ADD : begin
             aes_fsm_state <= DONE;
           end
           
           DONE : begin
             aes_fsm_state <= IDLE;
           end
           
         endcase
    
    always@(posedge clk) begin
      if(aes_fsm_state == IDLE) begin
        index <= 0;
      end
      else if(aes_fsm_state == MIX_COLUMNS) begin
        index <= index + 1;
      end
      

    end
    
    always@(posedge clk) begin
      case(aes_fsm_state) 
        IDLE : delay <= 0;
        RD_KEY : delay <= delay + 1;
      endcase
      
      case(aes_fsm_state) 
        RD_KEY : begin
          key_int <= {key_int[95:0],key};
        end
      endcase
      
      case(aes_fsm_state)
      
      IDLE : begin
        plain_text_int <= plain_text;
      end
      
      MIX_COLUMNS : begin
        plain_text_int <= {s00_res, s10_res, s20_res,s30_res,
                        s01_res, s11_res, s21_res,s31_res,
                        s02_res, s12_res, s22_res,s32_res,
                        s03_res, s13_res, s23_res,s33_res};  
      end
      
      endcase
      
      if(aes_fsm_state == SUB_BYTES) begin
        sub_reg <= {s_val_temp_wrd_3,s_val_temp_wrd_2,s_val_temp_wrd_1,s_val_temp_wrd_0};
      end
      
      if(aes_fsm_state == ADD_KEY) begin
        add_key_reg <= plain_text_int ^ key_int;
      end
      
      if(aes_fsm_state == SHIFT_ROWS) begin
        shift_row_reg <= {sub_reg[127:120],sub_reg[87:80],sub_reg[47:40],sub_reg[7:0],
                          sub_reg[95:88],sub_reg[55:48],sub_reg[15:8],sub_reg[103:96],
                          sub_reg[63:56],sub_reg[23:16],sub_reg[111:104],sub_reg[71:64],
                          sub_reg[31:24],sub_reg[119:112],sub_reg[79:72],sub_reg[39:32]};
      end
      
      if(aes_fsm_state == FINAL_KEY_ADD) begin
        cipher_text <= key_int ^ shift_row_reg;
      end
      
      
    end
    
    assign key_addr = {index[3:0],delay};
    
key_expansion key_gen(
  .clk         (clk         ),
  .reset       (reset       ),
  .key_word    (key_word    ),
  .valid_word  (valid_word  ),
  .encrypt_addr(key_addr),
  .encrypt_out (key ),
  .busy        (busy)
    );    
    
    assign ROM_rd = (aes_fsm_state == RD_ROM);
    
s_table_ROM byte_0_3(
 .clk(clk),
 .rd(ROM_rd),
 .address(add_key_reg[7:0]),
 .sub_val(s_val_temp_wrd_0[7:0])
    );       
    
s_table_ROM byte_0_2(
 .clk(clk),
 .rd(ROM_rd),
 .address(add_key_reg[15:8]),
 .sub_val(s_val_temp_wrd_0[15:8])
    );   
    
s_table_ROM byte_0_1(
 .clk(clk),
 .rd(ROM_rd),
 .address(add_key_reg[23:16]),
 .sub_val(s_val_temp_wrd_0[23:16])
    );   
    
s_table_ROM byte_0_0(
 .clk(clk),
 .rd(ROM_rd),
 .address(add_key_reg[31:24]),
 .sub_val(s_val_temp_wrd_0[31:24])
    );       
   
s_table_ROM byte_1_3(
 .clk(clk),
 .rd(ROM_rd),
 .address(add_key_reg[39:32]),
 .sub_val(s_val_temp_wrd_1[7:0])
    );       
    
s_table_ROM byte_1_2(
 .clk(clk),
 .rd(ROM_rd),
 .address(add_key_reg[47:40]),
 .sub_val(s_val_temp_wrd_1[15:8])
    );   
    
s_table_ROM byte_1_1(
 .clk(clk),
 .rd(ROM_rd),
 .address(add_key_reg[55:48]),
 .sub_val(s_val_temp_wrd_1[23:16])
    );   
    
s_table_ROM byte_1_0(
 .clk(clk),
 .rd(ROM_rd),
 .address(add_key_reg[63:56]),
 .sub_val(s_val_temp_wrd_1[31:24])
    );       
    
s_table_ROM byte_2_3(
 .clk(clk),
 .rd(ROM_rd),
 .address(add_key_reg[71:64]),
 .sub_val(s_val_temp_wrd_2[7:0])
    );       
    
s_table_ROM byte_2_2(
 .clk(clk),
 .rd(ROM_rd),
 .address(add_key_reg[79:72]),
 .sub_val(s_val_temp_wrd_2[15:8])
    );   
    
s_table_ROM byte_2_1(
 .clk(clk),
 .rd(ROM_rd),
 .address(add_key_reg[87:80]),
 .sub_val(s_val_temp_wrd_2[23:16])
    );   
    
s_table_ROM byte_2_0(
 .clk(clk),
 .rd(ROM_rd),
 .address(add_key_reg[95:88]),
 .sub_val(s_val_temp_wrd_2[31:24])
    );   
    
s_table_ROM byte_3_3(
 .clk(clk),
 .rd(ROM_rd),
 .address(add_key_reg[103:96]),
 .sub_val(s_val_temp_wrd_3[7:0])
    );       
    
s_table_ROM byte_3_2(
 .clk(clk),
 .rd(ROM_rd),
 .address(add_key_reg[111:104]),
 .sub_val(s_val_temp_wrd_3[15:8])
    );   
    
s_table_ROM byte_3_1(
 .clk(clk),
 .rd(ROM_rd),
 .address(add_key_reg[119:112]),
 .sub_val(s_val_temp_wrd_3[23:16])
    );   
    
s_table_ROM byte_3_0(
 .clk(clk),
 .rd(ROM_rd),
 .address(add_key_reg[127:120]),
 .sub_val(s_val_temp_wrd_3[31:24])
    );      
    



mix_column s00(
  .two  (shift_row_reg[127:120]),
  .three(shift_row_reg[119:112]),
  .one_1(shift_row_reg[111:104]),
  .one_2(shift_row_reg[103:96]),  
  .res  (s00_res)
    );  
	
mix_column s10(
  .two  (shift_row_reg[119:112]),
  .three(shift_row_reg[111:104]),
  .one_1(shift_row_reg[103:96]),
  .one_2(shift_row_reg[127:120]),  
  .res  (s10_res)
    );  

mix_column s20(
  .two  (shift_row_reg[111:104]),
  .three(shift_row_reg[103: 96]),
  .one_1(shift_row_reg[127:120]),
  .one_2(shift_row_reg[119:112]),  
  .res  (s20_res)
    );  	    

mix_column s30(
  .two  (shift_row_reg[103: 96]),
  .three(shift_row_reg[127:120]),
  .one_1(shift_row_reg[119:112]),
  .one_2(shift_row_reg[111:104]),  
  .res  (s30_res)
    );  	    
    
mix_column s01(
  .two  (shift_row_reg[95:88]),
  .three(shift_row_reg[87:80]),
  .one_1(shift_row_reg[79:72]),
  .one_2(shift_row_reg[71:64]),  
  .res  (s01_res)
    );  
	
mix_column s11(
  .two  (shift_row_reg[87:80]),
  .three(shift_row_reg[79:72]),
  .one_1(shift_row_reg[71:64]),
  .one_2(shift_row_reg[95:88]),  
  .res  (s11_res)
    );  

mix_column s21(
  .two  (shift_row_reg[79:72]),
  .three(shift_row_reg[71:64]),
  .one_1(shift_row_reg[95:88]),
  .one_2(shift_row_reg[87:80]),  
  .res  (s21_res)
    );  	    

mix_column s31(
  .two  (shift_row_reg[71:64]),
  .three(shift_row_reg[95:88]),
  .one_1(shift_row_reg[87:80]),
  .one_2(shift_row_reg[79:72]),  
  .res  (s31_res)
    );  	    	
   
mix_column s02(
  .two  (shift_row_reg[63:56]),
  .three(shift_row_reg[55:48]),
  .one_1(shift_row_reg[47:40]),
  .one_2(shift_row_reg[39:32]),  
  .res  (s02_res)
    );  
	
mix_column s12(
  .two  (shift_row_reg[55:48]),
  .three(shift_row_reg[47:40]),
  .one_1(shift_row_reg[39:32]),
  .one_2(shift_row_reg[63:56]),  
  .res  (s12_res)
    );  

mix_column s22(
  .two  (shift_row_reg[47:40]),
  .three(shift_row_reg[39:32]),
  .one_1(shift_row_reg[63:56]),
  .one_2(shift_row_reg[55:48]),  
  .res  (s22_res)
    );  	    

mix_column s32(
  .two  (shift_row_reg[39:32]),
  .three(shift_row_reg[63:56]),
  .one_1(shift_row_reg[55:48]),
  .one_2(shift_row_reg[47:40]),  
  .res  (s32_res)
    );  	    	
    
mix_column s03(
  .two  (shift_row_reg[31:24]),
  .three(shift_row_reg[23:16]),
  .one_1(shift_row_reg[15: 8]),
  .one_2(shift_row_reg[ 7: 0]),  
  .res  (s03_res)
    );  
	
mix_column s13(
  .two  (shift_row_reg[23:16]),
  .three(shift_row_reg[15: 8]),
  .one_1(shift_row_reg[ 7: 0]),
  .one_2(shift_row_reg[31:24]),  
  .res  (s13_res)
    );  

mix_column s23(
  .two  (shift_row_reg[15: 8]),
  .three(shift_row_reg[ 7: 0]),
  .one_1(shift_row_reg[31:24]),
  .one_2(shift_row_reg[23:16]),  
  .res  (s23_res)
    );  	    

mix_column s33(
  .two  (shift_row_reg[ 7: 0]),
  .three(shift_row_reg[31:24]),
  .one_1(shift_row_reg[23:16]),
  .one_2(shift_row_reg[15: 8]),  
  .res  (s33_res)
    );  	    	
        
   assign done = (aes_fsm_state == DONE);
       
        	
    
endmodule
