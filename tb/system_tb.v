`timescale 1ns / 1ps

module system_tb;

    // Parameters
    localparam AXI_ADDR_WIDTH = 12;
    localparam AXI_DATA_WIDTH = 32;
    localparam CLK_PERIOD = 10;

    // Signals
    reg aclk;
    reg aresetn;
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
    wire interrupt;

    // AXI4 Master Interface signals (flattened from interface)
    wire [31:0] m_axi_araddr;
    wire [7:0] m_axi_arlen;
    wire m_axi_arvalid;
    reg m_axi_arready;
    reg [63:0] m_axi_rdata;
    reg [1:0] m_axi_rresp;
    reg m_axi_rlast;
    reg m_axi_rvalid;
    wire m_axi_rready;

    // Instantiate the DUT
    bfs_system_integrated #(
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(64)
    ) dut (
        .clk(aclk),
        .rst_n(aresetn),
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
        .m_axi_araddr(m_axi_araddr),
        .m_axi_arlen(m_axi_arlen),
        .m_axi_arvalid(m_axi_arvalid),
        .m_axi_arready(m_axi_arready),
        .m_axi_rdata(m_axi_rdata),
        .m_axi_rlast(m_axi_rlast),
        .m_axi_rresp(m_axi_rresp),
        .m_axi_rvalid(m_axi_rvalid),
        .m_axi_rready(m_axi_rready),
        .global_done(interrupt)
    );

    // Clock generation
    always #(CLK_PERIOD/2) aclk = ~aclk;
    
    // Simple AXI memory model
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            m_axi_arready <= 1'b0;
            m_axi_rvalid <= 1'b0;
            m_axi_rlast <= 1'b0;
            m_axi_rdata <= 0;
            m_axi_rresp <= 2'b00;
        end else begin
            // Simple handshake
            if (m_axi_arvalid) begin
                m_axi_arready <= 1'b1;
                m_axi_rvalid <= 1'b1;
                m_axi_rlast <= 1'b1;
                m_axi_rdata <= 64'hDEADBEEFCAFEBABE;
            end else begin
                m_axi_arready <= 1'b0;
                if (m_axi_rready) begin
                    m_axi_rvalid <= 1'b0;
                    m_axi_rlast <= 1'b0;
                end
            end
        end
    end

    // Test sequence
    initial begin
        // Initialize signals
        aclk = 0;
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
        #100 aresetn = 1;
        #50;

        // Write to a config register
        $display("Writing to config register at time %0t", $time);
        s_axi_awaddr = 12'h004; // Start Node Address
        s_axi_wdata = 32'h12345678;
        s_axi_awvalid = 1;
        s_axi_wvalid = 1;
        s_axi_wstrb = 4'b1111;
        @(posedge aclk);
        while (!(s_axi_awready && s_axi_wready)) @(posedge aclk);
        s_axi_awvalid = 0;
        s_axi_wvalid = 0;
        #50;

        // Read from a status register
        $display("Reading from status register at time %0t", $time);
        s_axi_araddr = 12'h010; // Status Register
        s_axi_arvalid = 1;
        @(posedge aclk);
        while (!s_axi_arready) @(posedge aclk);
        s_axi_arvalid = 0;
        while (!s_axi_rvalid) @(posedge aclk);
        $display("Read data: 0x%h at time %0t", s_axi_rdata, $time);

        // End simulation
        #100;
        $display("Test completed at time %0t", $time);
        $finish;
    end
    
    // VCD dump for waveform viewing
    initial begin
        $dumpfile("system_tb.vcd");
        $dumpvars(0, system_tb);
    end

endmodule
