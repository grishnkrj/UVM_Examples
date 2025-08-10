/**
 * Serial Parity Checker
 * Checks whether the parity bit matches the selected parity type (even/odd)
 * For even parity: Total number of 1s in {data_in, parity_bit} should be even
 * For odd parity: Total number of 1s in {data_in, parity_bit} should be odd
 */
module serial_parity_checker #(
    parameter int DATA_WIDTH = 8  // Width of data input
)(
    input  logic [DATA_WIDTH-1:0] data_in,     // Data byte to check
    input  logic                  parity_bit,  // Received parity bit
    input  logic                  parity_type, // 0 = even, 1 = odd
    output logic                  parity_error // 1 if parity is incorrect
);
    // Calculate parity of data_in (1 if odd number of 1s)
    logic data_parity;
    assign data_parity = ^data_in;
    
    // Calculate total parity including the parity bit
    logic total_parity;
    assign total_parity = data_parity ^ parity_bit;
    
    // Determine parity error based on parity type
    always_comb begin
        if (parity_type == 1'b0) // Even parity
            // For even parity: total_parity should be 0 (even number of 1s)
            parity_error = total_parity;
        else                     // Odd parity
            // For odd parity: total_parity should be 1 (odd number of 1s)
            parity_error = ~total_parity;
    end
endmodule
