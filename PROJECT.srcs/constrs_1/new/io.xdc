
set_property PACKAGE_PIN Y11  [get_ports {wire3rst}];  # "JA1"
set_property PACKAGE_PIN AA11 [get_ports {wire3clk}];  # "JA2"
set_property PACKAGE_PIN Y10  [get_ports {wire3dq}];  # "JA3"

set_property PACKAGE_PIN V10 [get_ports {tx}];  # "JB3"
set_property PACKAGE_PIN W8 [get_ports {rx}];  # "JB4"



set_property PACKAGE_PIN T22 [get_ports {dataOut[0]}];  # "LD0"
set_property PACKAGE_PIN T21 [get_ports {dataOut[1]}];  # "LD1"
set_property PACKAGE_PIN U22 [get_ports {dataOut[2]}];  # "LD2"
set_property PACKAGE_PIN U21 [get_ports {dataOut[3]}];  # "LD3"
set_property PACKAGE_PIN V22 [get_ports {dataOut[4]}];  # "LD4"
set_property PACKAGE_PIN W22 [get_ports {dataOut[5]}];  # "LD5"
set_property PACKAGE_PIN U19 [get_ports {dataOut[6]}];  # "LD6"
set_property PACKAGE_PIN U14 [get_ports {dataOut[7]}];  # "LD7"

set_property PACKAGE_PIN Y4  [get_ports {dataOut[8]}];  # "JC2_P"


set_property PACKAGE_PIN R16 [get_ports {rst}];  # "BTND"
set_property PACKAGE_PIN T18 [get_ports {start}];  # "BTNU"


set_property PACKAGE_PIN Y9 [get_ports {clk}];  # "GCLK"

set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 13]];
set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 34]];
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 33]];

