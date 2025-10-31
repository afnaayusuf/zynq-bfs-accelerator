`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// BFS CSR Module Testbench
// Tests the Control and Status Register interface
////////////////////////////////////////////////////////////////////////////////

module bfs_csr_tb;

    // Parameters
    localparam CLK_PERIOD = 10;              // 100 MHz
    localparam AXI_ADDR_WIDTH = 12;
    localparam AXI_DATA_WIDTH = 32;
    
    // CSR Register Addresses
    localparam ADDR_CTRL_REG      = 12'h000;
    localparam ADDR_START_NODE    = 12'h004;
    localparam ADDR_NODE_COUNT    = 12'h008;
    localparam ADDR_GRAPH_BASE    = 12'h00C;
    localparam ADDR_STATUS_REG    = 12'h010;
    localparam ADDR_NODES_VISITED = 12'h014;
    localparam ADDR_EDGES_SCANNED = 12'h018;
    localparam ADDR_BFS_LEVEL     = 12'h01C;

    // Signals
    reg clk;
    reg rst_n;
    
    // AXI-Lite Interface
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
    
    // Control/Status signals
    wire start_bfs;
    wire reset_bfs;
    wire enable_bfs;
    wire [31:0] start_node_id;
    wire [31:0] node_count;
    wire [31:0] graph_base_addr;
    reg bfs_done;
    reg bfs_busy;
    reg bfs_error;
    reg [31:0] nodes_visited_count;
    reg [31:0] edges_scanned_count;
    reg [31:0] current_level;

    // DUT Instantiation
    csr_module #(
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        
        // AXI-Lite Interface
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),
        
        // Control outputs
        .start_bfs(start_bfs),
        .reset_bfs(reset_bfs),
        .enable_bfs(enable_bfs),
        .start_node_id(start_node_id),
        .node_count(node_count),
        .graph_base_addr(graph_base_addr),
        
        // Status inputs
        .bfs_done(bfs_done),
        .bfs_busy(bfs_busy),
        .bfs_error(bfs_error),
        .nodes_visited_count(nodes_visited_count),
        .edges_scanned_count(edges_scanned_count),
        .current_level(current_level)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // AXI-Lite Write Task
    task axi_write;
        input [AXI_ADDR_WIDTH-1:0] addr;
        input [AXI_DATA_WIDTH-1:0] data;
        begin
            @(posedge clk);
            s_axi_awaddr = addr;
            s_axi_awvalid = 1'b1;
            s_axi_wdata = data;
            s_axi_wvalid = 1'b1;
            s_axi_wstrb = 4'b1111;
            
            // Wait for handshake
            while (!(s_axi_awready && s_axi_wready)) @(posedge clk);
            
            @(posedge clk);
            s_axi_awvalid = 1'b0;
            s_axi_wvalid = 1'b0;
            
            // Wait for write response
            while (!s_axi_bvalid) @(posedge clk);
            @(posedge clk);
            
            $display("[%0t] AXI Write: addr=0x%h, data=0x%h", $time, addr, data);
        end
    endtask

    // AXI-Lite Read Task
    task axi_read;
        input [AXI_ADDR_WIDTH-1:0] addr;
        output [AXI_DATA_WIDTH-1:0] data;
        begin
            @(posedge clk);
            s_axi_araddr = addr;
            s_axi_arvalid = 1'b1;
            
            // Wait for handshake
            while (!s_axi_arready) @(posedge clk);
            
            @(posedge clk);
            s_axi_arvalid = 1'b0;
            
            // Wait for read data
            while (!s_axi_rvalid) @(posedge clk);
            data = s_axi_rdata;
            @(posedge clk);
            
            $display("[%0t] AXI Read: addr=0x%h, data=0x%h", $time, addr, data);
        end
    endtask

    // Main Test Sequence
    reg [AXI_DATA_WIDTH-1:0] read_data;
    
    initial begin
        $display("\n╔═══════════════════════════════════════════════╗");
        $display("║  BFS CSR Module Testbench                     ║");
        $display("╚═══════════════════════════════════════════════╝\n");
        
        // Initialize
        rst_n = 0;
        s_axi_awaddr = 0;
        s_axi_awvalid = 0;
        s_axi_wdata = 0;
        s_axi_wstrb = 0;
        s_axi_wvalid = 0;
        s_axi_bready = 1;
        s_axi_araddr = 0;
        s_axi_arvalid = 0;
        s_axi_rready = 1;
        
        // Status inputs (simulate BFS engine)
        bfs_done = 0;
        bfs_busy = 0;
        bfs_error = 0;
        nodes_visited_count = 0;
        edges_scanned_count = 0;
        current_level = 0;
        
        // Reset
        #100;
        $display("[%0t] Releasing reset...", $time);
        rst_n = 1;
        #200;
        
        // TEST 1: Write Configuration
        $display("\n[%0t] ═══ TEST 1: Write Configuration ═══", $time);
        axi_write(ADDR_NODE_COUNT, 32'd32);
        axi_write(ADDR_START_NODE, 32'd0);
        axi_write(ADDR_GRAPH_BASE, 32'h10000000);
        
        // Verify outputs
        #50;
        $display("[%0t] start_node_id = %0d", $time, start_node_id);
        $display("[%0t] node_count = %0d", $time, node_count);
        $display("[%0t] graph_base_addr = 0x%h", $time, graph_base_addr);
        
        // TEST 2: Start BFS
        $display("\n[%0t] ═══ TEST 2: Start BFS ═══", $time);
        axi_write(ADDR_CTRL_REG, 32'h00000005);  // enable + start
        
        #50;
        $display("[%0t] start_bfs = %b", $time, start_bfs);
        $display("[%0t] enable_bfs = %b", $time, enable_bfs);
        
        // TEST 3: Simulate BFS Execution
        $display("\n[%0t] ═══ TEST 3: Simulate BFS Progress ═══", $time);
        #100;
        bfs_busy = 1;
        
        // Simulate progress
        repeat(10) begin
            #100;
            nodes_visited_count = nodes_visited_count + 3;
            edges_scanned_count = edges_scanned_count + 14;
            current_level = current_level + 1;
        end
        
        // Complete
        #100;
        bfs_done = 1;
        bfs_busy = 0;
        nodes_visited_count = 32;
        edges_scanned_count = 140;
        current_level = 5;
        
        // TEST 4: Read Status
        $display("\n[%0t] ═══ TEST 4: Read Final Status ═══", $time);
        #100;
        axi_read(ADDR_STATUS_REG, read_data);
        axi_read(ADDR_NODES_VISITED, read_data);
        axi_read(ADDR_EDGES_SCANNED, read_data);
        axi_read(ADDR_BFS_LEVEL, read_data);
        
        #500;
        $display("\n[%0t] ✓ TEST COMPLETE!", $time);
        $finish;
    end
    
    // VCD Dump
    initial begin
        $dumpfile("bfs_csr_tb.vcd");
        $dumpvars(0, bfs_csr_tb);
    end

endmodule
