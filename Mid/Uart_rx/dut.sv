/**
 * UART Receiver (UART_RX)
 * Configurable serial receiver with programmable data width, parity, stop bits,
 * and baud rate divider. Includes error detection capabilities.
 */
module uart_rx #(
    parameter int DATA_WIDTH = 8,      // Data width (typically 7-9 bits)
    parameter int PARITY = 0,          // 0: none, 1: even, 2: odd
    parameter int STOP_BITS = 1,       // 1 or 2 stop bits
    parameter int BAUD_DIV = 16        // Clock divider for baud rate
) (
    input  logic                  clk,           // System clock
    input  logic                  rst_n,         // Active-low synchronous reset
    input  logic                  rx,            // Serial data input
    output logic [DATA_WIDTH-1:0] data_out,      // Received parallel data
    output logic                  data_valid,    // Data valid strobe (1 clk pulse)
    output logic                  parity_error,  // Parity error detected
    output logic                  framing_error, // Framing error detected
    output logic                  overrun_error  // Overrun error detected
);
    // State machine definition
    typedef enum logic [2:0] {
        IDLE, START, DATA, PARITY_BIT, STOP, DONE
    } state_t;
    
    // Internal signals
    state_t state;
    logic [$clog2(DATA_WIDTH):0] bit_cnt;
    logic [DATA_WIDTH-1:0] data_shift;
    logic [$clog2(BAUD_DIV)-1:0] baud_cnt;
    logic rx_sync, rx_prev;
    logic parity_calc;
    logic [DATA_WIDTH-1:0] data_buf;
    
    // Double-synchronize rx input to prevent metastability
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            rx_sync <= 1'b1;
            rx_prev <= 1'b1;
        end else begin
            rx_prev <= rx_sync;
            rx_sync <= rx;
        end
    end

    // Main state machine - synchronous reset
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            baud_cnt <= '0;
            bit_cnt <= '0;
            data_shift <= '0;
            parity_calc <= 1'b0;
            data_out <= '0;
            data_valid <= 1'b0;
            framing_error <= 1'b0;
            parity_error <= 1'b0;
            overrun_error <= 1'b0;
        end else begin
            // Default data_valid to 0 (single-cycle pulse)
            data_valid <= 1'b0;
            
            case (state)
                IDLE: begin
                    framing_error <= 1'b0;
                    parity_error <= 1'b0;
                    
                    // Start bit detection (falling edge)
                    if (rx_sync == 1'b0) begin
                        // Initialize for start bit sampling (at middle of bit)
                        baud_cnt <= BAUD_DIV/2; 
                        state <= START;
                    end
                end
                
                START: begin
                    if (baud_cnt == 0) begin
                        // Confirm start bit is still low at middle of bit
                        if (rx_sync == 1'b0) begin
                            // Setup for data bits
                            baud_cnt <= BAUD_DIV-1;
                            bit_cnt <= '0;
                            parity_calc <= 1'b0;
                            state <= DATA;
                        end else begin
                            // False start bit detected
                            state <= IDLE;
                        end
                    end else begin
                        baud_cnt <= baud_cnt - 1'b1;
                    end
                end
                
                DATA: begin
                    if (baud_cnt == 0) begin
                        // Sample data bit at middle of bit period
                        data_shift <= {rx_sync, data_shift[DATA_WIDTH-1:1]};
                        // Update parity calculation
                        parity_calc <= parity_calc ^ rx_sync;
                        bit_cnt <= bit_cnt + 1'b1;
                        baud_cnt <= BAUD_DIV-1;
                        
                        // Check if all data bits received
                        if (bit_cnt == DATA_WIDTH-1) begin
                            // Go to parity check or stop bit based on configuration
                            state <= (PARITY == 0) ? STOP : PARITY_BIT;
                        end
                    end else begin
                        baud_cnt <= baud_cnt - 1'b1;
                    end
                end
                
                PARITY_BIT: begin
                    if (baud_cnt == 0) begin
                        // Check parity based on configuration
                        if ((PARITY == 1 && parity_calc != rx_sync) ||  // Even parity
                            (PARITY == 2 && parity_calc == rx_sync)) {   // Odd parity
                            parity_error <= 1'b1;
                        }
                        state <= STOP;
                        baud_cnt <= BAUD_DIV-1;
                    end else begin
                        baud_cnt <= baud_cnt - 1'b1;
                    end
                end
                
                STOP: begin
                    if (baud_cnt == 0) begin
                        // Check stop bit(s)
                        if (rx_sync != 1'b1) begin
                            framing_error <= 1'b1;
                        end
                        
                        // Handle second stop bit if configured
                        if (STOP_BITS == 2) begin
                            baud_cnt <= BAUD_DIV-1;
                            state <= DONE;
                        end else begin
                            state <= DONE;
                            // If 1 stop bit, transfer data immediately
                            if (data_valid) begin
                                // Data wasn't read from previous reception
                                overrun_error <= 1'b1;
                            end
                            data_out <= data_shift;
                            data_valid <= 1'b1;
                        end
                    end else begin
                        baud_cnt <= baud_cnt - 1'b1;
                    end
                end
                
                DONE: begin
                    if (STOP_BITS == 2) begin
                        // Second stop bit handling for 2 stop bits
                        if (baud_cnt == 0) begin
                            // Check second stop bit
                            if (rx_sync != 1'b1) begin
                                framing_error <= 1'b1;
                            end
                            // Transfer data after second stop bit
                            if (data_valid) begin
                                overrun_error <= 1'b1;
                            end
                            data_out <= data_shift;
                            data_valid <= 1'b1;
                            state <= IDLE;
                        end else begin
                            baud_cnt <= baud_cnt - 1'b1;
                        end
                    end else begin
                        // For 1 stop bit, just go back to IDLE
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule