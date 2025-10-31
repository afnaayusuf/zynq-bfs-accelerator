
# Vivado Tcl script for synthesizing the BFS accelerator

# Set the target FPGA device
set_part xc7z020clg484-1

# Read the Verilog files
read_verilog -sv [glob ../../rtl/packages/bfs_params_pkg.v]
read_verilog [glob ../../rtl/interfaces/*.v]
read_verilog [glob ../../rtl/processing_units/*.v]
read_verilog [glob ../../rtl/distribution/*.v]
read_verilog [glob ../../rtl/memory/*.v]
read_verilog [glob ../../rtl/buffers/*.v]
read_verilog [glob ../../rtl/celebrity/*.v]
read_verilog [glob ../../rtl/control/*.v]
read_verilog [glob ../../rtl/top/*.v]

# Set the top-level module
set_property top bfs_system_integrated [current_fileset]

# Read the constraints
read_xdc ../synthesis/constraints/constraints.xdc

# Run synthesis
synth_design -top bfs_system_integrated -part xc7z020clg484-1

# Write the synthesis report
report_timing_summary -file synthesis_timing_summary.rpt
report_utilization -file synthesis_utilization.rpt

# Write the netlist
write_verilog -mode synth_stub synthesis_netlist.v
