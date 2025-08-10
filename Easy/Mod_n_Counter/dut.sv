/**
 * Mod-N Counter - Counts from 0 to N-1 before wrapping back to 0
 * Parameterized design with synchronous reset
 */
module counter_modn #(
    parameter int N = 10  // Maximum count value (counts from 0 to N-1)
) (
    input  logic                clk,    // Clock signal
    input  logic                rst_n,  // Active-low synchronous reset
    output logic [$clog2(N)-1:0] count  // Current counter value (0 to N-1)
);
    // Synchronous counter with wrap-around at N-1
    always_ff @(posedge clk) begin
        if (!rst_n)
            count <= '0;  // Reset to 0 when reset is active
        else if (count == N-1)
            count <= '0;  // Wrap around to 0 when maximum count is reached
        else
            count <= count + 1'b1;  // Increment counter
    end
endmodule
