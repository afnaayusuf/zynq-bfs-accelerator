`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Complete BFS Accelerator System Testbench for Icarus Verilog
// ==============================================================
// Tests the full BFS system with realistic graph data from memory files
// Includes AXI-Lite CSR control and AXI4 memory interface simulation
////////////////////////////////////////////////////////////////////////////////

module bfs_system_complete_tb;

    // ==========================================================================
    // Parameters
    // ==========================================================================
    localparam CLK_PERIOD = 10;              // 100 MHz clock
    localparam AXI_ADDR_WIDTH = 32;          // Changed from 12 to match memory bus width
    localparam AXI_DATA_WIDTH = 32;
    localparam AXI4_ADDR_WIDTH = 32;
    localparam AXI4_DATA_WIDTH = 64;
    
    // CSR Register Addresses (matching actual csr_module.v)
    localparam ADDR_RESERVED      = 12'h000;  // Reserved
    localparam ADDR_START_NODE    = 12'h004;  // Start node address
    localparam ADDR_GRAPH_BASE    = 12'h008;  // Graph base address
    localparam ADDR_CTRL_REG      = 12'h00C;  // Control register (bit 0: start)
    localparam ADDR_STATUS_REG    = 12'h010;  // Status register (bit 0: busy, bit 1: done)
    localparam ADDR_CYCLE_COUNT   = 12'h014;  // Cycle count
    localparam ADDR_EDGES_SCANNED = 12'h018;  // Traversed edges
    localparam ADDR_HIGH_THRESHOLD = 12'h01C; // High degree threshold
    localparam ADDR_MEDIUM_THRESHOLD = 12'h020; // Medium degree threshold
    
    // Control Register Bits
    localparam CTRL_START_BIT = 0;
    localparam CTRL_RESET_BIT = 1;
    localparam CTRL_ENABLE_BIT = 2;
    
    // Status Register Bits (matching actual CSR module)
    localparam STATUS_BUSY_BIT = 0;  // Bit 0: busy
    localparam STATUS_DONE_BIT = 1;  // Bit 1: done

    // ==========================================================================
    // DUT Signals
    // ==========================================================================
    reg aclk;
    reg aresetn;
    
    // AXI-Lite Slave (CSR Interface)
    reg [AXI_ADDR_WIDTH-1:0] s_axi_awaddr;
    reg s_axi_awvalid;
    wire s_axi_awready;
    reg [AXI_DATA_WIDTH-1:0] s_axi_wdata;
    reg [AXI_DATA_WIDTH/8-1:0] s_axi_wstrb;
    reg s_axi_wvalid;
    wire s_axi_wready;
    wire [1:0] s_axi_bresp;
    wire s_axi_bvalid;
    reg s_axi_bready;
    reg [AXI_ADDR_WIDTH-1:0] s_axi_araddr;
    reg s_axi_arvalid;
    wire s_axi_arready;
    wire [AXI_DATA_WIDTH-1:0] s_axi_rdata;
    wire [1:0] s_axi_rresp;
    wire s_axi_rvalid;
    reg s_axi_rready;
    
    // AXI4 Master (Memory Interface)
    wire [AXI4_ADDR_WIDTH-1:0] m_axi_araddr;
    wire [7:0] m_axi_arlen;
    wire [2:0] m_axi_arsize;
    wire [1:0] m_axi_arburst;
    wire m_axi_arvalid;
    reg m_axi_arready;
    reg [AXI4_DATA_WIDTH-1:0] m_axi_rdata;
    reg [1:0] m_axi_rresp;
    reg m_axi_rlast;
    reg m_axi_rvalid;
    wire m_axi_rready;
    
    // Interrupt
    wire interrupt;
    
    // ==========================================================================
    // Graph Memory Model
    // ==========================================================================
    reg [31:0] graph_memory [0:4095];  // Graph data storage
    integer mem_idx;
    
    initial begin
        // Initialize memory
        for (mem_idx = 0; mem_idx < 4096; mem_idx = mem_idx + 1) begin
            graph_memory[mem_idx] = 32'h0;
        end
        
        // Load graph data from memory file (simple format for BFS engine)
        $readmemh("../../test_data/simple_graph_memory.mem", graph_memory);
        $display("[%0t] Graph memory loaded from simple_graph_memory.mem", $time);
    end

    // ==========================================================================
    // DUT Instantiation
    // ==========================================================================
    bfs_system_integrated #(
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI4_DATA_WIDTH)
    ) dut (
        .clk(aclk),
        .rst_n(aresetn),
        
        // AXI-Lite Slave (CSR)
        .s_axi_lite_awaddr(s_axi_awaddr),
        .s_axi_lite_awvalid(s_axi_awvalid),
        .s_axi_lite_awready(s_axi_awready),
        .s_axi_lite_wdata(s_axi_wdata),
        .s_axi_lite_wstrb(s_axi_wstrb),
        .s_axi_lite_wvalid(s_axi_wvalid),
        .s_axi_lite_wready(s_axi_wready),
        .s_axi_lite_bresp(s_axi_bresp),
        .s_axi_lite_bvalid(s_axi_bvalid),
        .s_axi_lite_bready(s_axi_bready),
        .s_axi_lite_araddr(s_axi_araddr),
        .s_axi_lite_arvalid(s_axi_arvalid),
        .s_axi_lite_arready(s_axi_arready),
        .s_axi_lite_rdata(s_axi_rdata),
        .s_axi_lite_rresp(s_axi_rresp),
        .s_axi_lite_rvalid(s_axi_rvalid),
        .s_axi_lite_rready(s_axi_rready),
        
        // AXI4 Master (Memory)
        .m_axi_araddr(m_axi_araddr),
        .m_axi_arlen(m_axi_arlen),
        .m_axi_arvalid(m_axi_arvalid),
        .m_axi_arready(m_axi_arready),
        .m_axi_rdata(m_axi_rdata),
        .m_axi_rlast(m_axi_rlast),
        .m_axi_rresp(m_axi_rresp),
        .m_axi_rvalid(m_axi_rvalid),
        .m_axi_rready(m_axi_rready),
        
        // Interrupt
        .global_done(interrupt)
    );

    // ==========================================================================
    // Clock Generation
    // ==========================================================================
    initial begin
        aclk = 0;
        forever #(CLK_PERIOD/2) aclk = ~aclk;
    end

    // ==========================================================================
    // AXI4 Memory Model (DDR Simulator)
    // ==========================================================================
    reg [7:0] burst_count;
    reg [AXI4_ADDR_WIDTH-1:0] burst_addr;
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            m_axi_arready <= 1'b0;
            m_axi_rvalid <= 1'b0;
            m_axi_rlast <= 1'b0;
            m_axi_rdata <= 0;
            m_axi_rresp <= 2'b00;
            burst_count <= 0;
            burst_addr <= 0;
        end else begin
            // Address channel handshake
            if (m_axi_arvalid && !m_axi_arready) begin
                m_axi_arready <= 1'b1;
                burst_addr <= m_axi_araddr;
                burst_count <= m_axi_arlen + 1;  // ARLEN is 0-based
                $display("[%0t] AXI Read Handshake: addr=0x%h, len=%0d", $time, m_axi_araddr, m_axi_arlen+1);
            end else if (m_axi_arready && !m_axi_arvalid) begin
                // arready was high, but no more valid - clear it
                m_axi_arready <= 1'b0;
            end
            
            // Data channel - burst read (starts one cycle after address handshake)
            if (m_axi_arready && burst_count > 0 && !m_axi_rvalid) begin
                // Start data transfer
                m_axi_rvalid <= 1'b1;
                // Read from graph memory (byte address to word address)
                // Return single 32-bit word in lower half of 64-bit data
                m_axi_rdata <= {32'h0, graph_memory[burst_addr[13:2]]};
                m_axi_rresp <= 2'b00;  // OKAY
                m_axi_rlast <= (burst_count == 1);
                $display("[%0t] AXI Memory Data: addr=0x%h word_addr=%0d data=0x%h", 
                         $time, burst_addr, burst_addr[13:2], graph_memory[burst_addr[13:2]]);
                burst_count <= burst_count - 1;
                burst_addr <= burst_addr + 8;  // Increment by data width
            end else if (m_axi_rvalid && m_axi_rready) begin
                if (burst_count > 1) begin
                    // Continue burst
                    m_axi_rdata <= {32'h0, graph_memory[burst_addr[13:2]]};
                    m_axi_rlast <= (burst_count == 2);
                    burst_count <= burst_count - 1;
                    burst_addr <= burst_addr + 8;
                    $display("[%0t] AXI Memory: Read addr=0x%h word_addr=%0d data=0x%h", 
                             $time, burst_addr, burst_addr[13:2], graph_memory[burst_addr[13:2]]);
                end else begin
                    // End of burst
                    m_axi_rvalid <= 1'b0;
                    m_axi_rlast <= 1'b0;
                end
            end
        end
    end

    // ==========================================================================
    // AXI-Lite Write Task
    // ==========================================================================
    task axi_write;
        input [AXI_ADDR_WIDTH-1:0] addr;
        input [AXI_DATA_WIDTH-1:0] data;
        begin
            @(posedge aclk);
            s_axi_awaddr = addr;
            s_axi_awvalid = 1'b1;
            s_axi_wdata = data;
            s_axi_wvalid = 1'b1;
            s_axi_wstrb = 4'b1111;
            
            // Wait for address and data ready
            while (!(s_axi_awready && s_axi_wready)) @(posedge aclk);
            
            @(posedge aclk);
            s_axi_awvalid = 1'b0;
            s_axi_wvalid = 1'b0;
            
            // Wait for write response
            while (!s_axi_bvalid) @(posedge aclk);
            @(posedge aclk);
            
            $display("[%0t] AXI Write: addr=0x%h, data=0x%h", $time, addr, data);
        end
    endtask

    // ==========================================================================
    // AXI-Lite Read Task
    // ==========================================================================
    task axi_read;
        input [AXI_ADDR_WIDTH-1:0] addr;
        output [AXI_DATA_WIDTH-1:0] data;
        begin
            @(posedge aclk);
            s_axi_araddr = addr;
            s_axi_arvalid = 1'b1;
            
            // Wait for address ready
            while (!s_axi_arready) @(posedge aclk);
            
            @(posedge aclk);
            s_axi_arvalid = 1'b0;
            
            // Wait for read data
            while (!s_axi_rvalid) @(posedge aclk);
            data = s_axi_rdata;
            @(posedge aclk);
            
            $display("[%0t] AXI Read: addr=0x%h, data=0x%h", $time, addr, data);
        end
    endtask

    // ==========================================================================
    // Monitor Task - Poll Status
    // ==========================================================================
    task monitor_status;
        reg [AXI_DATA_WIDTH-1:0] status;
        reg [AXI_DATA_WIDTH-1:0] cycle_count;
        reg [AXI_DATA_WIDTH-1:0] edges_scanned;
        begin
            axi_read(ADDR_STATUS_REG, status);
            axi_read(ADDR_CYCLE_COUNT, cycle_count);
            axi_read(ADDR_EDGES_SCANNED, edges_scanned);
            
            $display("═══════════════════════════════════════════");
            $display("  Status: 0x%h [BUSY=%b DONE=%b]", 
                     status, status[0], status[1]);
            $display("  Cycle Count: %0d", cycle_count);
            $display("  Edges Scanned: %0d", edges_scanned);
            $display("═══════════════════════════════════════════");
        end
    endtask

    // ==========================================================================
    // Main Test Sequence
    // ==========================================================================
    reg [AXI_DATA_WIDTH-1:0] read_data;
    integer timeout_counter;
    
    initial begin
        $display("\n");
        $display("╔═════════════════════════════════════════════════════════════╗");
        $display("║  BFS Accelerator Complete System Testbench                  ║");
        $display("║  Testing with Complex 32-Node Social Network Graph          ║");
        $display("╚═════════════════════════════════════════════════════════════╝");
        $display("\n");
        
        // Initialize AXI-Lite signals
        aresetn = 0;
        s_axi_awaddr = 0;
        s_axi_awvalid = 0;
        s_axi_wdata = 0;
        s_axi_wstrb = 0;
        s_axi_wvalid = 0;
        s_axi_bready = 1;
        s_axi_araddr = 0;
        s_axi_arvalid = 0;
        s_axi_rready = 1;
        
        // Reset sequence
        #100;
        $display("[%0t] ▶ Releasing reset...", $time);
        aresetn = 1;
        #200;
        
        // ======================================================================
        // TEST 1: Configure BFS Parameters
        // ======================================================================
        $display("\n[%0t] ═══ TEST 1: Configure BFS Parameters ═══", $time);
        
        axi_write(ADDR_START_NODE, 32'd0);       // Start from node 0 (celebrity)
        axi_write(ADDR_GRAPH_BASE, 32'h00000000); // Graph data at base address
        
        $display("[%0t] ✓ Configuration complete", $time);
        #100;
        
        // ======================================================================
        // TEST 2: Start BFS Execution
        // ======================================================================
        $display("\n[%0t] ═══ TEST 2: Start BFS Execution ═══", $time);
        
        // Set control register: start bit (bit 0)
        axi_write(ADDR_CTRL_REG, 32'h00000001);  // Start=1
        
        $display("[%0t] ✓ BFS started", $time);
        #100;
        
        // ======================================================================
        // TEST 3: Monitor Execution Progress
        // ======================================================================
        $display("\n[%0t] ═══ TEST 3: Monitor Execution ═══", $time);
        
        timeout_counter = 0;
        read_data = 0;
        
        // Poll until done or timeout
        while (read_data[STATUS_DONE_BIT] == 0 && timeout_counter < 10000) begin
            #1000;  // Check every 1us
            monitor_status();
            axi_read(ADDR_STATUS_REG, read_data);
            timeout_counter = timeout_counter + 1;
            

        end
        
        if (timeout_counter >= 10000) begin
            $display("\n[%0t] ✗ TIMEOUT: BFS did not complete", $time);
            $finish;
        end
        
        // ======================================================================
        // TEST 4: Verify Results
        // ======================================================================
        $display("\n[%0t] ═══ TEST 4: Final Results ═══", $time);
        
        monitor_status();
        
        if (read_data[STATUS_DONE_BIT]) begin
            $display("\n[%0t] ✓ BFS COMPLETED SUCCESSFULLY!", $time);
        end
        
        // ======================================================================
        // TEST 5: Check Interrupt Signal
        // ======================================================================
        $display("\n[%0t] ═══ TEST 5: Interrupt Check ═══", $time);
        
        if (interrupt) begin
            $display("[%0t] ✓ Interrupt signal asserted", $time);
        end else begin
            $display("[%0t] ✗ Interrupt signal NOT asserted", $time);
        end
        
        #1000;
        
        // ======================================================================
        // Summary
        // ======================================================================
        $display("\n╔═════════════════════════════════════════════════════════════╗");
        $display("║  SIMULATION COMPLETE                                        ║");
        $display("║  Expected Results for Node 0 (Celebrity):                   ║");
        $display("║  - Nodes Visited: 32 (all nodes reachable)                  ║");
        $display("║  - Max BFS Level: ~3-5 (social network depth)               ║");
        $display("║  - Edges Scanned: 140+ (bidirectional edges)                ║");
        $display("╚═════════════════════════════════════════════════════════════╝");
        $display("\n");
        
        $finish;
    end
    
    // ==========================================================================
    // VCD Dump for GTKWave
    // ==========================================================================
    initial begin
        $dumpfile("bfs_system_complete.vcd");
        $dumpvars(0, bfs_system_complete_tb);
        
        // Dump internal signals for detailed analysis
        $dumpvars(1, dut);
        
        // Limit dump depth to avoid huge files
        // Comment out for full hierarchy dump
        // $dumpvars(2, dut);
    end
    
    // ==========================================================================
    // Simulation Timeout Watchdog
    // ==========================================================================
    initial begin
        #500000;  // 500us absolute timeout
        $display("\n[%0t] ✗ WATCHDOG TIMEOUT: Simulation exceeded 500us", $time);
        $finish;
    end
    
    // ==========================================================================
    // Signal Monitoring (Optional Debug)
    // ==========================================================================
    always @(posedge interrupt) begin
        $display("\n[%0t] ★★★ INTERRUPT TRIGGERED ★★★", $time);
    end

    // ==========================================================================
    // ADDITIONAL SIGNALS FOR MODELSIM WAVEFORM PLOTTING
    // ==========================================================================
    
    // Expose internal DUT signals for easier viewing - FROM BFS ENGINE
    wire [2:0] bfs_state_internal;
    wire [31:0] nodes_visited_internal;
    wire [31:0] edges_scanned_internal;
    wire [31:0] current_level_internal;
    wire bfs_busy_internal;
    wire bfs_done_internal;
    wire incr_edge_pulse;
    wire [31:0] current_node_id;  // Which node is being processed
    wire [31:0] last_node_discovered;
    wire node_discovered_event;
    
    assign bfs_state_internal = dut.bfs_engine.state;
    assign nodes_visited_internal = dut.nodes_visited;
    assign edges_scanned_internal = dut.edges_scanned;
    assign current_level_internal = dut.current_bfs_level;
    assign bfs_busy_internal = dut.bfs_busy;
    assign bfs_done_internal = dut.bfs_done;
    assign incr_edge_pulse = dut.incr_edge_signal;
    assign current_node_id = dut.current_node_processing;
    assign last_node_discovered = dut.last_discovered_node;
    assign node_discovered_event = dut.node_discovered_pulse;
    
    // State decoder for human-readable state names
    reg [127:0] state_name;
    always @(*) begin
        case (bfs_state_internal)
            3'd0: state_name = "IDLE";
            3'd1: state_name = "INIT";
            3'd2: state_name = "FETCH_NODE";
            3'd3: state_name = "PROCESS_NODE";
            3'd4: state_name = "CHECK_NEIGHBOR";
            3'd5: state_name = "NEXT_LEVEL";
            3'd6: state_name = "DONE";
            default: state_name = "UNKNOWN";
        endcase
    end
    
    // Node visit event tracker (pulses high when a new node is visited)
    reg [31:0] prev_nodes_visited;
    wire node_visited_event;
    assign node_visited_event = node_discovered_event;
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn)
            prev_nodes_visited <= 0;
        else
            prev_nodes_visited <= nodes_visited_internal;
    end
    
    // Edge processing event (visual indicator)
    wire edge_processed;
    assign edge_processed = incr_edge_pulse;
    
    // Level change detector
    reg [31:0] prev_level;
    wire level_changed;
    assign level_changed = (current_level_internal != prev_level);
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn)
            prev_level <= 0;
        else
            prev_level <= current_level_internal;
    end
    
    // Status bits decoded
    wire status_busy;
    wire status_done;
    assign status_busy = s_axi_rdata[STATUS_BUSY_BIT];
    assign status_done = s_axi_rdata[STATUS_DONE_BIT];
    
    // current_node_id now comes from BFS engine directly (see wire assignment above)
    
    // BFS Progress indicator (percentage)
    reg [7:0] bfs_progress_percent;
    always @(*) begin
        if (nodes_visited_internal >= 32)
            bfs_progress_percent = 8'd100;
        else
            bfs_progress_percent = (nodes_visited_internal * 100) / 32;
    end
    
    // Activity indicators (useful for plotting)
    wire axi_write_active;
    wire axi_read_active;
    wire mem_read_active;
    
    assign axi_write_active = s_axi_awvalid || s_axi_wvalid;
    assign axi_read_active = s_axi_arvalid || s_axi_rvalid;
    assign mem_read_active = m_axi_arvalid || m_axi_rvalid;

endmodule
