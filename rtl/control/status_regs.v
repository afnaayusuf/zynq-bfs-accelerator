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

// Status Registers Module
module status_regs #(
    parameter ADDR_WIDTH = 12,
    parameter DATA_WIDTH = 32
) (
    input wire clk,
    input wire rst_n,

    // Bus Interface
    input wire [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] read_data,

    // Status Inputs
    input wire busy,
    input wire done,
    input wire incr_traversed_edges
);

    // Register definitions
    localparam STATUS_REG           = 12'h010;
    localparam CYCLE_COUNT_REG      = 12'h014;
    localparam TRAVERSED_EDGES_REG  = 12'h018;

    // Internal Registers
    reg [DATA_WIDTH-1:0] cycle_count;
    reg [DATA_WIDTH-1:0] traversed_edges_count;

    // Logic for cycle_count and traversed_edges_count
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_count <= 32'd0;
            traversed_edges_count <= 32'd0;
        end else begin
            if (busy) begin
                cycle_count <= cycle_count + 1;
            end
            if (incr_traversed_edges) begin
                traversed_edges_count <= traversed_edges_count + 1;
                if (traversed_edges_count < 10) begin
                    $display("[%0t] Status Regs: Edge counter incremented to %0d", $time, traversed_edges_count + 1);
                end
            end
        end
    end

    // Read logic
    always @(*) begin
        case (addr)
            STATUS_REG:          read_data = {30'b0, done, busy};
            CYCLE_COUNT_REG:     read_data = cycle_count;
            TRAVERSED_EDGES_REG: read_data = traversed_edges_count;
            default:             read_data = 32'd0;
        endcase
    end

endmodule
