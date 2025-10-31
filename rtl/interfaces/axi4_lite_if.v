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

// AXI4-Lite Interface
module axi4_lite_if #(
    parameter AXI_ADDR_WIDTH = 12,
    parameter AXI_DATA_WIDTH = 32
) (
    // AXI4-Lite Interface
    input wire s_axi_clk,
    input wire s_axi_rst_n,
    input wire [AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input wire s_axi_awvalid,
    output reg s_axi_awready,
    input wire [AXI_DATA_WIDTH-1:0] s_axi_wdata,
    input wire [AXI_DATA_WIDTH/8-1:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output reg s_axi_wready,
    output reg [1:0] s_axi_bresp,
    output reg s_axi_bvalid,
    input wire s_axi_bready,
    input wire [AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input wire s_axi_arvalid,
    output reg s_axi_arready,
    output reg [AXI_DATA_WIDTH-1:0] s_axi_rdata,
    output reg [1:0] s_axi_rresp,
    output reg s_axi_rvalid,
    input wire s_axi_rready,

    // Generic bus interface
    output wire [AXI_ADDR_WIDTH-1:0] addr,
    output wire write_en,
    output wire [AXI_DATA_WIDTH-1:0] write_data,
    input wire [AXI_DATA_WIDTH-1:0] read_data
);

    reg [AXI_ADDR_WIDTH-1:0] awaddr_reg;
    reg [AXI_ADDR_WIDTH-1:0] araddr_reg;
    reg awvalid_reg, wvalid_reg, arvalid_reg;

    assign addr = awvalid_reg ? awaddr_reg : araddr_reg;
    assign write_en = awvalid_reg & wvalid_reg;
    assign write_data = s_axi_wdata;

    always @(posedge s_axi_clk or negedge s_axi_rst_n) begin
        if (!s_axi_rst_n) begin
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b0;
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rdata <= 32'b0;
            s_axi_rresp <= 2'b0;
            awaddr_reg <= 0;
            araddr_reg <= 0;
            awvalid_reg <= 0;
            wvalid_reg <= 0;
            arvalid_reg <= 0;
        end else begin
            // Write channel
            if (s_axi_awvalid && !awvalid_reg) begin
                awaddr_reg <= s_axi_awaddr;
                awvalid_reg <= 1'b1;
                s_axi_awready <= 1'b1;
            end else if (s_axi_awready) begin
                s_axi_awready <= 1'b0;
            end

            if (s_axi_wvalid && !wvalid_reg) begin
                wvalid_reg <= 1'b1;
                s_axi_wready <= 1'b1;
            end else if (s_axi_wready) begin
                s_axi_wready <= 1'b0;
            end

            if (awvalid_reg && wvalid_reg) begin
                awvalid_reg <= 1'b0;
                wvalid_reg <= 1'b0;
                s_axi_bvalid <= 1'b1;
            end

            if (s_axi_bready && s_axi_bvalid) begin
                s_axi_bvalid <= 1'b0;
            end

            // Read channel
            if (s_axi_arvalid && !arvalid_reg) begin
                araddr_reg <= s_axi_araddr;
                arvalid_reg <= 1'b1;
                s_axi_arready <= 1'b1;
            end else if (s_axi_arready) begin
                s_axi_arready <= 1'b0;
            end

            if (arvalid_reg) begin
                s_axi_rdata <= read_data;
                s_axi_rvalid <= 1'b1;
                arvalid_reg <= 1'b0;
            end

            if (s_axi_rready && s_axi_rvalid) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule
