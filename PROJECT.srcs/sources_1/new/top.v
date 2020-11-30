`timescale 1ns / 1ps


module top #(parameter nb = 9)(input clk, rst, start, rx, output tx, output wire3rst, output wire3clk, inout wire3dq, output [nb-1:0] dataOut);

    reg ready;  
    
    wire3 wire3_mod (.clk(clk), .rst(rst), .start(start), .wire3dq(wire3dq), .wire3clk(wire3clk), .wire3rst(wire3rst), .ready(ready), .dataOut(dataOut));
    

//    wire [7:0] leds;
//    wire rstp = rst;
//    wire rstn = ~rstp;
//    wire [31:0] s_axi_wdata, s_axi_rdata;
//    wire [3:0] s_axi_awaddr, s_axi_araddr;
//    wire [1:0] s_axi_bresp; //, s_axi_rresp;
//    wire [3:0] s_axi_wstrb = 4'b1;
//    axi_uartlite_0 uart_ip (.s_axi_aclk(clk),        // input wire s_axi_aclk
//      .s_axi_aresetn(rstn),  // input wire s_axi_aresetn
//      .interrupt(interrupt),          // output wire interrupt
//      .s_axi_awaddr(s_axi_awaddr),    // input wire [3 : 0] s_axi_awaddr
//      .s_axi_awvalid(s_axi_awvalid),  // input wire s_axi_awvalid
//      .s_axi_awready(s_axi_awready),  // output wire s_axi_awready
//      .s_axi_wdata(s_axi_wdata),      // input wire [31 : 0] s_axi_wdata
//      .s_axi_wstrb(s_axi_wstrb),      // input wire [3 : 0] s_axi_wstrb
//      .s_axi_wvalid(s_axi_wvalid),    // input wire s_axi_wvalid
//      .s_axi_wready(s_axi_wready),    // output wire s_axi_wready
//      .s_axi_bresp(s_axi_bresp),      // output wire [1 : 0] s_axi_bresp
//      .s_axi_bvalid(s_axi_bvalid),    // output wire s_axi_bvalid
//      .s_axi_bready(s_axi_bready),    // input wire s_axi_bready
//      .s_axi_araddr(s_axi_araddr),    // input wire [3 : 0] s_axi_araddr
//      .s_axi_arvalid(s_axi_arvalid),  // input wire s_axi_arvalid
//      .s_axi_arready(s_axi_arready),  // output wire s_axi_arready
//      .s_axi_rdata(s_axi_rdata),      // output wire [31 : 0] s_axi_rdata
//      .s_axi_rresp(),      // output wire [1 : 0] s_axi_rresp
//      .s_axi_rvalid(s_axi_rvalid),    // output wire s_axi_rvalid
//      .s_axi_rready(s_axi_rready),    // input wire s_axi_rready
//      .rx(rx),                        // input wire rx
//      .tx(tx)                        // output wire tx
//    );
      
////    reg [4:0] nd = 8;
//    wire [$clog2(8)-1:0] addr;
//    wire [7:0] received, transmit;
//    assign transmit = dataOut[7:0];
    
//    master_axi_uart #(.nd(8)) master (.clk(clk), .rst(rstp), .start(ready), .rec_trn(led),
//        .awadr(s_axi_awaddr), .awvalid(s_axi_awvalid), .awrdy(s_axi_awready),
//        .wdata(s_axi_wdata), .wvalid(s_axi_wvalid), .wrdy(s_axi_wready),
//        .bdata(s_axi_bresp), .bvalid(s_axi_bvalid), .brdy(s_axi_bready),    //not needed
//        .aradr(s_axi_araddr), .arvalid(s_axi_arvalid), .arrdy(s_axi_arready),
//        .rdata(s_axi_rdata), .rvalid(s_axi_rvalid), .rrdy(s_axi_rready),
//        .received(received), .dcnt(addr), .wstb(wr),
//        .transmit(transmit), .rstb(rd));
            
endmodule
