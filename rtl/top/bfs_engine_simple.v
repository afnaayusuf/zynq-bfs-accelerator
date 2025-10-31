// Simplified BFS Engine for ModelSim Simulation
// Pure Verilog-2001 compatible
// Shows actual node-by-node BFS traversal with path tracking

`timescale 1ns / 1ps

module bfs_engine_simple #(
    parameter NUM_NODES = 32,
    parameter MAX_NEIGHBORS = 16
) (
    input wire clk,
    input wire rst_n,
    
    // Control
    input wire start,
    input wire [31:0] start_node_id,
    output reg done,
    output reg busy,
    
    // Memory interface (for reading graph)
    output reg [31:0] mem_addr,
    output reg mem_rd_en,
    input wire [31:0] mem_data,
    input wire mem_valid,
    
    // Statistics outputs
    output reg [31:0] nodes_visited_count,
    output reg [31:0] edges_scanned_count,
    output wire incr_edge_pulse,
    
    // Path tracking outputs (for waveform viewing)
    output reg [31:0] current_node_processing,
    output reg [31:0] current_level,
    output reg [31:0] last_discovered_node,
    output reg node_discovered_pulse
);

    // BFS State Machine
    localparam [2:0] IDLE           = 3'd0;
    localparam [2:0] INIT           = 3'd1;
    localparam [2:0] FETCH_NODE     = 3'd2;
    localparam [2:0] PROCESS_NODE   = 3'd3;
    localparam [2:0] CHECK_NEIGHBOR = 3'd4;
    localparam [2:0] NEXT_LEVEL     = 3'd5;
    localparam [2:0] DONE_STATE     = 3'd6;
    
    reg [2:0] state, next_state;
    
    // Visited bitmap (1 bit per node)
    reg [NUM_NODES-1:0] visited_bitmap;
    
    // Distance array (BFS level for each node)
    reg [7:0] distance [0:NUM_NODES-1];
    
    // Parent array (for path reconstruction)
    reg [31:0] parent [0:NUM_NODES-1];
    
    // Queue implementation (simple FIFO)
    reg [31:0] queue [0:NUM_NODES-1];
    reg [5:0] queue_head, queue_tail;
    reg queue_empty, queue_full;
    
    // Processing variables
    reg [31:0] current_node;
    reg [7:0] current_neighbor_idx;
    reg [7:0] num_neighbors;
    reg [31:0] neighbor_id;
    reg [31:0] mem_read_buffer [0:MAX_NEIGHBORS-1];
    
    // Edge increment pulse
    reg edge_pulse;
    assign incr_edge_pulse = edge_pulse;
    
    integer i;
    
    // Queue management
    always @(*) begin
        queue_empty = (queue_head == queue_tail) && !queue_full;
    end
    
    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            busy <= 1'b0;
            done <= 1'b0;
            nodes_visited_count <= 32'd0;
            edges_scanned_count <= 32'd0;
            current_level <= 32'd0;
            visited_bitmap <= {NUM_NODES{1'b0}};
            queue_head <= 6'd0;
            queue_tail <= 6'd0;
            queue_full <= 1'b0;
            current_node_processing <= 32'd0;
            last_discovered_node <= 32'd0;
            node_discovered_pulse <= 1'b0;
            edge_pulse <= 1'b0;
            mem_rd_en <= 1'b0;
            mem_addr <= 32'd0;
            current_neighbor_idx <= 8'd0;
            num_neighbors <= 8'd0;
            
            // Initialize distance and parent arrays
            for (i = 0; i < NUM_NODES; i = i + 1) begin
                distance[i] <= 8'd255;  // Infinity
                parent[i] <= 32'd0;
            end
            
        end else begin
            // Default: clear pulses
            node_discovered_pulse <= 1'b0;
            edge_pulse <= 1'b0;
            mem_rd_en <= 1'b0;
            
            case (state)
                IDLE: begin
                    busy <= 1'b0;
                    done <= 1'b0;
                    
                    if (start) begin
                        $display("[%0t] BFS Engine: Starting BFS from node %0d", $time, start_node_id);
                        state <= INIT;
                        busy <= 1'b1;
                    end
                end
                
                INIT: begin
                    // Initialize for new BFS
                    visited_bitmap <= {NUM_NODES{1'b0}};
                    visited_bitmap[start_node_id] <= 1'b1;  // Mark start as visited
                    
                    distance[start_node_id] <= 8'd0;  // Distance to self is 0
                    parent[start_node_id] <= start_node_id;  // Parent of start is itself
                    
                    // Enqueue start node
                    queue[queue_tail] <= start_node_id;
                    queue_tail <= queue_tail + 1;
                    
                    nodes_visited_count <= 32'd1;
                    edges_scanned_count <= 32'd0;
                    current_level <= 32'd0;
                    queue_head <= 6'd0;
                    
                    $display("[%0t] BFS Engine: Initialized - Start node %0d enqueued", $time, start_node_id);
                    state <= FETCH_NODE;
                end
                
                FETCH_NODE: begin
                    if (!queue_empty) begin
                        // Dequeue next node to process
                        current_node <= queue[queue_head];
                        current_node_processing <= queue[queue_head];
                        queue_head <= queue_head + 1;
                        
                        $display("[%0t] BFS Engine: Dequeued node %0d (level %0d)", 
                                 $time, queue[queue_head], distance[queue[queue_head]]);
                        
                        // Request neighbor list from memory
                        // Memory format: [num_neighbors, neighbor0, neighbor1, ...]
                        // Each node gets 32-word block: node_addr = node_id * 0x80 (32 words * 4 bytes)
                        mem_addr <= {queue[queue_head][4:0], 7'b0000000};  // node_id * 128 bytes
                        mem_rd_en <= 1'b1;
                        current_neighbor_idx <= 8'd0;
                        
                        state <= PROCESS_NODE;
                    end else begin
                        // Queue empty - BFS complete
                        $display("[%0t] BFS Engine: Queue empty - BFS complete!", $time);
                        $display("[%0t] BFS Engine: Visited %0d nodes, scanned %0d edges", 
                                 $time, nodes_visited_count, edges_scanned_count);
                        state <= DONE_STATE;
                    end
                end
                
                PROCESS_NODE: begin
                    if (mem_valid) begin
                        // First read: number of neighbors
                        if (current_neighbor_idx == 8'd0) begin
                            num_neighbors <= mem_data[7:0];
                            $display("[%0t] BFS Engine: Node %0d has %0d neighbors", 
                                     $time, current_node_processing, mem_data[7:0]);
                            
                            if (mem_data[7:0] == 0) begin
                                // No neighbors - fetch next node
                                state <= FETCH_NODE;
                            end else begin
                                // Request first neighbor
                                current_neighbor_idx <= 8'd1;
                                mem_addr <= mem_addr + 32'd4;
                                mem_rd_en <= 1'b1;
                            end
                        end else begin
                            // Reading neighbor IDs
                            neighbor_id <= mem_data;
                            state <= CHECK_NEIGHBOR;
                        end
                    end
                end
                
                CHECK_NEIGHBOR: begin
                    // Increment edge counter
                    edges_scanned_count <= edges_scanned_count + 1;
                    edge_pulse <= 1'b1;
                    
                    if (edges_scanned_count < 10 || edges_scanned_count >= 139) begin
                        $display("[%0t] BFS Engine: Checking edge %0d -> %0d (edge #%0d)", 
                                 $time, current_node_processing, neighbor_id, edges_scanned_count + 1);
                    end
                    
                    // Check if neighbor already visited
                    if (!visited_bitmap[neighbor_id[4:0]]) begin  // Only use lower 5 bits for 32 nodes
                        // New node discovered!
                        visited_bitmap[neighbor_id[4:0]] <= 1'b1;
                        distance[neighbor_id[4:0]] <= distance[current_node[4:0]] + 1;
                        parent[neighbor_id[4:0]] <= current_node;
                        
                        // Enqueue for later processing
                        queue[queue_tail] <= neighbor_id;
                        queue_tail <= queue_tail + 1;
                        
                        nodes_visited_count <= nodes_visited_count + 1;
                        last_discovered_node <= neighbor_id;
                        node_discovered_pulse <= 1'b1;
                        
                        $display("[%0t] BFS Engine: ★ NEW NODE DISCOVERED: %0d (distance=%0d, parent=%0d)", 
                                 $time, neighbor_id, distance[current_node[4:0]] + 1, current_node);
                    end
                    
                    // Check if more neighbors to process
                    if (current_neighbor_idx < num_neighbors) begin
                        current_neighbor_idx <= current_neighbor_idx + 1;
                        mem_addr <= mem_addr + 32'd4;
                        mem_rd_en <= 1'b1;
                        state <= PROCESS_NODE;
                    end else begin
                        // Done with this node's neighbors
                        state <= FETCH_NODE;
                    end
                end
                
                DONE_STATE: begin
                    if (!done) begin
                        // Print summary only once (when entering DONE state)
                        $display("\n[%0t] ═══════════════════════════════════════", $time);
                        $display("[%0t] BFS TRAVERSAL COMPLETE", $time);
                        $display("[%0t] ═══════════════════════════════════════", $time);
                        $display("[%0t] Total Nodes Visited: %0d", $time, nodes_visited_count);
                        $display("[%0t] Total Edges Scanned: %0d", $time, edges_scanned_count);
                        $display("[%0t] Maximum BFS Level: %0d", $time, current_level);
                    end
                    
                    done <= 1'b1;
                    busy <= 1'b0;
                    
                    // Stay in DONE (don't auto-restart)
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule
