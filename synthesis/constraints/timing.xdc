# Timing Constraints for BFS Accelerator on PYNQ-Z2
# Target Device: XC7Z020-1CLG484C
# Clock: 100 MHz from Zynq PS

# Primary clock constraint (100 MHz from Zynq PS)
create_clock -period 10.000 -name clk [get_ports clk]

# Input delay constraints (assuming AXI signals come from PS)
set_input_delay -clock clk -max 2.0 [get_ports {s_axi_lite_*}]
set_input_delay -clock clk -min 0.5 [get_ports {s_axi_lite_*}]

set_input_delay -clock clk -max 2.0 [get_ports {m_axi_*}]
set_input_delay -clock clk -min 0.5 [get_ports {m_axi_*}]

# Output delay constraints
set_output_delay -clock clk -max 2.0 [get_ports {s_axi_lite_*}]
set_output_delay -clock clk -min 0.5 [get_ports {s_axi_lite_*}]

set_output_delay -clock clk -max 2.0 [get_ports {m_axi_*}]
set_output_delay -clock clk -min 0.5 [get_ports {m_axi_*}]

set_output_delay -clock clk -max 2.0 [get_ports global_done]
set_output_delay -clock clk -min 0.5 [get_ports global_done]

# Reset is asynchronous but should be synchronized
set_false_path -from [get_ports rst_n]

# Multi-cycle paths for memory operations (if needed)
# set_multicycle_path -setup 2 -from [get_cells memory_path] -to [get_cells next_stage]

# Critical path optimization
set_max_delay 8.0 -from [get_cells processing_units/*] -to [get_cells visited_manager/*]
