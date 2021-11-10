`timescale 1ns / 1ps
module aes_top_sim(    );

  reg clk;
  reg reset;
  reg start = 0;
  reg [31:0] key_word;
  reg valid_word;
  wire done;
  wire [127:0] cipher_text;
//  reg [127:0] plain_text = 128'h00112233445566778899aabbccddeeff;
  reg [127:0] plain_text = 128'h00010203040506070809101112131415;

reg[7:0] index = 8;
//reg [127:0] test_cipher_text = 128'h8ea2b7ca516745bfeafc49904b496089;
reg [127:0] test_cipher_text = 128'h2d9c7b8768abad665e49b75f03f64df8;

AES_ecb_top DUT(.*);

always begin
  #5 clk = 0;
  #5 clk = 1;
end

initial begin
  reset = 1;
  #10 reset = 0;

  wait(index == 0) begin
    start <= 1;
  end
  #20 start <= 0;  
  
end
  
//reg[255:0] cipher_key = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
reg[255:0] cipher_key = 256'h3130292827262524232221201918171615141312111009080706050403020100;

always@(posedge clk) begin
  if(!reset && (index > 0)) begin
    cipher_key <= {cipher_key[223:0],32'b0};
    valid_word <= 1;
	key_word <= cipher_key[255 : 224];
	index <= index - 1;
  end
  else begin
	valid_word <= 0;
  end
  
  
end

    always@(posedge clk) begin
      if(done) begin
        assert(cipher_text == test_cipher_text) $display("encryption succeeded");
        else begin
         $error("encryption failed");
        end
      end
    end



endmodule
