// BFS Parameters Package
// This file contains global parameters used throughout the BFS accelerator
// Include this file using: `include "bfs_params_pkg.v"

// Processing Unit (PU) parameters
`ifndef NUM_PU
  `define NUM_PU 16
`endif

// Data width parameters
`ifndef NODE_BITS
  `define NODE_BITS 32
`endif

`ifndef EDGE_BITS
  `define EDGE_BITS 16
`endif

// Queue depth
`ifndef QUEUE_DEPTH
  `define QUEUE_DEPTH 1024
`endif

// AXI4 Interface parameters
`ifndef AXI_ADDR_WIDTH
  `define AXI_ADDR_WIDTH 32
`endif

`ifndef AXI_DATA_WIDTH
  `define AXI_DATA_WIDTH 512
`endif

`ifndef AXI_ID_WIDTH
  `define AXI_ID_WIDTH 4
`endif

`ifndef AXI_USER_WIDTH
  `define AXI_USER_WIDTH 1
`endif
