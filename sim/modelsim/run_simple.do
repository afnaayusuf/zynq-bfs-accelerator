# ModelSim Simulation Script - Run BFS Testbench
# ================================================

# Load the testbench
vsim -voptargs=+acc work.bfs_system_complete_tb

# Add waveforms
add wave -radix hex sim:/bfs_system_complete_tb/*
add wave -radix hex sim:/bfs_system_complete_tb/dut/*
add wave -radix hex sim:/bfs_system_complete_tb/dut/csr_inst/*

# Run simulation for 50 microseconds
run 50us

echo "Simulation complete! Check waveforms and transcript output."
