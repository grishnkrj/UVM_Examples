/**
 * 8-to-3 Priority Encoder
 * Encodes the highest priority active input bit to a 3-bit binary output
 * Priority is given to the highest bit position
 */
module priority_encoder_8to3 #(
    parameter int INPUT_WIDTH = 8,
    parameter int OUTPUT_WIDTH = 3
)(
    input  logic [INPUT_WIDTH-1:0] in,    // Input vector with priority to highest bit
    output logic [OUTPUT_WIDTH-1:0] out,  // Binary representation of highest priority active bit
    output logic                   valid  // Indicates if any input bit is active
);
    // Determine if any input bit is active
    always_comb begin
        // Valid is asserted when at least one input bit is set
        valid = |in;
        
        // Priority encoding using unique casez for synthesis optimization
        unique casez (in)
            8'b1???????: out = 3'd7; // Bit 7 (highest priority)
            8'b01??????: out = 3'd6; // Bit 6
            8'b001?????: out = 3'd5; // Bit 5
            8'b0001????: out = 3'd4; // Bit 4
            8'b00001???: out = 3'd3; // Bit 3
            8'b000001??: out = 3'd2; // Bit 2
            8'b0000001?: out = 3'd1; // Bit 1
            8'b00000001: out = 3'd0; // Bit 0 (lowest priority)
            default:     out = {OUTPUT_WIDTH{1'b0}}; // No bits set
        endcase
    end
endmodule
