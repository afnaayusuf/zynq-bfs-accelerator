// crossbar_switch.v
`timescale 1ns / 1ps

module crossbar_switch #(
    parameter NUM_PU = 16,
    parameter NODE_BITS = 32
) (
    input wire clk,
    input wire rst_n,
    
    // Input from PUs (flattened arrays)
    input wire [NUM_PU*NODE_BITS-1:0] in_data,
    input wire [NUM_PU-1:0]           in_valid,
    output wire [NUM_PU-1:0]          in_ready,
    
    // Output to PUs (flattened arrays)
    output wire [NUM_PU*NODE_BITS-1:0] out_data,
    output wire [NUM_PU-1:0]           out_valid,
    input wire [NUM_PU-1:0]            out_ready,
    
    // Work stealing control
    input wire                      steal_en,
    input wire [$clog2(NUM_PU)-1:0] steal_from,
    input wire [$clog2(NUM_PU)-1:0] steal_to
);

    reg [NODE_BITS-1:0] out_data_reg [0:NUM_PU-1];
    reg                  out_valid_reg [0:NUM_PU-1];
    reg                  in_ready_reg [0:NUM_PU-1];

    integer i;
    
    // Extract individual signals from flattened arrays
    wire [NODE_BITS-1:0] in_data_array [0:NUM_PU-1];
    genvar k;
    generate
        for (k = 0; k < NUM_PU; k = k + 1) begin : extract_inputs
            assign in_data_array[k] = in_data[k*NODE_BITS +: NODE_BITS];
        end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < NUM_PU; i = i + 1) begin
                out_data_reg[i] <= 0;
                out_valid_reg[i] <= 0;
                in_ready_reg[i] <= 1;
            end
        end else begin
            // Default: no stealing, pass through
            for (i = 0; i < NUM_PU; i = i + 1) begin
                out_data_reg[i] <= in_data_array[i];
                out_valid_reg[i] <= in_valid[i];
                in_ready_reg[i] <= out_ready[i];
            end

            // Work stealing connection
            if (steal_en) begin
                // The 'thief' gets data from the 'victim'
                out_data_reg[steal_to]  <= in_data_array[steal_from];
                out_valid_reg[steal_to] <= in_valid[steal_from];
                in_ready_reg[steal_from]<= out_ready[steal_to];

                // The 'victim' gets its own input blocked if the thief is not ready
                // And the thief's original input is blocked
                in_ready_reg[steal_to] <= 1'b0; // Don't accept new work, you are stealing
            end
        end
    end

    // Assign registered outputs to flattened ports
    genvar j;
    generate
        for (j = 0; j < NUM_PU; j = j + 1) begin : assign_outputs
            assign out_data[j*NODE_BITS +: NODE_BITS] = out_data_reg[j];
            assign out_valid[j] = out_valid_reg[j];
            assign in_ready[j] = in_ready_reg[j];
        end
    endgenerate

endmodule
