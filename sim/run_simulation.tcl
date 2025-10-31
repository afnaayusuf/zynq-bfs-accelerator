
# ModelSim/Vivado Tcl script for running the BFS accelerator simulation

# Create a work library
vlib work

# Compile the Verilog files
vlog -work work +incdir+../../rtl/packages/ ../../rtl/packages/bfs_params_pkg.v
vlog -work work +incdir+../../rtl/interfaces/ ../../rtl/interfaces/axi4_if.v
vlog -work work +incdir+../../rtl/interfaces/ ../../rtl/interfaces/axi4_lite_if.v
vlog -work work +incdir+../../rtl/processing_units/ ../../rtl/processing_units/pu_work_queue.v
vlog -work work +incdir+../../rtl/processing_units/ ../../rtl/processing_units/processing_unit.v
vlog -work work +incdir+../../rtl/distribution/ ../../rtl/distribution/crossbar_switch.v
vlog -work work +incdir+../../rtl/distribution/ ../../rtl/distribution/threshold_calculator.v
vlog -work work +incdir+../../rtl/distribution/ ../../rtl/distribution/work_stealing_scheduler.v
vlog -work work +incdir+../../rtl/distribution/ ../../rtl/distribution/work_distributor.v
vlog -work work +incdir+../../rtl/memory/ ../../rtl/memory/bitmask_storage.v
vlog -work work +incdir+../../rtl/memory/ ../../rtl/memory/burst_controller.v
vlog -work work +incdir+../../rtl/memory/ ../../rtl/memory/memory_arbiter.v
vlog -work work +incdir+../../rtl/memory/ ../../rtl/memory/node_fetcher.v
vlog -work work +incdir+../../rtl/memory/ ../../rtl/memory/visited_checker.v
vlog -work work +incdir+../../rtl/memory/ ../../rtl/memory/visited_manager.v
vlog -work work +incdir+../../rtl/buffers/ ../../rtl/buffers/fifo_with_spill.v
vlog -work work +incdir+../../rtl/buffers/ ../../rtl/buffers/prefetch_buffer.v
vlog -work work +incdir+../../rtl/buffers/ ../../rtl/buffers/smart_buffer_manager.v
vlog -work work +incdir+../../rtl/celebrity/ ../../rtl/celebrity/celebrity_detector.v
vlog -work work +incdir+../../rtl/celebrity/ ../../rtl/celebrity/work_preallocator.v
vlog -work work +incdir+../../rtl/celebrity/ ../../rtl/celebrity/celebrity_handler.v
vlog -work work +incdir+../../rtl/control/ ../../rtl/control/config_regs.v
vlog -work work +incdir+../../rtl/control/ ../../rtl/control/status_regs.v
vlog -work work +incdir+../../rtl/control/ ../../rtl/control/csr_module.v
vlog -work work +incdir+../../rtl/top/ ../../rtl/top/bfs_accelerator_top.v
vlog -work work +incdir+../../rtl/top/ ../../rtl/top/bfs_system_integrated.v

# Compile the testbenches
vlog -work work ../../tb/unit/interconnect_tb.v
vlog -work work ../../tb/system/system_tb.v

# Start the simulation
vsim -c work.system_tb

# Add waves
add wave -r /*

# Run the simulation
run -all
