`timescale 1ns / 1ps


// The Lookahead Statistics Engine (LSE)
// This module reads a list of node IDs from a frontier buffer, fetches the degree
// for each one, and calculates the average degree for that frontier.

module lookahead_stats_engine #(
    // Assuming a simple graph structure where node metadata (like degree) is indexed by node ID
    parameter NODE_METADATA_STRIDE = 8, // e.g., 8 bytes per node entry
    parameter AXI_ADDR_WIDTH = `AXI_ADDR_WIDTH,
    parameter AXI_DATA_WIDTH = `AXI_DATA_WIDTH
) (
    input wire clk,
    input wire rst_n,

    // Control Interface
    input wire start_analysis,
    input wire [AXI_ADDR_WIDTH-1:0] frontier_buffer_base_addr,
    input wire [31:0] num_nodes_in_frontier,
    input wire [AXI_ADDR_WIDTH-1:0] graph_base_addr,
    output reg analysis_done,

    // AXI Master Interface (for reading node degrees)
    output reg [AXI_ADDR_WIDTH-1:0] m_axi_araddr,
    output reg                      m_axi_arvalid,
    input  wire                      m_axi_arready,
    input  wire [AXI_DATA_WIDTH-1:0]  m_axi_rdata,
    input  wire                      m_axi_rvalid,
    output wire                      m_axi_rready,

    // Output to Main Execution Engine's CSR
    output reg [31:0] calculated_medium_threshold,
    output reg [31:0] calculated_high_threshold
);

    // FSM states
    localparam IDLE           = 3'd0;
    localparam READ_NODE_ID   = 3'd1;
    localparam WAIT_FOR_DEGREE = 3'd2;
    localparam CALC_STATS     = 3'd3;
    
    reg [2:0] state;

    reg [31:0] node_counter;
    reg [63:0] sum_of_degrees;
    reg [31:0] current_node_id;
    reg [31:0] current_node_degree;
    reg [31:0] avg_degree;

    assign m_axi_rready = (state == WAIT_FOR_DEGREE); // Always ready to accept degree data

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            analysis_done <= 1'b0;
            node_counter <= 0;
            sum_of_degrees <= 0;
            m_axi_arvalid <= 1'b0;
            m_axi_araddr <= 0;
            calculated_medium_threshold <= 0;
            calculated_high_threshold <= 0;
            avg_degree <= 0;
        end else begin
            analysis_done <= 1'b0;
            m_axi_arvalid <= 1'b0;

            case (state)
                IDLE: begin
                    if (start_analysis) begin
                        state <= READ_NODE_ID;
                        node_counter <= 0;
                        sum_of_degrees <= 0;
                    end
                end

                READ_NODE_ID: begin
                    if (node_counter < num_nodes_in_frontier) begin
                        // For this sketch, we assume node IDs are read from the frontier buffer
                        // A full implementation would have another AXI master for that.
                        // Here, we simplify and assume we can get the node ID to look up its degree.
                        // Let's assume we are reading the degree of node `node_counter` for simplicity.
                        m_axi_araddr <= graph_base_addr + (node_counter * NODE_METADATA_STRIDE);
                        m_axi_arvalid <= 1'b1;
                        state <= WAIT_FOR_DEGREE;
                    end else begin
                        state <= CALC_STATS;
                    end
                end

                WAIT_FOR_DEGREE: begin
                    if (m_axi_arvalid && m_axi_arready) begin
                        m_axi_arvalid <= 1'b0;
                    end
                    if (m_axi_rvalid) begin
                        // Assuming degree is in the first 32 bits of the returned data
                        current_node_degree <= m_axi_rdata[31:0];
                        sum_of_degrees <= sum_of_degrees + m_axi_rdata[31:0];
                        node_counter <= node_counter + 1;
                        state <= READ_NODE_ID;
                    end
                end

                CALC_STATS: begin
                    if (num_nodes_in_frontier > 0) begin
                        avg_degree <= sum_of_degrees / num_nodes_in_frontier;
                        // Set thresholds based on the calculated average
                        calculated_medium_threshold <= (sum_of_degrees / num_nodes_in_frontier) * 2; // e.g., 2x the average
                        calculated_high_threshold   <= (sum_of_degrees / num_nodes_in_frontier) * 8; // e.g., 8x the average
                    end
                    analysis_done <= 1'b1;
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule
