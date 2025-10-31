
`timescale 1ns / 1ps

module visited_checker #(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 32
) (
    input wire clk,
    input wire rst_n,
    input wire check_en,
    input wire [ADDR_WIDTH-1:0] node_addr,
    input wire [DATA_WIDTH-1:0] bitmask_in,
    output reg [DATA_WIDTH-1:0] bitmask_out,
    output reg visited,
    output reg update_en
);

    reg [4:0] bit_offset;

    always @(*) begin
        // Calculate bit offset within word (modulo 32)
        bit_offset = node_addr[4:0];  // Bottom 5 bits = modulo 32
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            visited <= 0;
            update_en <= 0;
            bitmask_out <= 0;
        end else if (check_en) begin
            if (!bitmask_in[bit_offset]) begin
                visited <= 0;
                update_en <= 1;
                bitmask_out <= bitmask_in | (1 << bit_offset);
            end else begin
                visited <= 1;
                update_en <= 0;
                bitmask_out <= bitmask_in;
            end
        end else begin
            visited <= 0;
            update_en <= 0;
            bitmask_out <= 0;
        end
    end

endmodule
