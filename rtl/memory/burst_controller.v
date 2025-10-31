
`timescale 1ns / 1ps

module burst_controller (
    input wire clk,
    input wire rst_n,

    // AXI4 Interface
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

    // Control Interface
    input wire [31:0] start_addr,
    input wire [7:0] burst_len,
    input wire start_burst,
    output wire burst_done
);

    reg [31:0] araddr_reg;
    reg [7:0] arlen_reg;
    reg arvalid_reg;
    reg rready_reg;
    reg burst_done_reg;

    localparam IDLE = 0, BURST_REQ = 1, BURST_READ = 2;
    reg [1:0] state;

    assign m_axi_araddr = araddr_reg;
    assign m_axi_arlen = arlen_reg;
    assign m_axi_arsize = 3'b011; // 8 bytes (64-bit)
    assign m_axi_arburst = 2'b01; // INCR
    assign m_axi_arvalid = arvalid_reg;
    assign m_axi_rready = rready_reg;
    assign burst_done = burst_done_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            araddr_reg <= 32'b0;
            arlen_reg <= 8'b0;
            arvalid_reg <= 1'b0;
            rready_reg <= 1'b0;
            burst_done_reg <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    burst_done_reg <= 1'b0;
                    if (start_burst) begin
                        araddr_reg <= start_addr;
                        arlen_reg <= burst_len - 1;
                        arvalid_reg <= 1'b1;
                        state <= BURST_REQ;
                    end
                end
                BURST_REQ: begin
                    if (m_axi_arready) begin
                        arvalid_reg <= 1'b0;
                        rready_reg <= 1'b1;
                        state <= BURST_READ;
                    end
                end
                BURST_READ: begin
                    if (m_axi_rvalid && m_axi_rlast) begin
                        rready_reg <= 1'b0;
                        burst_done_reg <= 1'b1;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule
