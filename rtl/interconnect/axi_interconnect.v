`timescale 1ns / 1ps

// 3-to-1 AXI4 Read-Only Interconnect

module axi_interconnect #(
    parameter NUM_MASTERS = 4,
    parameter MASTER_INDEX_WIDTH = 2,  // $clog2(NUM_MASTERS)
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_DATA_WIDTH = 64
) (
    input wire clk,
    input wire rst_n,

    // AXI Slave Interfaces (from system modules)
    input wire [NUM_MASTERS-1:0]                            s_axi_arvalid,
    output wire [NUM_MASTERS-1:0]                           s_axi_arready,
    input wire [NUM_MASTERS*AXI_ADDR_WIDTH-1:0]             s_axi_araddr,

    output wire [NUM_MASTERS*AXI_DATA_WIDTH-1:0]            s_axi_rdata,
    output wire [NUM_MASTERS-1:0]                           s_axi_rvalid,
    output wire [NUM_MASTERS-1:0]                           s_axi_rlast,
    input wire [NUM_MASTERS-1:0]                            s_axi_rready,

    // AXI Master Interface (to memory controller)
    output wire [AXI_ADDR_WIDTH-1:0]                        m_axi_araddr,
    output wire                                             m_axi_arvalid,
    input wire                                              m_axi_arready,

    input wire [AXI_DATA_WIDTH-1:0]                         m_axi_rdata,
    input wire                                              m_axi_rvalid,
    input wire                                              m_axi_rlast,
    output wire                                             m_axi_rready
);

    // State for round-robin arbitration
    reg [MASTER_INDEX_WIDTH-1:0] grant;
    reg [MASTER_INDEX_WIDTH-1:0] next_grant;
    reg m_axi_arvalid_reg;

    localparam S_IDLE = 0, S_BUSY = 1;
    reg state;
    
    integer i;

    // Simple round-robin arbiter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant <= 0;
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE && |s_axi_arvalid) begin
                state <= S_BUSY;
                // Find the first requesting master
                grant <= 0;  // Default
                for (i = 0; i < NUM_MASTERS; i = i + 1) begin
                    if (s_axi_arvalid[i] && grant == 0) begin
                        grant <= i;
                    end
                end
            end else if (state == S_BUSY && m_axi_arvalid && m_axi_arready) begin
                // Grant is passed, wait for read to complete
            end else if (m_axi_rvalid && m_axi_rlast) begin
                // Read complete, find next grant
                state <= S_IDLE;
                next_grant = grant + 1;
                if (next_grant >= NUM_MASTERS) next_grant = 0;
                
                // Round-robin search for next master
                grant <= next_grant;
                for (i = 0; i < NUM_MASTERS; i = i + 1) begin
                    if (s_axi_arvalid[next_grant]) begin
                        grant <= next_grant;
                    end
                    next_grant = next_grant + 1;
                    if (next_grant >= NUM_MASTERS) next_grant = 0;
                end
            end
        end
    end

    // Multiplex the AR channel from the granted master
    assign m_axi_araddr = s_axi_araddr[grant*AXI_ADDR_WIDTH +: AXI_ADDR_WIDTH];
    assign m_axi_arvalid = s_axi_arvalid[grant] && (state == S_IDLE);

    // Assign ARREADY to the granted master
    genvar j;
    generate
        for (j = 0; j < NUM_MASTERS; j = j + 1) begin : arready_assign
            assign s_axi_arready[j] = (j == grant) && m_axi_arready && (state == S_BUSY);
        end
    endgenerate

    // Route the R channel back to the granted master
    assign m_axi_rready = s_axi_rready[grant];

    genvar k;
    generate
        for (k = 0; k < NUM_MASTERS; k = k + 1) begin : rdata_assign
            assign s_axi_rdata[k*AXI_DATA_WIDTH +: AXI_DATA_WIDTH] = (k == grant) ? m_axi_rdata : {AXI_DATA_WIDTH{1'b0}};
            assign s_axi_rvalid[k] = (k == grant) ? m_axi_rvalid : 1'b0;
            assign s_axi_rlast[k] = (k == grant) ? m_axi_rlast : 1'b0;
        end
    endgenerate

endmodule
