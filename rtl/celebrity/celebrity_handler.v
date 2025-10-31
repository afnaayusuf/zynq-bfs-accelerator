// celebrity_handler.v
`timescale 1ns / 1ps

module celebrity_handler (
    input wire clk,
    input wire rst_n,
    input wire [1:0] node_class, // New 2-bit input
    input wire [31:0] celebrity_node_id,
    output reg special_handling_enabled
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            special_handling_enabled <= 1'b0;
        end else begin
            // Enable special handling if the node class is not Normal (00)
            if (node_class != 2'b00) begin
                special_handling_enabled <= 1'b1;
            end else begin
                special_handling_enabled <= 1'b0;
            end
        end
    end

endmodule
