/**
 * Simple Parameterized N-bit Adder
 * Takes two N-bit inputs and produces an N+1 bit output sum (to account for carry)
 */
module adder_4bit #(
    parameter int WIDTH = 4  // Default to 4-bit as per original design
)(
    input  logic [WIDTH-1:0] a,          // First operand
    input  logic [WIDTH-1:0] b,          // Second operand
    output logic [WIDTH:0]   sum         // Result with carry bit
);
    // Simple addition with carry
    assign sum = a + b;
endmodule
