# ModelSim Compilation Script - Minimal for Testbench
# ==================================================
# Run this in ModelSim: do compile_simple.do

# Create work library
vlib work
vmap work work

# Compile control subsystem (only what's needed)
vlog -work work ../../rtl/control/config_regs.v
vlog -work work ../../rtl/control/status_regs.v
vlog -work work ../../rtl/control/csr_module.v
vlog -work work ../../rtl/interfaces/axi4_lite_if.v

# Compile BFS engine
vlog -work work ../../rtl/top/bfs_engine_simple.v

# Compile top-level integration
vlog -work work ../../rtl/top/bfs_system_integrated.v

# Compile testbench
vlog -work work ../../sim/iverilog/bfs_system_complete_tb.v

echo "Compilation complete! Run simulation with: vsim -voptargs=+acc work.bfs_system_complete_tb"
