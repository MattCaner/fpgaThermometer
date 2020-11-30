`timescale 1ns / 1ps
 
module wire3 #(parameter wire3clkdiv = 1000)(input clk, rst, start, inout reg wire3dq, output wire3clk, wire3rst, output reg ready, output [8:0] dataOut );
    
    typedef enum {Idle, Starting, AskingForConfig, ReadingConfig, WaitBetweenConfig, WaitAfterConfig, AskingForData, ReadingData, PublishingData, WaitAfterData } states;
    states state, nextstate;
    
    // to obtain 150 ns of waitTime
    localparam waitCycles = 15;
    localparam waitCyclesBits = $clog2(waitCycles);
    reg[waitCyclesBits:0] waitClock;
    
    reg[7:0] outShreg;
    
    reg[7:0] startCMD;
    reg[7:0] readConfigCMD = 8'hac;
    reg[7:0] readCMD = 8'haa;
    
    reg[8:0] data;
    
    reg[8:0] dataOutReg;
    
    reg[3:0] bytesSend;
    
    reg wire3dqReg, wire3rstReg;
    
    reg clkout;
    localparam clkoutBits = $clog2(wire3clkdiv);
    reg[clkoutBits:0] clkoutCounter;
    
    // if the conversion has ended
    reg hasEnded;
    
    // CLOCK GENERATION
    always @(posedge clk, posedge rst)
        if(rst) clkout <= 1'b0;
        else if (clkoutCounter == wire3clkdiv) clkout <= ~clkout;
 
    always @(posedge clk, posedge rst)
        if(rst) clkoutCounter <= {clkoutBits{1'b0}};
        else if (clkoutCounter == wire3clkdiv) clkoutCounter <= {clkoutBits{1'b0}};
        else clkoutCounter <= clkoutCounter + 1'b1;
    assign wire3clk = clkout;
    
    wire hasClkWentUp;
    reg tmpClkWentUp;
    
    always @(posedge clk, posedge rst)
        if(rst) tmpClkWentUp <= 1'b0;
        else tmpClkWentUp <= wire3clk;
    
    assign hasClkWentUp = ~tmpClkWentUp & wire3clk;
    assign hasClkWentDown = tmpClkWentUp & ~wire3clk;
 
 
    // SENDER/RECEIVER
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            data <= 9'b0;
            bytesSend <= 4'b0;
            wire3dqReg <= 1'b0;
            hasEnded <= 1'b0;
            startCMD <= 8'hee;
        end
        else begin
            if(nextstate == Starting & state != Starting)
                outShreg <= startCMD;
            if(nextstate == AskingForConfig & state != AskingForConfig)
                outShreg <= readConfigCMD;
            if(nextstate == AskingForData & state != AskingForData)
                outShreg <= readCMD;
            else if (state == Starting | state == AskingForConfig | state == AskingForData) begin
                if (bytesSend == 8 & hasClkWentUp) begin
                    bytesSend <= 4'b0;
                end
                else if(hasClkWentDown) begin
                    outShreg <= {outShreg[0],outShreg[7:1]};
                    bytesSend <= bytesSend + 1'b1;
                end
            end
            else if (state == ReadingConfig) begin
                if(hasClkWentUp && bytesSend == 4'b1) begin
                    hasEnded <= wire3dq;
                    bytesSend <= bytesSend + 1'b1;
                end
                else if (bytesSend == 8 & hasClkWentUp)  bytesSend <= 4'b0;
                else if (hasClkWentUp) bytesSend <= bytesSend + 1'b1;
            end
            else if (state == ReadingData) begin
                if(bytesSend == 4'b1001) bytesSend <= 4'b0;
                else if (hasClkWentUp) begin
                    data[bytesSend] <= wire3dq;
                    bytesSend <= bytesSend + 1'b1;
                end
            end
        end
    end
    
    always @(posedge clk, posedge rst)
        if(rst) wire3rstReg <= 1'b0;
        else if (state == Idle | state == PublishingData | state == WaitBetweenConfig | state == WaitAfterConfig | state == WaitAfterData)
            wire3rstReg <= 1'b0;
        else wire3rstReg <= 1'b1;
    
 
    assign wire3dq = (state == Starting || state == AskingForConfig || state == AskingForData) ? outShreg[7] : 1'bz;
    
    assign wire3rst = wire3rstReg;
    // END OF SENDER/RECEIVER
 
   
    // ASSIGNING DATA TO OUTPUT:
    always @(posedge clk, posedge rst)
        if(rst) dataOutReg <= 9'b0;
        else if (state == PublishingData) dataOutReg <= data;
    assign dataOut = dataOutReg;
    
    // READY INFORMATION:
    assign ready = (state == PublishingData) ? 1'b1 : 1'b0;
        
    // RST wait clock
    always @(posedge clk, posedge rst)
        if(rst) begin
        
        end
        else if(state == WaitBetweenConfig | state == WaitAfterConfig | state == WaitAfterData) begin
            waitClock <= waitClock + 1'b1;
        end
        else begin
            waitClock <= {waitCyclesBits{1'b0}};
        end
    
    // FINITE STATE MACHINE
    always @(posedge clk, posedge rst)
        if(rst) state <= Idle;
        else state <= nextstate;
 
        
    // FINITE STATE MACHINE LOGIC   
    always @* begin
        nextstate = Idle;
        case(state)
            Idle: nextstate = start ? Starting : Idle;
            Starting: nextstate = bytesSend == 8 & hasClkWentUp ? AskingForConfig : Starting;
            AskingForConfig: nextstate = bytesSend == 8 & hasClkWentUp ? ReadingConfig : AskingForConfig;
            //ReadingConfig: nextstate = bytesSend[3] & hasClkWentDown ? hasEnded ? AskingForData : AskingForConfig : ReadingConfig;
            ReadingConfig: begin
                if(bytesSend == 8 & hasClkWentUp) begin
                    if(hasEnded) nextstate = WaitAfterConfig;
                    else nextstate = WaitBetweenConfig;
                end
                else nextstate = ReadingConfig;
            end
            WaitBetweenConfig: nextstate = waitClock == waitCycles ? AskingForConfig : WaitBetweenConfig;
            WaitAfterConfig: nextstate = waitClock == waitCycles ? AskingForData : WaitAfterConfig; 
            AskingForData: nextstate = bytesSend == 8 & hasClkWentUp ? ReadingData : AskingForData;
            ReadingData: nextstate = (bytesSend == 4'b1001) ? PublishingData : ReadingData;
            PublishingData: nextstate = WaitAfterData;
            WaitAfterData: nextstate = waitClock == waitCycles ? AskingForConfig : WaitAfterData;
        endcase
    end
 
endmodule