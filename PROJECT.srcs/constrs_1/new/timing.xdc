

create_clock -name clk100MHz -period 10 [get_ports clk] 
#create_generated_clock -name divclk -source [get_ports clk] -divide_by 100000000 [get_nets slowclk]