`timescale 1ns / 1ps

module prefetch_buffer #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 512,
    parameter PREFETCH_THRESHOLD = 256
) (
    // Clock and Reset
    input wire clk,
    input wire rst_n,

    // Read Port (to consumer)
    input  wire rd_en,
    output wire [DATA_WIDTH-1:0] rd_data,
    output wire empty,

    // Prefetch Interface (to Buffer Manager/AXI)
    output wire prefetch_req,
    input  wire prefetch_grant,
    input  wire [DATA_WIDTH-1:0] prefetch_data,
    input  wire prefetch_data_valid,
    output wire prefetch_data_ready,

    // Control
    input wire [31:0] base_addr,  // AXI_ADDR_WIDTH = 32
    input wire [15:0] total_nodes
);

    // Internal FIFO to store prefetched data
    // Using a simple FIFO model here
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH):0] wr_ptr, rd_ptr;
    reg [$clog2(DEPTH)+1:0] count;

    assign empty = (count == 0);
    assign rd_data = mem[rd_ptr[$clog2(DEPTH)-1:0]];

    // Prefetch control logic
    // Use fixed width for node counters (16 bits to match total_nodes input)
    reg [15:0] nodes_fetched;
    reg [15:0] nodes_consumed;

    assign prefetch_req = (count < PREFETCH_THRESHOLD) && (nodes_fetched < total_nodes);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
            nodes_fetched <= 0;
            nodes_consumed <= 0;
        end else begin
            // Write from prefetch interface
            if (prefetch_data_valid && prefetch_data_ready) begin
                mem[wr_ptr[$clog2(DEPTH)-1:0]] <= prefetch_data;
                wr_ptr <= wr_ptr + 1;
                nodes_fetched <= nodes_fetched + 1;
            end

            // Read by consumer
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1;
                nodes_consumed <= nodes_consumed + 1;
            end

            // Update count
            if ((prefetch_data_valid && prefetch_data_ready) && !(rd_en && !empty)) begin
                count <= count + 1;
            end else if (!(prefetch_data_valid && prefetch_data_ready) && (rd_en && !empty)) begin
                count <= count - 1;
            end
        end
    end

    // Logic to handle prefetch data readiness
    assign prefetch_data_ready = (count < DEPTH);

endmodule
