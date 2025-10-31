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

// Configuration Registers Module
module config_regs #(
    parameter ADDR_WIDTH = 12,
    parameter DATA_WIDTH = 32
) (
    input wire clk,
    input wire rst_n,

    // Bus Interface
    input wire [ADDR_WIDTH-1:0] addr,
    input wire write_en,
    input wire [DATA_WIDTH-1:0] write_data,
    output reg [DATA_WIDTH-1:0] read_data,

    // Direct write port for Lookahead Engine
    input wire lse_threshold_we,
    input wire [DATA_WIDTH-1:0] lse_high_degree_in,
    input wire [DATA_WIDTH-1:0] lse_medium_degree_in,

    // Configuration Outputs
    output reg [DATA_WIDTH-1:0] start_node_address,
    output reg [DATA_WIDTH-1:0] graph_base_address,
    output reg [DATA_WIDTH-1:0] high_degree_threshold,
    output reg [DATA_WIDTH-1:0] medium_degree_threshold,
    output reg control_reg
);

    // Register definitions
    localparam START_NODE_ADDR_REG = 12'h004;
    localparam GRAPH_BASE_ADDR_REG = 12'h008;
    localparam CONTROL_REG         = 12'h00C;
    localparam HIGH_DEGREE_THRESHOLD_REG = 12'h01C;
    localparam MEDIUM_DEGREE_THRESHOLD_REG = 12'h020;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_node_address <= 32'd0;
            graph_base_address <= 32'd0;
            high_degree_threshold <= 32'd0;
            medium_degree_threshold <= 32'd0;
            control_reg <= 1'b0;
        end else begin
            // Priority goes to the internal LSE write
            if (lse_threshold_we) begin
                high_degree_threshold <= lse_high_degree_in;
                medium_degree_threshold <= lse_medium_degree_in;
            end
            // AXI-Lite writes take lower priority
            else if (write_en) begin
                case (addr)
                    START_NODE_ADDR_REG: start_node_address <= write_data;
                    GRAPH_BASE_ADDR_REG: graph_base_address <= write_data;
                    CONTROL_REG:         control_reg <= write_data[0];
                    HIGH_DEGREE_THRESHOLD_REG: high_degree_threshold <= write_data;
                    MEDIUM_DEGREE_THRESHOLD_REG: medium_degree_threshold <= write_data;
                endcase
            end
        end
    end

    always @(*) begin
        case (addr)
            START_NODE_ADDR_REG: read_data = start_node_address;
            GRAPH_BASE_ADDR_REG: read_data = graph_base_address;
            CONTROL_REG:         read_data = {31'b0, control_reg};
            HIGH_DEGREE_THRESHOLD_REG: read_data = high_degree_threshold;
            MEDIUM_DEGREE_THRESHOLD_REG: read_data = medium_degree_threshold;
            default:             read_data = 32'd0;
        endcase
    end

endmodule
