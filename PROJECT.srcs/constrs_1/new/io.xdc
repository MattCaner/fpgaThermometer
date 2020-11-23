


set_property PACKAGE_PIN R16 [get_ports {rst}];  # "BTND"
set_property PACKAGE_PIN T18 [get_ports {start}];  # "BTNU"


set_property PACKAGE_PIN Y9 [get_ports {clk}];  # "GCLK"

set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 13]];
set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 34]];
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 33]];

