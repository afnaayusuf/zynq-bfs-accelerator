// threshold_calculator.v
`timescale 1ns / 1ps

module threshold_calculator #(
    parameter NUM_PE = 4,
    parameter QUEUE_DEPTH_WIDTH = 8,
    parameter PE_INDEX_WIDTH = 2  // $clog2(NUM_PE) for NUM_PE=4
) (
    input wire clk,
    input wire rst_n,

    input wire [NUM_PE*QUEUE_DEPTH_WIDTH-1:0] pe_queue_depths,  // Flattened array
    output reg [QUEUE_DEPTH_WIDTH-1:0] dynamic_threshold
);

    reg [QUEUE_DEPTH_WIDTH+PE_INDEX_WIDTH-1:0] sum_of_depths;
    wire [QUEUE_DEPTH_WIDTH-1:0] pe_queue_depths_array [0:NUM_PE-1];
    integer i;
    
    // Extract individual queue depths from flattened input
    genvar j;
    generate
        for (j = 0; j < NUM_PE; j = j + 1) begin : extract_depths
            assign pe_queue_depths_array[j] = pe_queue_depths[j*QUEUE_DEPTH_WIDTH +: QUEUE_DEPTH_WIDTH];
        end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_of_depths <= 0;
            dynamic_threshold <= 0;
        end else begin
            sum_of_depths = 0;
            for (i = 0; i < NUM_PE; i = i + 1) begin
                sum_of_depths = sum_of_depths + pe_queue_depths[i];
            end
            dynamic_threshold <= sum_of_depths / NUM_PE; // Simple average
        end
    end

endmodule
