// work_preallocator.v
`timescale 1ns / 1ps

module work_preallocator (
    input wire clk,
    input wire rst_n,
    input wire [1:0] node_class, // New input
    output reg [$clog2(`NUM_PU):0] preallocated_pus
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            preallocated_pus <= 1;
        end else begin
            case (node_class)
                2'b10:  preallocated_pus <= 12; // High degree node
                2'b01:  preallocated_pus <= 4;  // Medium degree node
                default: preallocated_pus <= 1;  // Normal node
            endcase
        end
    end

endmodule
