`timescale 1ns / 1ps

//============================================================================
// BFS System Integrated - WITH REAL BFS ENGINE
//============================================================================
// This version instantiates a real BFS engine that:
// - Reads graph from memory
// - Tracks visited nodes
// - Computes distances and parents
// - Shows actual BFS traversal in waveforms
//============================================================================

module bfs_system_integrated #(
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_DATA_WIDTH = 64
) (
    // Clock and Reset
    input  wire                                   clk,
    input  wire                                   rst_n,
    
    // AXI4-Lite Interface for CSR
    input  wire                                   s_axi_lite_awvalid,
    input  wire [AXI_ADDR_WIDTH-1:0]             s_axi_lite_awaddr,
    output wire                                   s_axi_lite_awready,
    input  wire                                   s_axi_lite_wvalid,
    input  wire [31:0]                           s_axi_lite_wdata,
    input  wire [3:0]                              s_axi_lite_wstrb,
    output wire                                   s_axi_lite_wready,
    output wire                                   s_axi_lite_bvalid,
    output wire [1:0]                             s_axi_lite_bresp,
    input  wire                                   s_axi_lite_bready,
    input  wire                                   s_axi_lite_arvalid,
    input  wire [AXI_ADDR_WIDTH-1:0]             s_axi_lite_araddr,
    output wire                                   s_axi_lite_arready,
    output wire                                   s_axi_lite_rvalid,
    output wire [31:0]                           s_axi_lite_rdata,
    output wire [1:0]                             s_axi_lite_rresp,
    input  wire                                   s_axi_lite_rready,

    // AXI4 Interface for Memory
    output wire [AXI_ADDR_WIDTH-1:0]             m_axi_araddr,
    output wire [7:0]                               m_axi_arlen,
    output wire                                   m_axi_arvalid,
    input  wire                                   m_axi_arready,
    input  wire [AXI_DATA_WIDTH-1:0]             m_axi_rdata,
    input  wire                                   m_axi_rlast,
    input  wire [1:0]                              m_axi_rresp,
    input  wire                                   m_axi_rvalid,
    output wire                                   m_axi_rready,
    
    output wire                                   global_done
);

//============================================================================
// Internal Signals
//============================================================================

// Control signals from CSR
wire start_bfs;
wire [31:0] start_node_id;
wire [31:0] graph_base_addr;

// Status signals to CSR
wire bfs_done;
wire bfs_busy;
wire incr_edge_signal;

// BFS Engine signals
wire [31:0] current_node_processing;
wire [31:0] current_bfs_level;
wire [31:0] last_discovered_node;
wire node_discovered_pulse;
wire [31:0] nodes_visited;
wire [31:0] edges_scanned;

// Memory interface between BFS engine and AXI
wire [31:0] bfs_mem_addr;
wire bfs_mem_rd_en;
reg [31:0] bfs_mem_data;
reg bfs_mem_valid;

// Edge detection for start signal
reg start_bfs_prev;
wire start_bfs_edge;
assign start_bfs_edge = start_bfs && !start_bfs_prev;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        start_bfs_prev <= 1'b0;
    else
        start_bfs_prev <= start_bfs;
end

//============================================================================
// CSR Module Instance
//============================================================================
csr_module #(
    .AXI_ADDR_WIDTH(12),
    .AXI_DATA_WIDTH(32)
) csr_inst (
    .s_axi_clk(clk),
    .s_axi_rst_n(rst_n),
    
    // AXI-Lite Interface
    .s_axi_awaddr(s_axi_lite_awaddr[11:0]),
    .s_axi_awvalid(s_axi_lite_awvalid),
    .s_axi_awready(s_axi_lite_awready),
    .s_axi_wdata(s_axi_lite_wdata),
    .s_axi_wstrb(s_axi_lite_wstrb),
    .s_axi_wvalid(s_axi_lite_wvalid),
    .s_axi_wready(s_axi_lite_wready),
    .s_axi_bresp(s_axi_lite_bresp),
    .s_axi_bvalid(s_axi_lite_bvalid),
    .s_axi_bready(s_axi_lite_bready),
    .s_axi_araddr(s_axi_lite_araddr[11:0]),
    .s_axi_arvalid(s_axi_lite_arvalid),
    .s_axi_arready(s_axi_lite_arready),
    .s_axi_rdata(s_axi_lite_rdata),
    .s_axi_rresp(s_axi_lite_rresp),
    .s_axi_rvalid(s_axi_lite_rvalid),
    .s_axi_rready(s_axi_lite_rready),
    
    // Control outputs
    .start_node_address(start_node_id),
    .graph_base_address(graph_base_addr),
    .high_degree_threshold(),  // Not used in simulation
    .medium_degree_threshold(), // Not used in simulation
    .control_reg_start(start_bfs),
    
    // Status inputs
    .busy(bfs_busy),
    .done(bfs_done),
    .incr_traversed_edges(incr_edge_signal),
    
    // Lookahead Engine ports (not used)
    .lse_threshold_we(1'b0),
    .lse_high_degree_in(32'h0),
    .lse_medium_degree_in(32'h0)
);

//============================================================================
// REAL BFS Engine Instance
//============================================================================
bfs_engine_simple #(
    .NUM_NODES(32),
    .MAX_NEIGHBORS(16)
) bfs_engine (
    .clk(clk),
    .rst_n(rst_n),
    
    // Control
    .start(start_bfs_edge),
    .start_node_id(start_node_id),
    .done(bfs_done),
    .busy(bfs_busy),
    
    // Memory interface
    .mem_addr(bfs_mem_addr),
    .mem_rd_en(bfs_mem_rd_en),
    .mem_data(bfs_mem_data),
    .mem_valid(bfs_mem_valid),
    
    // Statistics
    .nodes_visited_count(nodes_visited),
    .edges_scanned_count(edges_scanned),
    .incr_edge_pulse(incr_edge_signal),
    
    // Path tracking (for waveform viewing)
    .current_node_processing(current_node_processing),
    .current_level(current_bfs_level),
    .last_discovered_node(last_discovered_node),
    .node_discovered_pulse(node_discovered_pulse)
);

//============================================================================
// Memory Interface - Connect BFS Engine to AXI4 Memory
//============================================================================
// Simple adapter: when BFS engine requests memory read, translate to AXI

reg [1:0] mem_state;
reg [31:0] mem_addr_latched;
localparam MEM_IDLE = 2'd0;
localparam MEM_REQ  = 2'd1;
localparam MEM_WAIT = 2'd2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mem_state <= MEM_IDLE;
        bfs_mem_valid <= 1'b0;
        bfs_mem_data <= 32'd0;
        mem_addr_latched <= 32'd0;
    end else begin
        case (mem_state)
            MEM_IDLE: begin
                bfs_mem_valid <= 1'b0;
                if (bfs_mem_rd_en) begin
                    mem_addr_latched <= bfs_mem_addr;  // Latch the address!
                    mem_state <= MEM_REQ;
                    $display("[%0t] Memory: BFS engine requests addr=0x%h", $time, bfs_mem_addr);
                end
            end
            
            MEM_REQ: begin
                // Wait for AXI address handshake
                if (m_axi_arready) begin
                    mem_state <= MEM_WAIT;
                    $display("[%0t] Memory: AXI address handshake complete, addr on bus=0x%h", $time, m_axi_araddr);
                end
            end
            
            MEM_WAIT: begin
                // Wait for AXI data response
                if (m_axi_rvalid) begin
                    bfs_mem_data <= m_axi_rdata[31:0];  // Take lower 32 bits
                    bfs_mem_valid <= 1'b1;
                    mem_state <= MEM_IDLE;
                    $display("[%0t] Memory: Data received = 0x%h", $time, m_axi_rdata[31:0]);
                end
            end
            
            default: mem_state <= MEM_IDLE;
        endcase
    end
end

//============================================================================
// AXI4 Memory Interface
//============================================================================
assign m_axi_araddr = mem_addr_latched[AXI_ADDR_WIDTH-1:0];
assign m_axi_arlen = 8'd0;  // Single transfer
assign m_axi_arvalid = (mem_state == MEM_REQ) ? 1'b1 : 1'b0;
assign m_axi_rready = 1'b1;  // Always ready

//============================================================================
// Global Done Output
//============================================================================
assign global_done = bfs_done;

endmodule
