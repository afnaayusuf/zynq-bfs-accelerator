// work_stealing_scheduler.v
`timescale 1ns / 1ps

module work_stealing_scheduler #(
    parameter NUM_PU = 16,
    parameter QUEUE_DEPTH_WIDTH = 10
) (
    input wire clk,
    input wire rst_n,
    
    // Queue depth monitoring
    input wire [NUM_PU*QUEUE_DEPTH_WIDTH-1:0] pe_queue_depths,  // Flattened array
    input wire [QUEUE_DEPTH_WIDTH-1:0]        dynamic_threshold,
    
    // Work stealing output
    output reg                      steal_request,
    output reg [$clog2(NUM_PU)-1:0] steal_from,
    output reg [$clog2(NUM_PU)-1:0] steal_to
);

    // Extract individual queue depths from flattened input
    wire [QUEUE_DEPTH_WIDTH-1:0] pe_queue_depths_array [0:NUM_PU-1];
    genvar k;
    generate
        for (k = 0; k < NUM_PU; k = k + 1) begin : extract_depths
            assign pe_queue_depths_array[k] = pe_queue_depths[k*QUEUE_DEPTH_WIDTH +: QUEUE_DEPTH_WIDTH];
        end
    endgenerate

    // Identify potential victims and thieves in parallel
    wire [NUM_PU-1:0] is_victim;
    wire [NUM_PU-1:0] is_thief;
    genvar i;
    generate
        for (i = 0; i < NUM_PU; i = i + 1) begin : victim_thief_detect
            assign is_victim[i] = pe_queue_depths_array[i] > dynamic_threshold;
            assign is_thief[i]  = (pe_queue_depths_array[i] == 0); // Only steal if completely empty
        end
    endgenerate

    // Find the first victim and first thief (priority encoding)
    wire [$clog2(NUM_PU)-1:0] victim_idx;
    wire [$clog2(NUM_PU)-1:0] thief_idx;
    wire victim_found = |is_victim;
    wire thief_found = |is_thief;

    // A synthesizable priority encoder
    // This can be replaced with a dedicated IP block for better performance
    assign victim_idx = is_victim[0] ? 0 :
                      is_victim[1] ? 1 :
                      is_victim[2] ? 2 :
                      is_victim[3] ? 3 :
                      is_victim[4] ? 4 :
                      is_victim[5] ? 5 :
                      is_victim[6] ? 6 :
                      is_victim[7] ? 7 :
                      is_victim[8] ? 8 :
                      is_victim[9] ? 9 :
                      is_victim[10] ? 10 :
                      is_victim[11] ? 11 :
                      is_victim[12] ? 12 :
                      is_victim[13] ? 13 :
                      is_victim[14] ? 14 : 15;

    assign thief_idx =  is_thief[0] ? 0 :
                      is_thief[1] ? 1 :
                      is_thief[2] ? 2 :
                      is_thief[3] ? 3 :
                      is_thief[4] ? 4 :
                      is_thief[5] ? 5 :
                      is_thief[6] ? 6 :
                      is_thief[7] ? 7 :
                      is_thief[8] ? 8 :
                      is_thief[9] ? 9 :
                      is_thief[10] ? 10 :
                      is_thief[11] ? 11 :
                      is_thief[12] ? 12 :
                      is_thief[13] ? 13 :
                      is_thief[14] ? 14 : 15;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            steal_request <= 1'b0;
            steal_from    <= 0;
            steal_to      <= 0;
        end else begin
            // A steal is possible if we found at least one of each, and they are not the same PU
            if (victim_found && thief_found && (victim_idx != thief_idx)) begin
                steal_request <= 1'b1;
                steal_from    <= victim_idx;
                steal_to      <= thief_idx;
            end else begin
                steal_request <= 1'b0;
            end
        end
    end

endmodule
