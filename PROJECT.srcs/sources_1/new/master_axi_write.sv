`timescale 1ns / 1ps


module master_axi_uart #(parameter nd = 20, b = $clog2(nd)) 
    (input clk, rst, start, output reg rec_trn,
    output reg [3:0] awadr, output reg awvalid, input awrdy,
    output [31:0] wdata, output reg wvalid, input wrdy,
    input [1:0] bdata, input bvalid, output reg brdy,
    output reg [3:0] aradr, output reg arvalid, input arrdy,
    input [31:0] rdata, input rvalid, output reg rrdy,
    output reg [7:0] received, output reg [b-1:0] dcnt, output reg wstb,
    input [7:0] transmit, output reg rstb);

typedef enum {idle, readstatus, waitstatus, read, waitread, write, waitwrite, waitresp} states;
states st, nst;

//Rx FIFO valid flag
wire rfifo_valid = (st == waitstatus & rvalid)?rdata[0]:1'b0;  
//Tx FIFO fukk flag      
wire tfifo_full = (st == waitstatus & rvalid)?rdata[3]:1'b0; 

//reg to distiguisz transmi and receive
always @(posedge clk, posedge rst)
    if(rst)
        rec_trn <= 1'b1;
    //else if (dcnt == 0)
      //  rec_trn <= 1'b1;
    else if (dcnt == nd)
        rec_trn <= 1'b0;

//state reg
always @(posedge clk, posedge rst)
    if(rst)
        st <= idle;
    else
        st <= nst;
        
 //next state logic       
 always @* begin
    nst = idle;
    case(st)
        idle: nst = start?readstatus:idle;
        readstatus: nst = waitstatus;
        waitstatus: 
                    if(rec_trn)
                        nst = rvalid?rfifo_valid?read:readstatus:waitstatus;
                    else
                        nst = rvalid?tfifo_full?readstatus:write:waitstatus;

        read: nst = waitread;
        waitread: nst = rvalid?readstatus:waitread;
        write: nst = waitwrite;
        waitwrite: nst = awrdy?waitresp:waitwrite;
        waitresp: nst = bvalid?(dcnt == 0)?idle:readstatus:waitresp;
    endcase
 end       

//transaction counter (memory ddres generator) and flags
wire inca = ((st == waitread) & rvalid & rec_trn);
wire deca = ((st == waitwrite) & wrdy & ~rec_trn);
always @(posedge clk)   //, posedge rst)
    if(rst)   
        dcnt <= {b{1'b0}};
    else if (inca)    //read
        dcnt <= dcnt + 1;
    else if (deca)    //write
        dcnt <= dcnt - 1;
    else if (st == idle)
        dcnt <= {b{1'b0}};
        
//Transmiter control
//-------------------------------------------------------
//channel AR
always @(posedge clk, posedge rst)
    if(rst)  
        aradr <= 4'b0;
    else if (st == readstatus)
        aradr <= 4'h8;
    else if (st == read)
        aradr <= 4'h0;   
always @(posedge clk, posedge rst)
    if(rst)         
        arvalid <= 1'b0;
    else if(st == read | st == readstatus)
        arvalid <= 1'b1;
    else if(arrdy)
        arvalid <= 1'b0;    

//channel R
always @(posedge clk, posedge rst)
    if(rst)        
        rrdy <= 1'b0;
    else if((st == waitstatus | st == waitread) & rvalid)
        rrdy <= 1'b1;  
    else //if(st == read | st == readstatus)
        rrdy <= 1'b0;  
always @(posedge clk, posedge rst)
    if(rst)
        received <= 8'b0;
    else if (inca)
        received <= rdata[7:0];
        
//memory write 
always @(posedge clk)   //, posedge rst)
    if(rst)
        wstb <= 1'b0;
    else 
        wstb <= inca;
        
//Receiver control       
//-------------------------------------------------------
//channel AW
always @(posedge clk, posedge rst)
    if(rst)  
        awadr <= 4'b0;
    else if (st == write | st == waitwrite)
        awadr <= 4'h4;
    else
        awadr <= 4'b0;
always @(posedge clk, posedge rst)
    if(rst)         
        awvalid <= 1'b0;
    else begin
        if(st == waitwrite)
            awvalid <= 1'b1;
        if(awrdy)
            awvalid <= 1'b0; 
        end

//channel W
always @(posedge clk, posedge rst)
    if(rst)         
        wvalid <= 1'b0;
    else begin
        if(st == waitwrite)
            wvalid <= 1'b1;
        if(awrdy)
            wvalid <= 1'b0; 
        end
assign wdata = (st == waitwrite)?{24'b0, transmit}:32'b0;

//channel B
always @(posedge clk, posedge rst)
    if(rst)        
        brdy <= 1'b0;
    else begin
        if (st == write)
            brdy <= 1'b1;  
        if (bvalid)
            brdy <= 1'b0;
        end

//memory read        
always @(posedge clk)   //, posedge rst)
    if(rst)
        rstb <= 1'b0;
    else 
        rstb <= (st == write);
                    
endmodule
