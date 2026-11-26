# ============================================================================
# REALDIGITAL URBANA BOARD CONSTRAINTS V2I1 (1/3/2023)
# Target: AMD Spartan-7 XC7S50-CSGA324-1
# Project: 4-Digit Hex Digital Combination Lock with 8-Digit Display
# ============================================================================

# 100 MHz Master Oscillator Clock (Bank 14, MRCC)
set_property -dict {PACKAGE_PIN N15 IOSTANDARD LVCMOS33} [get_ports {CLK_100MHZ}]
create_clock -period 10.000 -name gclk [get_ports {CLK_100MHZ}]

# Set Configuration Voltage
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.Config.SPI_buswidth 4 [current_design]

# ============================================================================
# On-board Slide Switches (Bank 35, Active-High)
# ============================================================================
set_property -dict {PACKAGE_PIN G1 IOSTANDARD LVCMOS25} [get_ports {SW[0]}]
set_property -dict {PACKAGE_PIN F2 IOSTANDARD LVCMOS25} [get_ports {SW[1]}]
set_property -dict {PACKAGE_PIN F1 IOSTANDARD LVCMOS25} [get_ports {SW[2]}]
set_property -dict {PACKAGE_PIN E2 IOSTANDARD LVCMOS25} [get_ports {SW[3]}]
set_property -dict {PACKAGE_PIN E1 IOSTANDARD LVCMOS25} [get_ports {SW[4]}]
set_property -dict {PACKAGE_PIN D2 IOSTANDARD LVCMOS25} [get_ports {SW[5]}]
set_property -dict {PACKAGE_PIN D1 IOSTANDARD LVCMOS25} [get_ports {SW[6]}]
set_property -dict {PACKAGE_PIN C2 IOSTANDARD LVCMOS25} [get_ports {SW[7]}]
set_property -dict {PACKAGE_PIN B2 IOSTANDARD LVCMOS25} [get_ports {SW[8]}]
set_property -dict {PACKAGE_PIN A4 IOSTANDARD LVCMOS25} [get_ports {SW[9]}]
set_property -dict {PACKAGE_PIN A5 IOSTANDARD LVCMOS25} [get_ports {SW[10]}]
set_property -dict {PACKAGE_PIN A6 IOSTANDARD LVCMOS25} [get_ports {SW[11]}]
set_property -dict {PACKAGE_PIN C7 IOSTANDARD LVCMOS25} [get_ports {SW[12]}]
set_property -dict {PACKAGE_PIN A7 IOSTANDARD LVCMOS25} [get_ports {SW[13]}]
set_property -dict {PACKAGE_PIN B7 IOSTANDARD LVCMOS25} [get_ports {SW[14]}]
set_property -dict {PACKAGE_PIN A8 IOSTANDARD LVCMOS25} [get_ports {SW[15]}]

# ============================================================================
# On-board Discrete LEDs (Bank 14/15, Active-High)
# ============================================================================
set_property -dict {PACKAGE_PIN C13 IOSTANDARD LVCMOS33} [get_ports {LED[0]}]
set_property -dict {PACKAGE_PIN C14 IOSTANDARD LVCMOS33} [get_ports {LED[1]}]
set_property -dict {PACKAGE_PIN D14 IOSTANDARD LVCMOS33} [get_ports {LED[2]}]
set_property -dict {PACKAGE_PIN D15 IOSTANDARD LVCMOS33} [get_ports {LED[3]}]
set_property -dict {PACKAGE_PIN D16 IOSTANDARD LVCMOS33} [get_ports {LED[4]}]
set_property -dict {PACKAGE_PIN F18 IOSTANDARD LVCMOS33} [get_ports {LED[5]}]
set_property -dict {PACKAGE_PIN E17 IOSTANDARD LVCMOS33} [get_ports {LED[6]}]
set_property -dict {PACKAGE_PIN D17 IOSTANDARD LVCMOS33} [get_ports {LED[7]}]
set_property -dict {PACKAGE_PIN C17 IOSTANDARD LVCMOS33} [get_ports {LED[8]}]
set_property -dict {PACKAGE_PIN B18 IOSTANDARD LVCMOS33} [get_ports {LED[9]}]
set_property -dict {PACKAGE_PIN A17 IOSTANDARD LVCMOS33} [get_ports {LED[10]}]
set_property -dict {PACKAGE_PIN B17 IOSTANDARD LVCMOS33} [get_ports {LED[11]}]
set_property -dict {PACKAGE_PIN C18 IOSTANDARD LVCMOS33} [get_ports {LED[12]}]
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports {LED[13]}]
set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS33} [get_ports {LED[14]}]
set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS33} [get_ports {LED[15]}]

# ============================================================================
# On-board Push Buttons (Bank 35, Active-High)
# ============================================================================
set_property -dict {PACKAGE_PIN J2 IOSTANDARD LVCMOS25} [get_ports {BTN[0]}]
set_property -dict {PACKAGE_PIN J1 IOSTANDARD LVCMOS25} [get_ports {BTN[1]}]
set_property -dict {PACKAGE_PIN G2 IOSTANDARD LVCMOS25} [get_ports {BTN[2]}]
set_property -dict {PACKAGE_PIN H2 IOSTANDARD LVCMOS25} [get_ports {BTN[3]}]

# ============================================================================
# On-board RGB Color LEDs (Bank 16, Active-High)
# ============================================================================
set_property -dict {PACKAGE_PIN C9 IOSTANDARD LVCMOS33} [get_ports {RGB0[0]}];   # RGB0_R
set_property -dict {PACKAGE_PIN A9 IOSTANDARD LVCMOS33} [get_ports {RGB0[1]}];   # RGB0_G
set_property -dict {PACKAGE_PIN A10 IOSTANDARD LVCMOS33} [get_ports {RGB0[2]}];   # RGB0_B
set_property -dict {PACKAGE_PIN A11 IOSTANDARD LVCMOS33} [get_ports {RGB1[0]}];   # RGB1_R
set_property -dict {PACKAGE_PIN C10 IOSTANDARD LVCMOS33} [get_ports {RGB1[1]}];   # RGB1_G
set_property -dict {PACKAGE_PIN B11 IOSTANDARD LVCMOS33} [get_ports {RGB1[2]}];   # RGB1_B

# ============================================================================
# On-board 7-Segment Display Module 0 (Left Block: DISP0, Digits 7..4)
# ============================================================================
set_property -dict {PACKAGE_PIN G6 IOSTANDARD LVCMOS25} [get_ports {D0_AN[0]}];  # Active LOW (rightmost digit of block)
set_property -dict {PACKAGE_PIN H6 IOSTANDARD LVCMOS25} [get_ports {D0_AN[1]}];  # Active LOW
set_property -dict {PACKAGE_PIN C3 IOSTANDARD LVCMOS25} [get_ports {D0_AN[2]}];  # Active LOW
set_property -dict {PACKAGE_PIN B3 IOSTANDARD LVCMOS25} [get_ports {D0_AN[3]}];  # Active LOW (leftmost digit of block)

set_property -dict {PACKAGE_PIN E6 IOSTANDARD LVCMOS25} [get_ports {D0_SEG[0]}];  # CA Active LOW
set_property -dict {PACKAGE_PIN B4 IOSTANDARD LVCMOS25} [get_ports {D0_SEG[1]}];  # CB Active LOW
set_property -dict {PACKAGE_PIN D5 IOSTANDARD LVCMOS25} [get_ports {D0_SEG[2]}];  # CC Active LOW
set_property -dict {PACKAGE_PIN C5 IOSTANDARD LVCMOS25} [get_ports {D0_SEG[3]}];  # CD Active LOW
set_property -dict {PACKAGE_PIN D7 IOSTANDARD LVCMOS25} [get_ports {D0_SEG[4]}];  # CE Active LOW
set_property -dict {PACKAGE_PIN D6 IOSTANDARD LVCMOS25} [get_ports {D0_SEG[5]}];  # CF Active LOW
set_property -dict {PACKAGE_PIN C4 IOSTANDARD LVCMOS25} [get_ports {D0_SEG[6]}];  # CG Active LOW
set_property -dict {PACKAGE_PIN B5 IOSTANDARD LVCMOS25} [get_ports {D0_SEG[7]}];  # CDP Active LOW

# ============================================================================
# On-board 7-Segment Display Module 1 (Right Block: DISP1, Digits 3..0)
# ============================================================================
set_property -dict {PACKAGE_PIN E4 IOSTANDARD LVCMOS25} [get_ports {D1_AN[0]}];  # Active LOW (rightmost digit of block)
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS25} [get_ports {D1_AN[1]}];  # Active LOW
set_property -dict {PACKAGE_PIN F5 IOSTANDARD LVCMOS25} [get_ports {D1_AN[2]}];  # Active LOW
set_property -dict {PACKAGE_PIN H5 IOSTANDARD LVCMOS25} [get_ports {D1_AN[3]}];  # Active LOW (leftmost digit of block)

set_property -dict {PACKAGE_PIN F3 IOSTANDARD LVCMOS25} [get_ports {D1_SEG[0]}];  # CA Active LOW
set_property -dict {PACKAGE_PIN G5 IOSTANDARD LVCMOS25} [get_ports {D1_SEG[1]}];  # CB Active LOW
set_property -dict {PACKAGE_PIN J3 IOSTANDARD LVCMOS25} [get_ports {D1_SEG[2]}];  # CC Active LOW
set_property -dict {PACKAGE_PIN H4 IOSTANDARD LVCMOS25} [get_ports {D1_SEG[3]}];  # CD Active LOW
set_property -dict {PACKAGE_PIN F4 IOSTANDARD LVCMOS25} [get_ports {D1_SEG[4]}];  # CE Active LOW
set_property -dict {PACKAGE_PIN H3 IOSTANDARD LVCMOS25} [get_ports {D1_SEG[5]}];  # CF Active LOW
set_property -dict {PACKAGE_PIN E5 IOSTANDARD LVCMOS25} [get_ports {D1_SEG[6]}];  # CG Active LOW
set_property -dict {PACKAGE_PIN J4 IOSTANDARD LVCMOS25} [get_ports {D1_SEG[7]}];  # CDP Active LOW

# ============================================================================
# Timing Constraints: False paths on asynchronous I/O
# ============================================================================
set_false_path -from [get_ports {SW[*]}]
set_false_path -from [get_ports {BTN[*]}]
set_false_path -to   [get_ports {LED[*]}]
set_false_path -to   [get_ports {RGB0[*]}]
set_false_path -to   [get_ports {RGB1[*]}]
set_false_path -to   [get_ports {D0_AN[*]}]
set_false_path -to   [get_ports {D0_SEG[*]}]
set_false_path -to   [get_ports {D1_AN[*]}]
set_false_path -to   [get_ports {D1_SEG[*]}]

# ============================================================================
# Bitstream Generation Options
# ============================================================================
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLDOWN [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
