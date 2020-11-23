`timescale 1ns / 1ps

module wire3 #(parameter wire3clkdiv = 1000)(input clk, rst, start, inout wire3dq, output wire3clk, wire3rst, output ready, output [8:0] dataOut );
    
    typedef enum {Idle, Starting, AskingForConfig, ReadingConfig, AskingForData, ReadingData, PublishingData } states;
    states state, nextstate;
    
    reg[7:0] startCMD = 8'hee;
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
            wire3rstReg <= 1'b0;
        end
        else if (state == Starting) begin
            if (bytesSend[3]) begin
                bytesSend <= 4'b0;
                wire3rstReg <= 1'b0;
            end
            else if(hasClkWentDown) begin
                wire3rstReg <= 1'b0;
                wire3dqReg <= startCMD[bytesSend];
                bytesSend <= bytesSend + 1'b1;
            end
        end
        else if (state == AskingForConfig) begin
            if (bytesSend[3]) begin
                bytesSend <= 4'b0;
                wire3rstReg <= 1'b0;
            end
            else if(hasClkWentDown) begin
                wire3rstReg <= 1'b0;
                wire3dqReg <= readConfigCMD[bytesSend];
                bytesSend <= bytesSend + 1'b1;
            end
        end
        else if (state == ReadingConfig) begin
            if(hasClkWentDown && bytesSend == 4'b0) begin
                hasEnded <= wire3dq;
                bytesSend <= bytesSend + 1'b1;
            end
            else if (hasClkWentDown) bytesSend <= bytesSend + 1'b1;
        end
        else if (state == AskingForData) begin
            if(bytesSend[3]) begin
                bytesSend <= 4'b0;
                wire3rstReg <= 1'b0;
            end
            else if(hasClkWentDown) begin
                wire3rstReg <= 1'b0;
                wire3dqReg <= readCMD[bytesSend];
                bytesSend <= bytesSend + 1'b1; 
            end
        end
        else if (state == ReadingData) begin
            if(bytesSend == 4'b1001) bytesSend <= 4'b0;
            else if (hasClkWentDown) begin
                data[bytesSend] <= wire3dq;
                bytesSend <= bytesSend + 1'b1;
            end
        end
    end
    
    assign wire3dq = wire3dqReg;
    assign wire3rst = wire3rstReg;
    // END OF SENDER/RECEIVER

   
    // ASSIGNING DATA TO OUTPUT:
    always @(posedge clk, posedge rst)
        if(rst) dataOutReg <= 9'b0;
        else if (state == PublishingData) dataOutReg <= data;
    assign dataOut = dataOutReg;
    
    // READY INFORMATION:
    assign ready = (state == PublishingData) ? 1'b1 : 1'b0;
        
    
    // FINITE STATE MACHINE
    always @(posedge clk, posedge rst)
        if(rst) state <= Idle;
        else state <= nextstate;
        
    // FINITE STATE MACHINE LOGIC   
    always @* begin
        nextstate = Idle;
        case(state)
            Idle: nextstate = start ? Starting : Idle;
            Starting: nextstate = bytesSend[3] ? Starting : AskingForConfig;
            AskingForConfig: nextstate = bytesSend[3] ? AskingForConfig : ReadingConfig;
            ReadingConfig: nextstate = bytesSend[3] ? hasEnded ? AskingForData : AskingForConfig : ReadingConfig;
            AskingForData: nextstate = bytesSend[3] ? ReadingData : AskingForData;
            ReadingData: nextstate = (bytesSend == 4'b1001) ? PublishingData : ReadingData;
            PublishingData: nextstate = AskingForConfig;
        endcase
    end

endmodule
