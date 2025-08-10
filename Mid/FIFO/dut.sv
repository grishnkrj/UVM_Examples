/**
 * Configurable FIFO Buffer
 * Features: programmable depth and width, status flags, synchronous operations
 */
module fifo #(
    parameter int DATA_WIDTH = 8,   // Width of data bus
    parameter int DEPTH = 16        // Maximum number of entries
) (
    input  logic                   clk,          // Clock signal
    input  logic                   rst_n,        // Active-low synchronous reset
    input  logic                   wr_en,        // Write enable
    input  logic                   rd_en,        // Read enable
    input  logic [DATA_WIDTH-1:0]  din,          // Data input
    output logic [DATA_WIDTH-1:0]  dout,         // Data output
    output logic                   full,         // FIFO is full
    output logic                   empty,        // FIFO is empty
    output logic                   almost_full,  // Only one space left
    output logic                   almost_empty, // Only one element left
    output logic [$clog2(DEPTH):0] count         // Number of elements in FIFO
);
    // Internal signals
    logic [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;    // Read/write pointers
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];      // Memory array
    logic [$clog2(DEPTH):0] cnt;                 // Element counter

    // Status flags
    assign full         = (cnt == DEPTH);
    assign empty        = (cnt == 0);
    assign almost_full  = (cnt == DEPTH-1);      // Corrected to match spec
    assign almost_empty = (cnt == 1);            // Corrected to match spec
    assign count        = cnt;

    always_ff @(posedge clk) begin               // Changed to synchronous reset
        if (!rst_n) begin
            // Synchronous reset
            wr_ptr <= '0;
            rd_ptr <= '0;
            cnt    <= '0;
            dout   <= '0;
        end else begin
            // Write operation
            if (wr_en && !full) begin
                mem[wr_ptr] <= din;
                wr_ptr <= (wr_ptr == DEPTH-1) ? '0 : wr_ptr + 1'b1;  // Added wrap-around
                cnt <= cnt + 1'b1;
            end
            
            // Read operation
            if (rd_en && !empty) begin
                dout <= mem[rd_ptr];
                rd_ptr <= (rd_ptr == DEPTH-1) ? '0 : rd_ptr + 1'b1;  // Added wrap-around
                cnt <= cnt - 1'b1;
            end
            
            // Simultaneous read and write
            if (wr_en && rd_en && !full && !empty) begin
                cnt <= cnt;  // No change in count when both read and write
            end
        end
    end
endmodule