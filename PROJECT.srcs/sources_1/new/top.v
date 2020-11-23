`timescale 1ns / 1ps


module top(input clk, rst, start);

    localparam hp = 5, brate = 9600, nb = 9;
    reg slowclk;
    reg ready, wire3dq, wire3clk, wire3rst;
    reg [nb-1:0] dataOut;
    
    reg trn, fin;
    
    clkdiv clkdiv_mod (.clk(clk), .rst(rst), .slowclk(slowclk));
    wire3 wire3_mod (.clk(slowclk), .rst(rst), .start(start), .wire3dq(wire3dq), .wire3clk(wire3clk), .wire3rst(wire3rst), .dataOut(dataOut), .ready(ready));
    // dodaæ przypisania do wire3dq, output wire3clk, wire3rst
    simple_transmitter #(.fclk(10**9/(2*hp)), .baudrate(brate), .nb(nb)) simple_transmitter_mod (.clk(clk), .rst(~rst), .str(ready), .val(dataOut), .trn(trn), .fin(fin));
            
endmodule
