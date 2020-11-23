`timescale 1ns / 1ps





// zmiana zegara z 100Mhz na 1Hz
module clkdiv #(parameter div = 100000000) (input clk, rst, output reg slowclk);

    localparam nb = $clog2(div);
    reg[nb-1:0] cnt;
    always @(posedge clk, posedge rst)
        if (rst)
            cnt <= {nb{1'b0}};
        else if (cnt == {nb{1'b0}})
            cnt <= div;
        else
            cnt <= cnt - 1'b1;
            
     always @(posedge clk, posedge rst)
                if (rst)
                   slowclk <= 1'b0;
                else if (cnt == {nb{1'b0}})
                   slowclk <= ~slowclk;
endmodule


