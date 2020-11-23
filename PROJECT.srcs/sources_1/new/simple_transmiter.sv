`timescale 1ns / 1ps


module simple_transmitter #(parameter fclk = 100_000_000, baudrate = 230400, nb = 8) 
    (input clk, rst, str, input [nb-1:0] val, output trn, fin);


reg [nb+1:0] trans_reg;
localparam bcntl = $clog2(nb);
reg [nb-1:0] bitcnt;
reg oper;

typedef enum {Idle, Start, Data, Stop} stateEnum; 
    
stateEnum st, nst;

//freq divider according to baudrate
localparam ratio = fclk/baudrate - 1;
integer cnt;
wire new_bit = (cnt == ratio);
assign fin = new_bit & (st == Stop);
always @(posedge clk, negedge rst) 
    if(~rst) 
        cnt <= 0;
    else if (st != Idle)
        if(cnt == 0) 
            cnt <= ratio;
        else 
            cnt <= cnt - 1; 

//FSM          
always @(posedge clk, negedge rst)
    if(~rst)
        st <= Idle;
    else
        st <= nst;

always @* begin
    nst = Idle;
    case(st)
        Idle: nst = oper?Start:Idle;
        Start: nst = new_bit?Data:Start;
        Data: nst = (bitcnt == 9)?Stop:Data;
        Stop: nst = new_bit?Idle:Stop;
    endcase
end

//shift register and serial output at LSB
assign trn = (st == Data)?trans_reg[0]:1'b1;
always @(posedge clk, negedge rst) 
    if(~rst) 
        trans_reg <= {(nb+2){1'b1}};
    else if(str & (bitcnt == 4'h0))
            trans_reg <= {1'b1, val, 1'b0};
         else if (new_bit & st == Data)
            trans_reg <= {1'b0,trans_reg[9:1]};
         else if(fin)
            trans_reg <= {(nb+2){1'b1}};

//opeartion ff             
always @(posedge clk, negedge rst) 
    if(~rst)
        oper <= 1'b0;
    else if(str)
        oper <= 1'b1;
    else if(fin)
        oper <= 1'b0;
        
//bit counter       
always @(posedge clk, negedge rst) 
    if(~rst) 
        bitcnt <= 4'h0;
    else if (oper & (bitcnt == 4'h9))
            bitcnt <= 4'h0;
         else if ((st == Data) & (oper & new_bit))
            bitcnt <= bitcnt + 4'h1;   
                  
endmodule
