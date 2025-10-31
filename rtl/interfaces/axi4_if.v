// axi4_if.v
// NOTE: This file contains AXI4 interface documentation.
// SystemVerilog 'interface' construct is not supported in Verilog-2001.
// When using AXI4 in modules, declare explicit ports instead.
//
// AXI4 Full Interface Signal Reference:
// 
// Write Address Channel:
//   AWID     - Write address ID
//   AWADDR   - Write address
//   AWLEN    - Burst length
//   AWSIZE   - Burst size
//   AWBURST  - Burst type
//   AWLOCK   - Lock type
//   AWCACHE  - Memory type
//   AWPROT   - Protection type
//   AWVALID  - Write address valid
//   AWREADY  - Write address ready
//   AWUSER   - User signal
//
// Write Data Channel:
//   WDATA    - Write data
//   WSTRB    - Write strobes
//   WLAST    - Write last
//   WVALID   - Write valid
//   WREADY   - Write ready
//   WUSER    - User signal
//
// Write Response Channel:
//   BID      - Response ID
//   BRESP    - Write response
//   BVALID   - Write response valid
//   BREADY   - Response ready
//   BUSER    - User signal
//
// Read Address Channel:
//   ARID     - Read address ID
//   ARADDR   - Read address
//   ARLEN    - Burst length
//   ARSIZE   - Burst size
//   ARBURST  - Burst type
//   ARLOCK   - Lock type
//   ARCACHE  - Memory type
//   ARPROT   - Protection type
//   ARVALID  - Read address valid
//   ARREADY  - Read address ready
//   ARUSER   - User signal
//
// Read Data Channel:
//   RID      - Read ID tag
//   RDATA    - Read data
//   RRESP    - Read response
//   RLAST    - Read last
//   RVALID   - Read valid
//   RREADY   - Read ready
//   RUSER    - User signal

// End of AXI4 interface documentation
