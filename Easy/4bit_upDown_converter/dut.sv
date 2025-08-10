// 4-bit Up/Down Counter with parameterized width
module counter_4bit #(
    parameter int WIDTH = 4    // Default to 4-bit as per spec
)(
    input  logic             clk,      // Clock signal
    input  logic             rst_n,    // Active-low reset (changed to synchronous)
    input  logic             up_down,  // Direction control: 1=count up, 0=count down
    output logic [WIDTH-1:0] count     // Current counter value
);

    // Synchronous counter with overflow/underflow protection
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            // Synchronous reset as per specification
            count <= {WIDTH{1'b0}};
        end else if (up_down) begin
            // Count up with overflow protection
            if (&count != 1'b1)  // If not all 1's
                count <= count + 1'b1;
        end else begin
            // Count down with underflow protection
            if (|count != 1'b0)  // If not all 0's
                count <= count - 1'b1;
        end
    end
endmodule
