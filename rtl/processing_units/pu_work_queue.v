`timescale 1ns / 1ps

module pu_work_queue #(
    parameter NODE_BITS   = 32,
    parameter QUEUE_DEPTH = 1024
) (
    input wire clk,
    input wire rst_n,

    // Write interface
    input  wire                  wr_en,
    input  wire [NODE_BITS-1:0]  wr_data,
    output wire                  full,

    // Read interface
    input  wire                  rd_en,
    output wire [NODE_BITS-1:0]  rd_data,
    output wire                  empty
);

    localparam ADDR_BITS = 10;  // $clog2(1024) = 10

    reg [NODE_BITS-1:0] mem [0:QUEUE_DEPTH-1];
    reg [ADDR_BITS:0]   wr_ptr, rd_ptr;
    reg                 is_full, is_empty;

    assign rd_data = mem[rd_ptr[ADDR_BITS-1:0]];
    assign full    = is_full;
    assign empty   = is_empty;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end else begin
            if (wr_en && !full) begin
                mem[wr_ptr[ADDR_BITS-1:0]] <= wr_data;
                wr_ptr <= wr_ptr + 1;
            end
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1;
            end
        end
    end

    always @(*) begin
        is_full  = (wr_ptr[ADDR_BITS] != rd_ptr[ADDR_BITS]) && (wr_ptr[ADDR_BITS-1:0] == rd_ptr[ADDR_BITS-1:0]);
        is_empty = (wr_ptr == rd_ptr);
    end

endmodule
