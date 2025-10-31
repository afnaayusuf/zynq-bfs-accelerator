// celebrity_detector.v
`timescale 1ns / 1ps

module celebrity_detector (
    input wire clk,
    input wire rst_n,
    input wire [31:0] node_degree,
    input wire [31:0] high_degree_threshold,
    input wire [31:0] medium_degree_threshold,
    output reg [1:0] node_class // 00: Normal, 01: Medium, 10: High
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            node_class <= 2'b00;
        end else begin
            if (node_degree > high_degree_threshold) begin
                node_class <= 2'b10; // High degree
            end else if (node_degree > medium_degree_threshold) begin
                node_class <= 2'b01; // Medium degree
            end else begin
                node_class <= 2'b00; // Normal degree
            end
        end
    end

endmodule
