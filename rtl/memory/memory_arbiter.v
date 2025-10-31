
`timescale 1ns / 1ps

module memory_arbiter #(
    parameter NUM_PU = `NUM_PU,
    parameter PU_INDEX_WIDTH = 4  // $clog2(NUM_PU) for NUM_PU=16
) (
    input wire clk,
    input wire rst_n,

    // AXI4 Master Interface (to Memory)
    output wire [31:0] m_axi_araddr,
    output wire [7:0] m_axi_arlen,
    output wire [2:0] m_axi_arsize,
    output wire [1:0] m_axi_arburst,
    output wire m_axi_arvalid,
    input wire m_axi_arready,

    input wire [63:0] m_axi_rdata,
    input wire m_axi_rvalid,
    input wire m_axi_rlast,
    output wire m_axi_rready,

    // AXI4 Slave Interfaces (from PUs)
    input wire [NUM_PU-1:0] s_axi_arvalid,
    output wire [NUM_PU-1:0] s_axi_arready,
    input wire [32*NUM_PU-1:0] s_axi_araddr,
    input wire [8*NUM_PU-1:0] s_axi_arlen,
    input wire [3*NUM_PU-1:0] s_axi_arsize,
    input wire [2*NUM_PU-1:0] s_axi_arburst,

    output wire [64*NUM_PU-1:0] s_axi_rdata,
    output wire [NUM_PU-1:0] s_axi_rvalid,
    output wire [NUM_PU-1:0] s_axi_rlast,
    input wire [NUM_PU-1:0] s_axi_rready
);

    reg [PU_INDEX_WIDTH-1:0] grant;
    reg [PU_INDEX_WIDTH-1:0] next_grant;
    integer i;

    // Simple round-robin arbitration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant <= 0;
        end else begin
            if (m_axi_arready && m_axi_arvalid) begin
                grant <= next_grant;
            end
        end
    end

    // This implementation of a round-robin arbiter gives priority to the requestors
    // in order, starting from the one after the last grant.
    always @(*) begin
        next_grant = grant; // Default to keeping the grant if no other request is active
        // Search for next requester in round-robin fashion
        for (i = 1; i < NUM_PU; i = i + 1) begin
            if (grant + i < NUM_PU) begin
                if (s_axi_arvalid[grant + i]) begin
                    next_grant = grant + i;
                end
            end else begin
                if (s_axi_arvalid[(grant + i) - NUM_PU]) begin
                    next_grant = (grant + i) - NUM_PU;
                end
            end
        end
    end

    // Connect granted PU to memory
    assign m_axi_araddr = s_axi_araddr[grant*32 +: 32];
    assign m_axi_arlen = s_axi_arlen[grant*8 +: 8];
    assign m_axi_arsize = s_axi_arsize[grant*3 +: 3];
    assign m_axi_arburst = s_axi_arburst[grant*2 +: 2];
    assign m_axi_arvalid = s_axi_arvalid[grant];

    // Connect memory to granted PU
    genvar j;
    generate
        for (j = 0; j < NUM_PU; j = j + 1) begin : r_channel
            assign s_axi_rdata[j*64 +: 64] = (j == grant) ? m_axi_rdata : 64'b0;
            assign s_axi_rvalid[j] = (j == grant) ? m_axi_rvalid : 1'b0;
            assign s_axi_rlast[j] = (j == grant) ? m_axi_rlast : 1'b0;
        end
    endgenerate

    assign m_axi_rready = s_axi_rready[grant];

    // Set arready for all PUs
    genvar k;
    generate
        for (k = 0; k < NUM_PU; k = k + 1) begin : ar_ready_gen
            assign s_axi_arready[k] = (k == grant) ? m_axi_arready : 1'b0;
        end
    endgenerate

endmodule
