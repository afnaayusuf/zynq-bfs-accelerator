// Icarus Verilog File List for BFS Accelerator System Simulation
// ================================================================

// Package files (must be first)
../../rtl/packages/bfs_params_pkg.v

// Interface definitions
../../rtl/interfaces/axi4_if.v
../../rtl/interfaces/axi4_lite_if.v

// Processing Units
../../rtl/processing_units/pu_work_queue.v
../../rtl/processing_units/processing_unit.v

// Distribution subsystem
../../rtl/distribution/crossbar_switch.v
../../rtl/distribution/threshold_calculator.v
../../rtl/distribution/work_stealing_scheduler.v
../../rtl/distribution/work_distributor.v

// Memory subsystem
../../rtl/memory/bitmask_storage.v
../../rtl/memory/burst_controller.v
../../rtl/memory/memory_arbiter.v
../../rtl/memory/node_fetcher.v
../../rtl/memory/visited_checker.v
../../rtl/memory/visited_manager.v

// Buffer subsystem
../../rtl/buffers/fifo_with_spill.v
../../rtl/buffers/prefetch_buffer.v
../../rtl/buffers/smart_buffer_manager.v

// Celebrity handling
../../rtl/celebrity/celebrity_detector.v
../../rtl/celebrity/work_preallocator.v
../../rtl/celebrity/celebrity_handler.v

// Control subsystem
../../rtl/control/config_regs.v
../../rtl/control/status_regs.v
../../rtl/control/csr_module.v

// Interconnect
../../rtl/interconnect/axi_interconnect.v

// Lookahead engine
../../rtl/lookahead/lookahead_stats_engine.v

// Top-level modules
../../rtl/top/main_execution_engine.v
../../rtl/top/bfs_system_integrated.v
../../rtl/top/bfs_accelerator_top.v

// Testbench
bfs_system_complete_tb.v
