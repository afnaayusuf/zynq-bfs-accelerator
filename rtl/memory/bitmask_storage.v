
`timescale 1ns / 1ps

module bitmask_storage #(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 32
) (
    input wire clk,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    assign dout = mem[addr];

    always @(posedge clk) begin
        if (we) begin
            mem[addr] <= din;
        end
    end

endmodule
