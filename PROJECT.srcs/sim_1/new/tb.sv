`timescale 1ns / 1ps
   
//komendy DS1620:
`define rd_cfg 8'hac
`define wr_cfg 8'h0C
`define start_convt 8'hee
`define stop_convt 8'h22
`define rd_temp 8'haa
/*
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
       #7500 conv_done = 1'b1; //naprawdÄ™ 750ms #75000 
endmodule
*/

module ds1620 #(parameter conversionDelay = 75000) (input clk, rstbar, sclk, inout dq);

    wire hasClkWentUp;
    reg tmpClkWentUp;
    reg counterFull;
    reg tmpRstWentUp;
    wire hasRstWentUp;
    
    always @(posedge clk)
        tmpClkWentUp <= sclk;
        
    always @(posedge clk)
        tmpRstWentUp <= rstbar;
    
    assign hasClkWentUp = ~tmpClkWentUp & sclk;
    assign hasClkWentDown = tmpClkWentUp & ~sclk;
    assign hasRstWentUp = ~tmpRstWentUp & rstbar;

    reg [7:0] receivedData;
    reg [3:0] receivedCounter;
    reg [3:0] sentCounter;
    reg [7:0] configReg;
    reg [8:0] convertedData = 9'b101010101; // example data
    reg conversionStarted;
    localparam timerBits = $clog2(conversionDelay);
    reg [timerBits: 0] conversionTimer;

    reg [8:0] outShreg;
    
    // reg dqReg;
    
    initial begin   // rather than a reset
        receivedData = 8'b0;
        receivedCounter = 4'b0;
        sentCounter = 4'b0;
        counterFull = 1'b0;
        configReg = 8'b00000001;
        conversionStarted = 1'b0;
        conversionTimer = {timerBits{1'b0}};
        // dqReg = 1'b0;
    end
    
    typedef enum {Idle, Receiving, StartingConv, TransmittingConfig, TransmittingData} states;
    
    states state;
    states nextstate;
    
    always @(posedge clk)
        if(~rstbar) state <= Idle;
        else state <= nextstate;

    always @*
        case(state)
            Idle: nextstate = rstbar ? Receiving : Idle;
            Receiving: 
                begin
                    if(receivedCounter[3] & hasClkWentDown) begin
                        if(receivedData == 8'hee) nextstate = StartingConv;
                        else if(receivedData == 8'hac) nextstate = TransmittingConfig;
                        else if(receivedData == 8'haa) nextstate = TransmittingData;
                        else nextstate = Receiving;
                    end
                    else nextstate = Receiving;
                end
            StartingConv: nextstate = Receiving;
            TransmittingConfig: nextstate = sentCounter == 7 & hasRstWentUp ? Receiving : TransmittingConfig;
            TransmittingData: nextstate = sentCounter == 4'b1001 & hasRstWentUp ? Receiving : TransmittingData;
        endcase
     
     // conversion:
     always @(posedge clk)
        if(state == StartingConv) begin
            conversionStarted <= 1'b1;
            conversionTimer <= 0;
        end
        
     always @(posedge clk)
        if(conversionStarted) begin
            if(conversionTimer == conversionDelay) begin
                conversionTimer <= {timerBits{1'b0}};
                configReg[0] <= 1'b1;
                conversionTimer <= 0;
            end
            else conversionTimer <= conversionTimer + 1'b1;
        end
     
     // receiver:
     always @(posedge clk)
        if(state == Receiving | state == StartingConv) begin
            if(hasClkWentUp) begin
                receivedData[receivedCounter] <= dq;
                receivedCounter <= receivedCounter + 1'b1;
            end
            if(receivedCounter[3] & hasClkWentUp) begin
                receivedCounter <= 0;
                //counterFull <= 1'b1;
            end
            if(state == StartingConv) begin
                receivedData <= 8'b0;
                receivedCounter <= 4'b0;
            end
            //else if(counterFull) counterFull <= 1'b0;
        end
        else if(state == TransmittingConfig | state == TransmittingData)
            if(receivedCounter[3] & hasClkWentUp) begin
                receivedCounter <= 4'b0;
                receivedData <= 8'b0;
            end
        
     // sender:
     always @(posedge clk) begin
        if(state == Receiving & nextstate == TransmittingConfig) begin
            outShreg <= {configReg,1'b0};
        end
        else if(state == Receiving & nextstate == TransmittingData) begin
            outShreg <= convertedData;
        end
        if(state == TransmittingConfig) begin
            if(hasClkWentUp) begin
                if(sentCounter < 7) begin
                    outShreg <= {outShreg[0],outShreg[7:1]};
                    sentCounter <= sentCounter + 1'b1;
                end
                else sentCounter <= 4'b0;
            end
        end
        else if(state == TransmittingData) begin
            if(hasClkWentUp) begin
                if(sentCounter < 4'b1001) begin
                    outShreg <= {outShreg[0],outShreg[7:1]};
                    sentCounter <= sentCounter + 1'b1;
                end
                else sentCounter <= 4'b0;
            end
        end
        else if(state == Receiving) begin
            sentCounter <= 4'b0;
        end
     end
        
     assign dq = (state == TransmittingConfig | state == TransmittingData) ? outShreg[0] : 1'bz;
    
endmodule


module tb();

    wire WIRE3DQ, WIRE3RST, WIRE3CLK;
    reg CLK, RST, START;
    wire READY;
    wire [8:0] DATAOUT;

    wire3 #(.wire3clkdiv(100)) testMaster(.clk(CLK), .rst(RST), .start(START), .wire3clk(WIRE3CLK), .wire3dq(WIRE3DQ), .wire3rst(WIRE3RST), .ready(READY), .dataOut(DATAOUT));
    
    ds1620 #(.conversionDelay(20)) testSlave(.clk(CLK), .rstbar(WIRE3RST), .sclk(WIRE3CLK), .dq(WIRE3DQ));
    
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
    
    initial begin
        #3000000 $finish;
    end
    
endmodule
