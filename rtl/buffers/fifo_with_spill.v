`timescale 1ns / 1ps

module fifo_with_spill #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 1024,
    parameter SPILL_THRESHOLD = 900,
    parameter FILL_THRESHOLD = 100
) (
    // Clock and Reset
    input wire clk,
    input wire rst_n,

    // Write Port
    input  wire wr_en,
    input  wire [DATA_WIDTH-1:0] wr_data,
    output wire full,

    // Read Port
    input  wire rd_en,
    output wire [DATA_WIDTH-1:0] rd_data,
    output wire empty,

    // Spill/Fill Interface (to Buffer Manager)
    output reg spill_req,
    input  wire spill_grant,
    output wire [DATA_WIDTH-1:0] spill_data,
    output wire spill_data_valid,
    input  wire spill_data_ready,

    output reg fill_req,
    input  wire fill_grant,
    input  wire [DATA_WIDTH-1:0] fill_data,
    input  wire fill_data_valid,
    output wire fill_data_ready
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH):0] wr_ptr, rd_ptr;
    reg [$clog2(DEPTH)+1:0] count;

    assign full = (count == DEPTH);
    assign empty = (count == 0);

    // FSM for spill/fill data transfer
    localparam [1:0] IDLE = 2'b00;
    localparam [1:0] SPILLING = 2'b01;
    localparam [1:0] FILLING = 2'b10;
    reg [1:0] state;

    // Handshake signals for data transfer
    wire spill_transfer, fill_transfer;
    wire normal_read, normal_write;
    wire [$clog2(DEPTH):0] spill_ptr;

    // Calculate spill pointer (one before write pointer)
    assign spill_ptr = wr_ptr - 1;

    // The consumer reads from the head of the queue
    assign rd_data = mem[rd_ptr[$clog2(DEPTH)-1:0]];

    // The buffer manager spills from the tail of the queue
    assign spill_data = mem[spill_ptr[$clog2(DEPTH)-1:0]];
    assign spill_data_valid = (state == SPILLING) && (count > 0);

    // Determine when transfers are happening
    assign normal_write = wr_en && !full;
    assign normal_read  = rd_en && !empty;
    assign spill_transfer = spill_data_valid && spill_data_ready;
    assign fill_transfer  = fill_data_valid && (state == FILLING) && !full;
    assign fill_data_ready = (state == FILLING) && !full;

    // Spill/Fill Request Logic
    always @(*) begin
        spill_req = (count >= SPILL_THRESHOLD) && (state == IDLE);
        fill_req = (count <= FILL_THRESHOLD) && (state == IDLE);
    end

    // Main synchronous block for state, pointers, and counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
            state  <= IDLE;
        end else begin
            // State transitions
            case (state)
                IDLE: begin
                    if (spill_grant)      state <= SPILLING;
                    else if (fill_grant) state <= FILLING;
                end
                SPILLING: begin
                    if (!spill_grant) state <= IDLE;
                end
                FILLING: begin
                    if (!fill_grant) state <= IDLE;
                end
            endcase

            // Pointer and Counter Logic
            // Note: Spilling removes the most recent write, so it decrements the write pointer.
            // Normal reads increment the read pointer.
            // Fills act like a normal write.

            if (normal_write && !spill_transfer) begin
                mem[wr_ptr[$clog2(DEPTH)-1:0]] <= wr_data;
                wr_ptr <= wr_ptr + 1;
            end else if (spill_transfer && !normal_write) begin
                wr_ptr <= wr_ptr - 1; // Pop the tail
            end

            if (normal_read) begin
                rd_ptr <= rd_ptr + 1;
            end

            if (fill_transfer) begin
                mem[wr_ptr[$clog2(DEPTH)-1:0]] <= fill_data;
                wr_ptr <= wr_ptr + 1;
            end

            // Net change in count
            // Calculate writing and reading conditions
            if ((normal_write || fill_transfer) && !(normal_read || spill_transfer)) begin
                count <= count + 1;
            end else if (!(normal_write || fill_transfer) && (normal_read || spill_transfer)) begin
                count <= count - 1;
            end
        end
    end

endmodule
