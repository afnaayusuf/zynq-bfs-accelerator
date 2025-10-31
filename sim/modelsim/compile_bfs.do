# ModelSim Compilation Script for BFS Accelerator
# =================================================
# Run this in ModelSim: do compile_bfs.do

# Create work library
vlib work
vmap work work

# Compile packages first
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/packages/bfs_params_pkg.v

# Compile interfaces
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/interfaces/axi4_if.v
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/interfaces/axi4_lite_if.v

# Compile processing units
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/processing_units/pu_work_queue.v
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/processing_units/processing_unit.v

# Compile distribution subsystem
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/distribution/crossbar_switch.v
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/distribution/threshold_calculator.v
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/distribution/work_stealing_scheduler.v
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/distribution/work_distributor.v

# Compile memory subsystem
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/memory/bitmask_storage.v
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/memory/burst_controller.v
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/memory/memory_arbiter.v
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/memory/node_fetcher.v
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/memory/visited_checker.v
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/memory/visited_manager.v

# Compile buffer subsystem
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/buffers/fifo_with_spill.v
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/buffers/prefetch_buffer.v
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/buffers/smart_buffer_manager.v

# Compile celebrity handling
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/celebrity/celebrity_detector.v
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/celebrity/work_preallocator.v
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/celebrity/celebrity_handler.v

# Compile control subsystem
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/control/config_regs.v
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/control/status_regs.v
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/control/csr_module.v

# Compile interconnect
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/interconnect/axi_interconnect.v

# Compile lookahead engine
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/lookahead/lookahead_stats_engine.v

# Compile top-level modules
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/top/main_execution_engine.v
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/top/bfs_system_integrated.v
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../../rtl/top/bfs_accelerator_top.v

# Compile testbench
vlog -work work +incdir+../../rtl/packages +incdir+../../rtl ../iverilog/bfs_system_complete_tb.v

echo "Compilation complete!"
