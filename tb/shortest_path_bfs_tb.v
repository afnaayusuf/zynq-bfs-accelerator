`timescale 1ns / 1ps

//==============================================================================
// Point-to-Point Shortest Path BFS Simulation Testbench
//==============================================================================
// This testbench finds the shortest path between TWO specific nodes using BFS
// with early termination optimization.
//
// Mode 1: Point-to-Point (stops when target found)
// Mode 2: Single-Source All-Destinations (explores entire graph)
//==============================================================================

module shortest_path_bfs_tb;

    //==========================================================================
    // Parameters
    //==========================================================================
    parameter NUM_NODES = 32;
    parameter NUM_EDGES = 171;
    parameter START_NODE = 0;      // Source node
    parameter TARGET_NODE = 31;    // Destination node
    parameter MAX_LEVELS = 10;
    parameter CLK_PERIOD = 10;
    
    // Simulation mode
    parameter MODE_POINT_TO_POINT = 1;  // 1 = Stop at target, 0 = Explore all
    
    //==========================================================================
    // Clock and Reset
    //==========================================================================
    reg clk;
    reg rst_n;
    
    //==========================================================================
    // Graph Memory (CSR Format)
    //==========================================================================
    reg [31:0] offset_array [0:NUM_NODES];
    reg [31:0] edge_array [0:NUM_EDGES-1];
    
    //==========================================================================
    // BFS State Variables
    //==========================================================================
    reg [31:0] current_level;
    reg [31:0] nodes_in_current_level;
    reg [NUM_NODES-1:0] visited;
    reg [31:0] frontier_queue [0:NUM_NODES-1];
    reg [31:0] next_frontier [0:NUM_NODES-1];
    reg [31:0] distance [0:NUM_NODES-1];
    reg [31:0] parent [0:NUM_NODES-1];
    
    //==========================================================================
    // Control Variables
    //==========================================================================
    integer i, j, k, m;
    integer front_idx, next_idx;
    reg [31:0] current_node;
    reg [31:0] neighbor_start, neighbor_end;
    reg [31:0] neighbor;
    reg bfs_done;
    reg target_found;
    
    // Statistics
    integer total_edges_explored;
    integer nodes_explored;
    reg [31:0] node_degree [0:NUM_NODES-1];
    reg should_exit_loop;  // Flag for early termination
    
    // Timing
    real start_time, end_time, execution_time;
    
    //==========================================================================
    // Clock Generation
    //==========================================================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    //==========================================================================
    // Initialize Graph Data
    //==========================================================================
    initial begin
        $display("[INFO] Loading graph data...");
        $readmemh("test_data/complex_graph_memory.mem", offset_array);
        
        // Initialize edge array (same as complex graph)
        #1;
        edge_array[0] = 1; edge_array[1] = 2; edge_array[2] = 3; edge_array[3] = 4;
        edge_array[4] = 5; edge_array[5] = 6; edge_array[6] = 7; edge_array[7] = 8;
        edge_array[8] = 9; edge_array[9] = 10; edge_array[10] = 11; edge_array[11] = 12;
        edge_array[12] = 13; edge_array[13] = 14; edge_array[14] = 15; edge_array[15] = 16;
        edge_array[16] = 17;
        edge_array[17] = 0; edge_array[18] = 2; edge_array[19] = 3; edge_array[20] = 4;
        edge_array[21] = 5; edge_array[22] = 8; edge_array[23] = 12; edge_array[24] = 13;
        edge_array[25] = 18; edge_array[26] = 19; edge_array[27] = 20; edge_array[28] = 21;
        edge_array[29] = 0; edge_array[30] = 1; edge_array[31] = 5; edge_array[32] = 6;
        edge_array[33] = 7; edge_array[34] = 12; edge_array[35] = 13; edge_array[36] = 14;
        edge_array[37] = 22; edge_array[38] = 23;
        edge_array[39] = 0; edge_array[40] = 1; edge_array[41] = 8; edge_array[42] = 9;
        edge_array[43] = 10; edge_array[44] = 18; edge_array[45] = 19; edge_array[46] = 24;
        edge_array[47] = 0; edge_array[48] = 11; edge_array[49] = 15; edge_array[50] = 16;
        edge_array[51] = 17; edge_array[52] = 25; edge_array[53] = 26; edge_array[54] = 27;
        edge_array[55] = 0; edge_array[56] = 1; edge_array[57] = 2; edge_array[58] = 6;
        edge_array[59] = 7; edge_array[60] = 12; edge_array[61] = 13;
        edge_array[62] = 0; edge_array[63] = 2; edge_array[64] = 5; edge_array[65] = 7;
        edge_array[66] = 14; edge_array[67] = 15;
        edge_array[68] = 0; edge_array[69] = 2; edge_array[70] = 5; edge_array[71] = 6;
        edge_array[72] = 14; edge_array[73] = 22;
        edge_array[74] = 0; edge_array[75] = 1; edge_array[76] = 3; edge_array[77] = 9;
        edge_array[78] = 10; edge_array[79] = 18; edge_array[80] = 19;
        edge_array[81] = 0; edge_array[82] = 3; edge_array[83] = 8; edge_array[84] = 10;
        edge_array[85] = 19; edge_array[86] = 20;
        edge_array[87] = 0; edge_array[88] = 3; edge_array[89] = 8; edge_array[90] = 9;
        edge_array[91] = 20; edge_array[92] = 21;
        edge_array[93] = 0; edge_array[94] = 4; edge_array[95] = 16; edge_array[96] = 17;
        edge_array[97] = 24; edge_array[98] = 25;
        edge_array[99] = 0; edge_array[100] = 1; edge_array[101] = 2; edge_array[102] = 5;
        edge_array[103] = 13;
        edge_array[104] = 0; edge_array[105] = 1; edge_array[106] = 2; edge_array[107] = 5;
        edge_array[108] = 12;
        edge_array[109] = 0; edge_array[110] = 2; edge_array[111] = 6; edge_array[112] = 7;
        edge_array[113] = 0; edge_array[114] = 4; edge_array[115] = 6;
        edge_array[116] = 0; edge_array[117] = 4; edge_array[118] = 11; edge_array[119] = 17;
        edge_array[120] = 0; edge_array[121] = 4; edge_array[122] = 11; edge_array[123] = 16;
        edge_array[124] = 1; edge_array[125] = 3; edge_array[126] = 8; edge_array[127] = 19;
        edge_array[128] = 23;
        edge_array[129] = 1; edge_array[130] = 3; edge_array[131] = 8; edge_array[132] = 9;
        edge_array[133] = 18; edge_array[134] = 24;
        edge_array[135] = 1; edge_array[136] = 9; edge_array[137] = 10; edge_array[138] = 21;
        edge_array[139] = 1; edge_array[140] = 10; edge_array[141] = 20;
        edge_array[142] = 2; edge_array[143] = 7; edge_array[144] = 23;
        edge_array[145] = 2; edge_array[146] = 18; edge_array[147] = 22;
        edge_array[148] = 3; edge_array[149] = 11; edge_array[150] = 19; edge_array[151] = 25;
        edge_array[152] = 4; edge_array[153] = 11; edge_array[154] = 24; edge_array[155] = 26;
        edge_array[156] = 4; edge_array[157] = 25; edge_array[158] = 27;
        edge_array[159] = 4; edge_array[160] = 26; edge_array[161] = 28;
        edge_array[162] = 27; edge_array[163] = 29; edge_array[164] = 30;
        edge_array[165] = 28; edge_array[166] = 30; edge_array[167] = 31;
        edge_array[168] = 28; edge_array[169] = 29;
        edge_array[170] = 29;
        
        for (i = 0; i < NUM_NODES; i = i + 1) begin
            node_degree[i] = offset_array[i + 1] - offset_array[i];
        end
        
        $display("[INFO] Graph data loaded successfully!");
    end
    
    //==========================================================================
    // Reconstruct Path from Parent Array
    //==========================================================================
    task reconstruct_path;
        input [31:0] target;
        reg [31:0] path [0:NUM_NODES-1];
        integer path_len;
        integer idx;
        reg [31:0] curr;
        begin
            // Trace back from target to source
            path_len = 0;
            curr = target;
            
            while (curr != START_NODE && parent[curr] != 32'hFFFFFFFF) begin
                path[path_len] = curr;
                path_len = path_len + 1;
                curr = parent[curr];
            end
            
            path[path_len] = START_NODE;
            path_len = path_len + 1;
            
            // Display path in correct order
            $display("\n┌────────────────────────────────────────────────────────────────┐");
            $display("│           SHORTEST PATH FOUND                                  │");
            $display("└────────────────────────────────────────────────────────────────┘");
            $write("  Path: ");
            for (idx = path_len - 1; idx >= 0; idx = idx - 1) begin
                $write("%0d", path[idx]);
                if (idx > 0) $write(" → ");
            end
            $display("\n  Distance: %0d hops", distance[target]);
            $display("  Nodes explored: %0d / %0d (%.1f%%)", 
                     nodes_explored, NUM_NODES, 
                     (nodes_explored * 100.0) / NUM_NODES);
        end
    endtask
    
    //==========================================================================
    // Main BFS Simulation
    //==========================================================================
    initial begin
        $dumpfile("shortest_path_bfs_sim.vcd");
        $dumpvars(0, shortest_path_bfs_tb);
        
        $display("\n╔════════════════════════════════════════════════════════════════╗");
        $display("║        SHORTEST PATH BFS SIMULATION                           ║");
        $display("╚════════════════════════════════════════════════════════════════╝");
        $display("  Mode: %s", MODE_POINT_TO_POINT ? "Point-to-Point (Early Termination)" : "Single-Source All-Destinations");
        $display("  Start Node: %0d", START_NODE);
        $display("  Target Node: %0d", TARGET_NODE);
        $display("  Total Nodes: %0d", NUM_NODES);
        
        // Wait for graph load
        #1;
        
        // Initialize
        rst_n = 0;
        current_level = 0;
        visited = 0;
        bfs_done = 0;
        target_found = 0;
        total_edges_explored = 0;
        nodes_explored = 0;
        
        for (i = 0; i < NUM_NODES; i = i + 1) begin
            frontier_queue[i] = 0;
            next_frontier[i] = 0;
            distance[i] = 32'hFFFFFFFF;
            parent[i] = 32'hFFFFFFFF;
        end
        
        #(CLK_PERIOD * 10);
        rst_n = 1;
        #(CLK_PERIOD * 5);
        
        start_time = $realtime;
        
        // Initialize with start node
        frontier_queue[0] = START_NODE;
        visited[START_NODE] = 1'b1;
        distance[START_NODE] = 0;
        parent[START_NODE] = START_NODE;
        nodes_in_current_level = 1;
        nodes_explored = 1;
        
        $display("\n╔════════════════════════════════════════════════════════════════╗");
        $display("║                  BFS TRAVERSAL START                           ║");
        $display("╚════════════════════════════════════════════════════════════════╝\n");
        
        //======================================================================
        // BFS Main Loop with Early Termination
        //======================================================================
        while (!bfs_done && current_level < MAX_LEVELS) begin
            @(posedge clk);
            #1;
            
            next_idx = 0;
            should_exit_loop = 0;
            $display("► Level %0d: Processing %0d nodes", current_level, nodes_in_current_level);
            
            // Process all nodes in current level
            for (front_idx = 0; front_idx < nodes_in_current_level && !should_exit_loop; front_idx = front_idx + 1) begin
                current_node = frontier_queue[front_idx];
                
                // Check if we found the target
                if (MODE_POINT_TO_POINT && current_node == TARGET_NODE) begin
                    $display("  ✓ TARGET NODE %0d FOUND at distance %0d!", TARGET_NODE, distance[TARGET_NODE]);
                    target_found = 1'b1;
                    bfs_done = 1'b1;
                    should_exit_loop = 1;
                end
                
                if (!should_exit_loop) begin
                    neighbor_start = offset_array[current_node];
                    neighbor_end = offset_array[current_node + 1];
                    
                    $display("  → Node %2d: Exploring %2d neighbors", 
                             current_node, (neighbor_end - neighbor_start));
                    
                    // Process neighbors
                    for (k = neighbor_start; k < neighbor_end; k = k + 1) begin
                        neighbor = edge_array[k];
                        total_edges_explored = total_edges_explored + 1;
                        
                        if (!visited[neighbor]) begin
                            $display("    ✓ Discovered: Node %2d (distance=%0d, parent=%0d)", 
                                     neighbor, current_level + 1, current_node);
                            visited[neighbor] = 1'b1;
                            distance[neighbor] = current_level + 1;
                            parent[neighbor] = current_node;
                            next_frontier[next_idx] = neighbor;
                            next_idx = next_idx + 1;
                            nodes_explored = nodes_explored + 1;
                            
                            // Check if we just discovered the target
                            if (MODE_POINT_TO_POINT && neighbor == TARGET_NODE) begin
                                $display("    ⭐ TARGET NODE %0d DISCOVERED!", TARGET_NODE);
                                target_found = 1'b1;
                            end
                        end
                    end
                    
                    // Early exit if target found in point-to-point mode
                    if (MODE_POINT_TO_POINT && target_found) begin
                        bfs_done = 1'b1;
                        should_exit_loop = 1;
                    end
                    
                    @(posedge clk);
                    #1;
                end
            end
            
            // Check if we should continue
            if (target_found && MODE_POINT_TO_POINT) begin
                $display("\n  ✓ Target found! Stopping BFS (early termination).\n");
                bfs_done = 1'b1;
            end else begin
                nodes_in_current_level = next_idx;
                
                if (nodes_in_current_level > 0) begin
                    $display("  ► %0d new nodes discovered for Level %0d\n", next_idx, current_level + 1);
                    
                    for (i = 0; i < next_idx; i = i + 1) begin
                        frontier_queue[i] = next_frontier[i];
                    end
                    
                    current_level = current_level + 1;
                end else begin
                    $display("\n  ✓ No more nodes to explore. BFS complete!\n");
                    bfs_done = 1'b1;
                end
            end
            
            @(posedge clk);
            #(CLK_PERIOD * 2);
        end
        
        end_time = $realtime;
        execution_time = end_time - start_time;
        
        //======================================================================
        // Display Results
        //======================================================================
        $display("\n╔════════════════════════════════════════════════════════════════╗");
        $display("║                    SIMULATION COMPLETE                         ║");
        $display("╚════════════════════════════════════════════════════════════════╝");
        $display("  Simulation Time:  %.2f ns", execution_time);
        $display("  Clock Cycles:     %0d", execution_time / CLK_PERIOD);
        $display("  BFS Levels:       %0d", current_level);
        $display("  Nodes Explored:   %0d / %0d (%.1f%%)", 
                 nodes_explored, NUM_NODES, (nodes_explored * 100.0) / NUM_NODES);
        $display("  Edges Explored:   %0d", total_edges_explored);
        
        if (target_found) begin
            $display("\n  ✅ SUCCESS: Target node %0d reached!", TARGET_NODE);
            reconstruct_path(TARGET_NODE);
        end else begin
            $display("\n  ❌ FAILURE: Target node %0d is UNREACHABLE from node %0d", 
                     TARGET_NODE, START_NODE);
        end
        
        // Comparison with full traversal
        if (MODE_POINT_TO_POINT && target_found) begin
            $display("\n┌────────────────────────────────────────────────────────────────┐");
            $display("│        EFFICIENCY COMPARISON                                   │");
            $display("└────────────────────────────────────────────────────────────────┘");
            $display("  Point-to-Point Mode:");
            $display("    Nodes explored: %0d (%.1f%%)", 
                     nodes_explored, (nodes_explored * 100.0) / NUM_NODES);
            $display("    Edges explored: %0d", total_edges_explored);
            $display("  Full Graph Traversal Would Need:");
            $display("    Nodes explored: %0d (100%%)", NUM_NODES);
            $display("    Edges explored: %0d (all edges)", NUM_EDGES);
            $display("  Savings:");
            $display("    Nodes saved: %0d (%.1f%% reduction)", 
                     NUM_NODES - nodes_explored, 
                     ((NUM_NODES - nodes_explored) * 100.0) / NUM_NODES);
            $display("    Edges saved: %0d (%.1f%% reduction)", 
                     NUM_EDGES - total_edges_explored,
                     ((NUM_EDGES - total_edges_explored) * 100.0) / NUM_EDGES);
        end
        
        $display("\n╔════════════════════════════════════════════════════════════════╗");
        $display("║              SIMULATION COMPLETED SUCCESSFULLY                 ║");
        $display("╚════════════════════════════════════════════════════════════════╝\n");
        
        #(CLK_PERIOD * 10);
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * 10000);
        $display("\n[ERROR] Simulation timeout!");
        $finish;
    end
    
endmodule
