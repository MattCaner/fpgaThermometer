`timescale 1ns / 1ps
   
//komendy DS1620:
`define rd_cfg 8'hac
`define wr_cfg 8'h0C
`define start_convt 8'hee
`define stop_convt 8'h22
`define rd_temp 8'haa

module ds1620(input rstbar,sclk, inout dq);
    reg dqr, conv_done = 1'b0;
    reg [4:0] cntb;
    reg [8:0] data, shreg;
    reg [7:0] cfg, cmd;
    wire [7:0] cmdw;
    wire read_cmd;
    
    event conversion;
    assign dq = dqr;
    //transmit out answer
    always @(negedge sclk, negedge rstbar)
        if(~rstbar)
            dqr <= 1'bz; //dqr <= #40 1'bz;
        else if(cntb >= 4'h8)
            dqr <= (cmd == 8'hac)?cfg[cntb[2:0]]:data[cntb-5'h8];
            
    //receive in query
    always @(posedge sclk, negedge rstbar)
        if(~rstbar)
            shreg <= 9'b0;
        else
            shreg <= {dq,shreg[8:1]};
            
    //command register
    always @(posedge sclk, negedge rstbar)
        if(~rstbar)
            cmd <= 8'b0;
        else if(read_cmd)
            cmd <= cmdw;
        
    assign cmdw = shreg[8:1];

    //bits counter
    always @(posedge sclk, negedge rstbar)
        if(~rstbar)
            cntb <= 5'b0;
        else
            cntb <= cntb + 1;
            
    assign read_cmd = (cntb == 4'h8);

    //command decoder
    always @(posedge sclk, negedge rstbar)
        if(~rstbar) begin
            data <= 8'h00;
            cfg <= 8'h00;
        end
        else if (read_cmd)
            case(cmdw)
                `rd_cfg: cfg <= conv_done?8'h88:8'h08;
                `rd_temp: data <= 9'b1_00110010;
                `start_convt: begin conv_done = 1'b0; ->conversion; end
                default: cfg <= 8'haa;
            endcase
            
    always @(conversion)
       #7500 conv_done = 1'b1; //naprawdę 750ms #75000 
endmodule


module tb();

    wire WIRE3DQ, WIRE3RST, WIRE3CLK;
    reg CLK, RST, START;
    wire READY;
    wire [8:0] DATAOUT;

    wire3 #(.clkdiv(1)) testMaster(.clk(CLK), .rst(RST), .start(START), .wire3clk(WIRE3CLK), .wire3dq(WIRE3DQ), .wire3rst(WIRE3RST), .ready(READY), .dataOut(DATAOUT));
    
    ds1620 testSlave(.rstbar(WIRE3RST), .sclk(WIRE3CLK), .dq(WIRE3DQ));
    
    initial begin
        CLK = 1'b0;
        forever #10 CLK = ~CLK;
    end
    
    initial begin
        RST = 1'b0;
        #5 RST = 1'b1;
        #5 RST = 1'b0;
    end
    
    initial begin
        START = 1'b0;
        #20 START = 1'b1;
        #20 START = 1'b0;
    end
    
endmodule
