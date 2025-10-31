
module processing_unit #(
    parameter PU_ID       = 0,
    parameter NODE_BITS   = 32,
    parameter QUEUE_DEPTH = 1024
) (
    input wire clk,
    input wire rst_n,

    // Interface to Node Fetcher
    output wire                  fetch_en,
    output wire [NODE_BITS-1:0]  fetch_node_id,
    input  wire                  fetch_done,
    input  wire [NODE_BITS-1:0]  neighbor_id,
    input  wire                  neighbor_valid,

    // Interface to Visited Manager
    output wire                  check_visited_en,
    output wire [NODE_BITS-1:0]  check_node_id,
    input  wire                  is_visited,

    // Interface to local work queue
    input  wire                  local_queue_full,
    output wire                  local_queue_wr_en,
    output wire [NODE_BITS-1:0]  local_queue_wr_data
);

    // Internal work queue
    pu_work_queue #(
        .NODE_BITS(NODE_BITS),
        .QUEUE_DEPTH(QUEUE_DEPTH)
    ) work_queue (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(local_queue_wr_en),
        .wr_data(local_queue_wr_data),
        .full(local_queue_full),
        .rd_en(rd_en),
        .rd_data(current_node),
        .empty(is_empty)
    );

    typedef enum logic [2:0] {
        IDLE,
        FETCH_NEIGHBORS,
        CHECK_VISITED,
        PUSH_TO_QUEUE
    } state_t;

    state_t current_state, next_state;

    logic [NODE_BITS-1:0] current_node;
    logic rd_en;
    logic is_empty;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    always_comb begin
        next_state = current_state;
        rd_en = 0;
        fetch_en = 0;
        fetch_node_id = '0;
        check_visited_en = 0;
        check_node_id = '0;
        local_queue_wr_en = 0;
        local_queue_wr_data = '0;

        case (current_state)
            IDLE: begin
                if (!is_empty) begin
                    rd_en = 1;
                    next_state = FETCH_NEIGHBORS;
                end
            end
            FETCH_NEIGHBORS: begin
                fetch_en = 1;
                fetch_node_id = current_node;
                if (fetch_done) begin
                    if (neighbor_valid) begin
                        next_state = CHECK_VISITED;
                    end else begin
                        next_state = IDLE;
                    end
                end
            end
            CHECK_VISITED: begin
                check_visited_en = 1;
                check_node_id = neighbor_id;
                next_state = PUSH_TO_QUEUE;
            end
            PUSH_TO_QUEUE: begin
                if (!is_visited && !local_queue_full) begin
                    local_queue_wr_en = 1;
                    local_queue_wr_data = neighbor_id;
                end
                if (fetch_done) begin
                     if (neighbor_valid) begin
                        next_state = CHECK_VISITED;
                    end else begin
                        next_state = IDLE;
                    end
                end else begin
                    next_state = FETCH_NEIGHBORS;
                end
            end
        endcase
    end

endmodule
