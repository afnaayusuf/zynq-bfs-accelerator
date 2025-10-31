// SPDX-License-Identifier: Apache-2.0
// Copyright 2024 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

`timescale 1ns / 1ps

// CSR Module for BFS Accelerator
module csr_module #(
    parameter AXI_ADDR_WIDTH = 12,
    parameter AXI_DATA_WIDTH = 32
) (
    // AXI4-Lite Interface
    input wire s_axi_clk,
    input wire s_axi_rst_n,
    input wire [AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input wire s_axi_awvalid,
    output wire s_axi_awready,
    input wire [AXI_DATA_WIDTH-1:0] s_axi_wdata,
    input wire [AXI_DATA_WIDTH/8-1:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output wire s_axi_wready,
    output wire [1:0] s_axi_bresp,
    output wire s_axi_bvalid,
    input wire s_axi_bready,
    input wire [AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input wire s_axi_arvalid,
    output wire s_axi_arready,
    output wire [AXI_DATA_WIDTH-1:0] s_axi_rdata,
    output wire [1:0] s_axi_rresp,
    output wire s_axi_rvalid,
    input wire s_axi_rready,

    // Configuration and Status signals
    output wire [AXI_DATA_WIDTH-1:0] start_node_address,
    output wire [AXI_DATA_WIDTH-1:0] graph_base_address,
    output wire [AXI_DATA_WIDTH-1:0] high_degree_threshold,
    output wire [AXI_DATA_WIDTH-1:0] medium_degree_threshold,
    output wire control_reg_start,
    input wire busy,
    input wire done,
    input wire incr_traversed_edges,

    // Direct write port for Lookahead Engine
    input wire lse_threshold_we,
    input wire [AXI_DATA_WIDTH-1:0] lse_high_degree_in,
    input wire [AXI_DATA_WIDTH-1:0] lse_medium_degree_in
);

    // Internal signals
    wire [AXI_ADDR_WIDTH-1:0] addr;
    wire write_en;
    wire [AXI_DATA_WIDTH-1:0] write_data;
    wire [AXI_DATA_WIDTH-1:0] read_data_config, read_data_status;
    reg [AXI_DATA_WIDTH-1:0] read_data_mux;

    // Address decode for read data multiplexing
    // Config registers: 0x000-0x00F and 0x01C-0x023
    // Status registers: 0x010-0x01B
    always @(*) begin
        if ((addr >= 12'h010) && (addr <= 12'h01B)) begin
            read_data_mux = read_data_status;
        end else begin
            read_data_mux = read_data_config;
        end
    end

    // Register Map
    // 0x000 - Reserved
    // 0x004 - Start Node Address (R/W)
    // 0x008 - Graph Base Address (R/W)
    // 0x00C - Control Register (R/W) - Bit 0: start
    // 0x010 - Status Register (R) - Bit 0: busy, Bit 1: done
    // 0x014 - Cycle Count (R)
    // 0x018 - Traversed Edges (R)
    // 0x01C - High Degree Threshold (R/W)
    // 0x020 - Medium Degree Threshold (R/W)

    axi4_lite_if #(
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
    ) axi_if_inst (
        .s_axi_clk(s_axi_clk),
        .s_axi_rst_n(s_axi_rst_n),
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),
        .addr(addr),
        .write_en(write_en),
        .write_data(write_data),
        .read_data(read_data_mux)
    );

    config_regs #(
        .ADDR_WIDTH(AXI_ADDR_WIDTH),
        .DATA_WIDTH(AXI_DATA_WIDTH)
    ) config_regs_inst (
        .clk(s_axi_clk),
        .rst_n(s_axi_rst_n),
        .addr(addr),
        .write_en(write_en),
        .write_data(write_data),
        .read_data(read_data_config),
        .lse_threshold_we(lse_threshold_we),
        .lse_high_degree_in(lse_high_degree_in),
        .lse_medium_degree_in(lse_medium_degree_in),
        .start_node_address(start_node_address),
        .graph_base_address(graph_base_address),
        .high_degree_threshold(high_degree_threshold),
        .medium_degree_threshold(medium_degree_threshold),
        .control_reg(control_reg_start)
    );

    status_regs #(
        .ADDR_WIDTH(AXI_ADDR_WIDTH),
        .DATA_WIDTH(AXI_DATA_WIDTH)
    ) status_regs_inst (
        .clk(s_axi_clk),
        .rst_n(s_axi_rst_n),
        .addr(addr),
        .read_data(read_data_status),
        .busy(busy),
        .done(done),
        .incr_traversed_edges(incr_traversed_edges)
    );

endmodule
