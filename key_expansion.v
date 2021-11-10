`timescale 1ns / 1ps

module key_expansion(
  input clk,
  input reset,
  input [31:0] key_word,
  input valid_word,
  
  input [5:0] encrypt_addr,
  output [31:0] encrypt_out,
  
  output busy
    );
    
    reg [31:0] key_ram [59:0];
    reg [5:0] rd_address, index;
    wire wr;
    reg [5:0] wr_address;
    reg [31:0] wr_data;
    reg [2:0] count = 0;
    reg [31:0] rot_word,W,s_value;
    wire [5:0] index_comb_sum = index + 1;
    wire [31:0] key_ram_rd_0,s_val_temp, rcon, xorw,s_rom_addr;
    wire ROM_rd, rcon_rd;
    
    

   parameter RST  = 4'b0000;
   parameter IDLE = 4'b0001;
   parameter LATCH  = 4'b0010;
   parameter  ROTWORD = 4'b0011;
   parameter SUB = 4'b0100;
   parameter XORRCON  = 4'b0101;
   parameter XORW  = 4'b0110;
   parameter LATCHW  = 4'b0111;
   parameter SUBLATCH  = 4'b1000;
   //parameter <state10> = 4'b1001;
   //parameter <state11> = 4'b1010;
   //parameter <state12> = 4'b1011;
   //parameter <state13> = 4'b1100;
   //parameter <state14> = 4'b1101;
   //parameter <state15> = 4'b1110;
   //parameter <state16> = 4'b1111;

   reg [3:0] key_exp_state = RST;
   assign busy = (key_exp_state != IDLE);
   always @(posedge clk)
      if (reset) begin
         key_exp_state <= RST;
      end
      else
         case (key_exp_state)
            RST : begin
               key_exp_state <= IDLE;
            end
            IDLE : begin
              if(valid_word) begin
                key_exp_state <= LATCH;
              end
            end
            LATCH : begin
              if(count == 7) begin
                key_exp_state <= LATCHW;
              end
            end
            ROTWORD : begin
              key_exp_state <= SUB;
            end
            SUB : begin
              key_exp_state <= SUBLATCH;
            end
            SUBLATCH : begin
              if(index[2:0] == 3'b0) begin
                key_exp_state <= XORRCON;
              end
              else if(index[1:0] == 2'b0) begin
                key_exp_state <= XORW;
              end
            end
            XORRCON : begin
              key_exp_state <= XORW;
            end
            LATCHW : begin
              if(index[2:0] == 3'b0) begin
                key_exp_state <= ROTWORD;
              end
              else if(index[1:0] == 2'b0) begin
                key_exp_state <= SUB;
              end
              else begin
                key_exp_state <= XORW;
              end
            end 
            XORW : begin
              if(index_comb_sum == 60) begin
                key_exp_state <= RST;
              end
              else begin
                key_exp_state <= LATCHW;
              end
            end
         endcase
							
						  
    
    always@(posedge clk) begin
      case(key_exp_state)
        RST : begin
          count <= 1;
        end
        LATCH : begin
          if(valid_word) begin
            count <= count + 1;
          end
        end      
      endcase
      
      case(key_exp_state)
        LATCH : begin
          index <= 8;
        end 
        XORW : begin
          index <= index + 1;
        end 
      endcase
      
      case(key_exp_state)
        LATCHW : begin
          W <= key_ram_rd_0;
        end
        XORRCON : begin
          W <= rcon ^ s_value;
        end
      endcase
      
      if(key_exp_state == ROTWORD) begin
        rot_word <= {W[23:0],W[31:24]};
      end
      
      if(key_exp_state == SUBLATCH) begin
        s_value <= s_val_temp;
      end      
      
    end    
    
    always@(posedge clk) begin
      case(key_exp_state)
        RST : begin
          wr_address <= 0;
        end 
        IDLE : begin
          if(valid_word) begin
            wr_address <= wr_address + 1;
          end
        end
        LATCH : begin
          if(valid_word) begin
            wr_address <= wr_address + 1;
          end
        end   
        XORW : begin
          wr_address <= wr_address + 1;
        end   
      endcase
    end     
    
    assign wr = (valid_word & ((key_exp_state == IDLE) | (key_exp_state == LATCH))) | (key_exp_state == XORW);
    
    always@(posedge clk) begin
      if(wr) begin
        key_ram[wr_address] <= wr_data;
      end
    end  
    
    assign key_ram_rd_0 = key_ram[rd_address]; 
    
    assign encrypt_out = key_ram[encrypt_addr];     
    
    assign xorw = ((index[2:0] != 3'b0) & (index[1:0] == 2'b0)) ? s_value ^ key_ram_rd_0 : W ^ key_ram_rd_0;
    
    always@(*) begin
      case(key_exp_state) 
        IDLE : wr_data = key_word;
        LATCH : wr_data = key_word;
        XORW : wr_data = xorw;
        default: wr_data = 32'b0;
      endcase
    end
    
    always@(*) begin
      case(key_exp_state) 
        LATCHW : begin
          rd_address = index - 1;
        end
        XORW : begin
          rd_address = index - 8;
        end
        default : begin
          rd_address = 0;
        end
      endcase
    end
    
    assign ROM_rd = (key_exp_state == SUB);
    
s_table_ROM byte_0(
 .clk(clk),
 .rd(ROM_rd),
 .address(s_rom_addr[31:24]),
 .sub_val(s_val_temp[31:24])
    );    
    
s_table_ROM byte_1(
 .clk(clk),
 .rd(ROM_rd),
 .address(s_rom_addr[23:16]),
 .sub_val(s_val_temp[23:16])
    );  
    
    
s_table_ROM byte_2(
 .clk(clk),
 .rd(ROM_rd),
 .address(s_rom_addr[15:8]),
 .sub_val(s_val_temp[15:8])
    );  
    
    
s_table_ROM byte_3(
 .clk(clk),
 .rd(ROM_rd),
 .address(s_rom_addr[7:0]),
 .sub_val(s_val_temp[7:0])
    );   
    
    
assign s_rom_addr = (index[2:0] == 3'b0) ? rot_word : W;
    
    
    assign rcon_rd = (key_exp_state == SUB);
    
rcon_rom rcon_lookup(
 .address({1'b0,index[5:3]}),
 .rd(rcon_rd),
 .clk(clk),
 .rcon(rcon)
    );
        
        
                   
    
endmodule
