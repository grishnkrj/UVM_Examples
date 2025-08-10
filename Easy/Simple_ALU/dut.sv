/**
 * Simple 4-bit ALU (Arithmetic Logic Unit)
 * Performs basic arithmetic and logical operations on two operands
 */
module alu_4bit #(
    parameter int WIDTH = 4  // Default to 4-bit as per specification
)(
    input  logic [WIDTH-1:0] a,      // First operand
    input  logic [WIDTH-1:0] b,      // Second operand
    input  logic [1:0]       op,     // Operation code
    output logic [WIDTH-1:0] result  // Operation result
);
    // ALU operations based on op code
    always_comb begin
        case(op)
            2'b00:   result = a + b;    // ADD: Addition
            2'b01:   result = a - b;    // SUB: Subtraction
            2'b10:   result = a & b;    // AND: Bitwise AND
            2'b11:   result = a | b;    // OR: Bitwise OR
            default: result = {WIDTH{1'b0}}; // Default case (should not occur)
        endcase
    end
endmodule
