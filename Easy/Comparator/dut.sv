/**
 * 8-bit Comparator - Compares two input values and outputs their relationship
 * Parameterizable width with default of 8-bits
 */
module comparator_8bit #(
    parameter WIDTH = 8  // Default to 8-bit as per specification
)(
    input  logic [WIDTH-1:0] a,   // First input for comparison
    input  logic [WIDTH-1:0] b,   // Second input for comparison
    output logic             lt,  // Asserted when a < b
    output logic             eq,  // Asserted when a == b
    output logic             gt   // Asserted when a > b
);
    // Combinational logic for comparison operations
    always_comb begin
        lt = (a < b);   // Less than comparison
        eq = (a == b);  // Equal comparison
        gt = (a > b);   // Greater than comparison
    end
endmodule
