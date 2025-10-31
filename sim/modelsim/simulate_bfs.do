# ModelSim Simulation Script for BFS Accelerator
# ================================================
# Run after compile_bfs.do

# Load simulation
vsim -voptargs=+acc work.bfs_system_complete_tb

# Configure waveform display
add wave -divider "Clock and Reset"
add wave -radix binary sim:/bfs_system_complete_tb/aclk
add wave -radix binary sim:/bfs_system_complete_tb/aresetn

add wave -divider "AXI-Lite Control Interface"
add wave -radix hex sim:/bfs_system_complete_tb/s_axi_awaddr
add wave -radix hex sim:/bfs_system_complete_tb/s_axi_wdata
add wave -radix binary sim:/bfs_system_complete_tb/s_axi_awvalid
add wave -radix binary sim:/bfs_system_complete_tb/s_axi_awready
add wave -radix binary sim:/bfs_system_complete_tb/s_axi_wvalid
add wave -radix binary sim:/bfs_system_complete_tb/s_axi_wready

add wave -divider "AXI-Lite Read Interface"
add wave -radix hex sim:/bfs_system_complete_tb/s_axi_araddr
add wave -radix hex sim:/bfs_system_complete_tb/s_axi_rdata
add wave -radix binary sim:/bfs_system_complete_tb/s_axi_arvalid
add wave -radix binary sim:/bfs_system_complete_tb/s_axi_arready
add wave -radix binary sim:/bfs_system_complete_tb/s_axi_rvalid
add wave -radix binary sim:/bfs_system_complete_tb/s_axi_rready

add wave -divider "AXI4 Memory Interface"
add wave -radix hex sim:/bfs_system_complete_tb/m_axi_araddr
add wave -radix unsigned sim:/bfs_system_complete_tb/m_axi_arlen
add wave -radix binary sim:/bfs_system_complete_tb/m_axi_arvalid
add wave -radix binary sim:/bfs_system_complete_tb/m_axi_arready
add wave -radix hex sim:/bfs_system_complete_tb/m_axi_rdata
add wave -radix binary sim:/bfs_system_complete_tb/m_axi_rvalid
add wave -radix binary sim:/bfs_system_complete_tb/m_axi_rready
add wave -radix binary sim:/bfs_system_complete_tb/m_axi_rlast

add wave -divider "BFS Status"
add wave -radix binary sim:/bfs_system_complete_tb/interrupt

add wave -divider "Internal DUT Signals (optional)"
# Uncomment these if you want to see internal signals
# add wave -radix hex sim:/bfs_system_complete_tb/dut/*

# Configure waveform window
wave zoom full

# Run simulation
run 500 us

# Zoom to fit data
wave zoom full

echo "Simulation complete. Check waveform and console output."
