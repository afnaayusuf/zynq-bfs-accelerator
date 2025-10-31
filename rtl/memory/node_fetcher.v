
`timescale 1ns / 1ps

module node_fetcher #(
    parameter DATA_WIDTH = 64
) (
    input wire clk,
    input wire rst_n,

    // AXI4 Master Interface
    output wire [31:0] m_axi_araddr,
    output wire [7:0] m_axi_arlen,
    output wire [2:0] m_axi_arsize,
    output wire [1:0] m_axi_arburst,
    output wire m_axi_arvalid,
    input wire m_axi_arready,

    input wire [DATA_WIDTH-1:0] m_axi_rdata,
    input wire m_axi_rvalid,
    input wire m_axi_rlast,
    output wire m_axi_rready,

    // Node Fetch Interface
    input wire [31:0] node_addr,
    input wire [7:0] num_nodes, // Number of nodes to fetch
    input wire fetch_start,
    output wire fetch_done,

    // Data Output
    output wire [DATA_WIDTH-1:0] node_data,
    output wire node_data_valid
);

    wire burst_done;
    reg fetch_done_reg;
    reg node_data_valid_reg;

    burst_controller i_burst_controller (
        .clk(clk),
        .rst_n(rst_n),
        .m_axi_araddr(m_axi_araddr),
        .m_axi_arlen(m_axi_arlen),
        .m_axi_arsize(m_axi_arsize),
        .m_axi_arburst(m_axi_arburst),
        .m_axi_arvalid(m_axi_arvalid),
        .m_axi_arready(m_axi_arready),
        .m_axi_rdata(m_axi_rdata),
        .m_axi_rvalid(m_axi_rvalid),
        .m_axi_rlast(m_axi_rlast),
        .m_axi_rready(m_axi_rready),
        .start_addr(node_addr),
        .burst_len(num_nodes),
        .start_burst(fetch_start),
        .burst_done(burst_done)
    );

    assign fetch_done = fetch_done_reg;
    assign node_data = m_axi_rdata;
    assign node_data_valid = m_axi_rvalid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fetch_done_reg <= 1'b0;
        end else begin
            if (burst_done) begin
                fetch_done_reg <= 1'b1;
            end else if (fetch_start) begin
                fetch_done_reg <= 1'b0;
            end
        end
    end

endmodule
