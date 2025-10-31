# ModelSim Waveform Viewing Script for BFS Accelerator
# ========================================================
# This script sets up the waveform viewer with meaningful signals
# Run this after compile_simple.do

# Compile the design
do compile_simple.do

# Load the testbench
vsim -voptargs=+acc work.bfs_system_complete_tb

# Configure wave window
view wave
delete wave *

# ==============================================================================
# GROUP 1: Clock and Reset
# ==============================================================================
add wave -noupdate -divider "Clock & Reset"
add wave -noupdate -color Yellow /bfs_system_complete_tb/aclk
add wave -noupdate -color Orange /bfs_system_complete_tb/aresetn

# ==============================================================================
# GROUP 2: BFS State Machine (MOST IMPORTANT!)
# ==============================================================================
add wave -noupdate -divider "BFS State Machine"
add wave -noupdate -color Cyan -radix ascii /bfs_system_complete_tb/state_name
add wave -noupdate -color "Medium Blue" -radix unsigned /bfs_system_complete_tb/bfs_state_internal
add wave -noupdate -color Green /bfs_system_complete_tb/bfs_busy_internal
add wave -noupdate -color Green /bfs_system_complete_tb/bfs_done_internal
add wave -noupdate -color Magenta /bfs_system_complete_tb/interrupt

# ==============================================================================
# GROUP 3: BFS Progress Indicators (KEY SIGNALS TO WATCH!)
# ==============================================================================
add wave -noupdate -divider "BFS Progress"
add wave -noupdate -color White -radix unsigned /bfs_system_complete_tb/current_node_id
add wave -noupdate -color Yellow -radix unsigned /bfs_system_complete_tb/nodes_visited_internal
add wave -noupdate -color Orange -radix unsigned /bfs_system_complete_tb/edges_scanned_internal
add wave -noupdate -color Cyan -radix unsigned /bfs_system_complete_tb/current_level_internal
add wave -noupdate -color Green -radix unsigned /bfs_system_complete_tb/bfs_progress_percent

# ==============================================================================
# GROUP 4: Event Pulses (Shows Activity!)
# ==============================================================================
add wave -noupdate -divider "Event Pulses"
add wave -noupdate -color Red /bfs_system_complete_tb/node_visited_event
add wave -noupdate -color Pink /bfs_system_complete_tb/edge_processed
add wave -noupdate -color Yellow /bfs_system_complete_tb/level_changed
add wave -noupdate -color Orange /bfs_system_complete_tb/incr_edge_pulse

# ==============================================================================
# GROUP 5: AXI Activity Indicators
# ==============================================================================
add wave -noupdate -divider "AXI Activity"
add wave -noupdate -color "Medium Blue" /bfs_system_complete_tb/axi_write_active
add wave -noupdate -color "Medium Blue" /bfs_system_complete_tb/axi_read_active
add wave -noupdate -color Violet /bfs_system_complete_tb/mem_read_active

# ==============================================================================
# GROUP 6: Control/Status Registers
# ==============================================================================
add wave -noupdate -divider "CSR Interface"
add wave -noupdate -radix hex /bfs_system_complete_tb/s_axi_awaddr
add wave -noupdate /bfs_system_complete_tb/s_axi_awvalid
add wave -noupdate -radix hex /bfs_system_complete_tb/s_axi_wdata
add wave -noupdate -radix hex /bfs_system_complete_tb/s_axi_araddr
add wave -noupdate /bfs_system_complete_tb/s_axi_arvalid
add wave -noupdate -radix hex /bfs_system_complete_tb/s_axi_rdata
add wave -noupdate /bfs_system_complete_tb/status_busy
add wave -noupdate /bfs_system_complete_tb/status_done

# ==============================================================================
# GROUP 7: Internal DUT Signals
# ==============================================================================
add wave -noupdate -divider "DUT Internal"
add wave -noupdate -radix unsigned /bfs_system_complete_tb/dut/sim_counter
add wave -noupdate -radix unsigned /bfs_system_complete_tb/dut/edges_to_add
add wave -noupdate /bfs_system_complete_tb/dut/start_bfs
add wave -noupdate /bfs_system_complete_tb/dut/start_bfs_edge

# Configure wave window layout
configure wave -namecolwidth 250
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns

# Run simulation
run 10us

# Zoom to show the interesting part (BFS execution)
wave zoom range 0ns 8us

# Print instructions
echo ""
echo "=============================================================="
echo "  BFS ACCELERATOR WAVEFORM VIEWER"
echo "=============================================================="
echo "  KEY SIGNALS TO WATCH:"
echo ""
echo "  1. state_name          - Shows IDLE/INIT/PROCESS/DONE"
echo "  2. current_node_id     - Which node is being processed"
echo "  3. nodes_visited       - Count of visited nodes (0→32)"
echo "  4. edges_scanned       - Count of edges scanned (0→140)"
echo "  5. node_visited_event  - Pulses HIGH when new node visited"
echo "  6. edge_processed      - Pulses HIGH when edge scanned"
echo "  7. bfs_progress_percent - Shows 0%→100% completion"
echo ""
echo "  WHAT TO LOOK FOR:"
echo "  - State transitions: IDLE → INIT → PROCESS → DONE"
echo "  - node_visited_event pulses as nodes are discovered"
echo "  - edge_processed pulses 140 times (once per edge)"
echo "  - nodes_visited_internal counts from 0 to 32"
echo "  - edges_scanned_internal counts from 0 to 140"
echo "  - interrupt asserts HIGH when BFS completes"
echo ""
echo "=============================================================="
echo ""
