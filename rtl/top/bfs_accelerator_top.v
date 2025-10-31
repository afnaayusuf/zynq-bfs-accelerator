`timescale 1ns / 1ps

module bfs_accelerator_top #(
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_DATA_WIDTH = 64
) (
    // Clock and Reset
    input wire aclk,
    input wire aresetn,

    // AXI4-Lite Control Interface
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

    // AXI4 Memory Interface
    output wire [AXI_ADDR_WIDTH-1:0]             m_axi_araddr,
    output wire [7:0]                               m_axi_arlen,
    output wire                                   m_axi_arvalid,
    input  wire                                   m_axi_arready,
    input  wire [AXI_DATA_WIDTH-1:0]             m_axi_rdata,
    input  wire                                   m_axi_rlast,
    input  wire [1:0]                              m_axi_rresp,
    input  wire                                   m_axi_rvalid,
    output wire                                   m_axi_rready,
    
    // AXI4 Write Interface (tied off - not used)
    input  wire                                   m_axi_awready,
    input  wire                                   m_axi_wready,
    input  wire                                   m_axi_bvalid,
    input  wire [1:0]                              m_axi_bresp,

    // Interrupt
    output wire interrupt
);

    // Instantiate the integrated system
    bfs_system_integrated dut (
        .clk(aclk),
        .rst_n(aresetn),

        // AXI4-Lite Slave Interface
        .s_axi_lite_awvalid(s_axi_lite_awvalid),
        .s_axi_lite_awaddr(s_axi_lite_awaddr),
        .s_axi_lite_awready(s_axi_lite_awready),
        .s_axi_lite_wvalid(s_axi_lite_wvalid),
        .s_axi_lite_wdata(s_axi_lite_wdata),
        .s_axi_lite_wstrb(s_axi_lite_wstrb),
        .s_axi_lite_wready(s_axi_lite_wready),
        .s_axi_lite_bvalid(s_axi_lite_bvalid),
        .s_axi_lite_bresp(s_axi_lite_bresp),
        .s_axi_lite_bready(s_axi_lite_bready),
        .s_axi_lite_arvalid(s_axi_lite_arvalid),
        .s_axi_lite_araddr(s_axi_lite_araddr),
        .s_axi_lite_arready(s_axi_lite_arready),
        .s_axi_lite_rvalid(s_axi_lite_rvalid),
        .s_axi_lite_rdata(s_axi_lite_rdata),
        .s_axi_lite_rresp(s_axi_lite_rresp),
        .s_axi_lite_rready(s_axi_lite_rready),

        // AXI4 Master Interface (Read-Only)
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

endmodule
