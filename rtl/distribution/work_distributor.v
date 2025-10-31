// work_distributor.v
`timescale 1ns / 1ps

module work_distributor #(
    parameter NUM_PE = 4,
    parameter DATA_WIDTH = 32,
    parameter PE_INDEX_WIDTH = 2  // $clog2(NUM_PE)
) (
    input wire clk,
    input wire rst_n,

    // Input work stream
    input wire [DATA_WIDTH-1:0] in_data,
    input wire                  in_valid,
    output wire                 in_ready,

    // Output work streams (flattened arrays)
    output wire [NUM_PE*DATA_WIDTH-1:0] out_data,
    output wire [NUM_PE-1:0]            out_valid,
    input wire [NUM_PE-1:0]             out_ready
);

    reg [PE_INDEX_WIDTH-1:0] current_pe;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_pe <= 0;
        end else if (in_valid && in_ready) begin
            if (current_pe == NUM_PE - 1) begin
                current_pe <= 0;
            end else begin
                current_pe <= current_pe + 1;
            end
        end
    end

    assign in_ready = out_ready[current_pe];

    genvar i;
    generate
        for (i = 0; i < NUM_PE; i = i + 1) begin : out_ports
            assign out_data[i*DATA_WIDTH +: DATA_WIDTH] = (i == current_pe) ? in_data : {DATA_WIDTH{1'b0}};
            assign out_valid[i] = (i == current_pe) && in_valid;
        end
    endgenerate

endmodule
