/**
 * UART Transmitter Module
 * Configurable serial transmitter with programmable baud rate, data length,
 * parity, and stop bits
 */
module uart_tx (
    input  logic        clk,          // System clock
    input  logic        rst_n,        // Active-low synchronous reset
    input  logic [7:0]  data_in,      // Parallel input data
    input  logic        data_len,     // 0=7-bit, 1=8-bit
    input  logic        parity_en,    // Enable parity bit
    input  logic        parity_type,  // 0=even, 1=odd
    input  logic        stop_bits,    // 0=1 stop bit, 1=2 stop bits
    input  logic [15:0] baud_div,     // Clock divider for baud rate
    input  logic        tx_start,     // Start transmission pulse
    output logic        tx_line,      // Serial output line
    output logic        tx_busy,      // Transmitter busy indicator
    output logic        tx_done       // Transmission complete pulse
);
    // State machine definition
    typedef enum logic [2:0] {
        IDLE, START, DATA, PARITY, STOP, DONE
    } state_t;

    // Internal signals
    state_t state, next_state;
    logic [15:0] baud_cnt;
    logic baud_tick;
    logic [3:0] bit_cnt;
    logic parity_bit;
    logic [7:0] shift_reg;

    // Baud rate generator - synchronous reset
    always_ff @(posedge clk) begin
        if (!rst_n)
            baud_cnt <= '0;
        else if (state != IDLE) begin
            if (baud_cnt == baud_div - 1'b1)
                baud_cnt <= '0;
            else
                baud_cnt <= baud_cnt + 1'b1;
        end else
            baud_cnt <= '0;
    end

    assign baud_tick = (baud_cnt == baud_div - 1'b1);

    // FSM state register - synchronous reset
    always_ff @(posedge clk) begin
        if (!rst_n)
            state <= IDLE;
        else if (baud_tick)
            state <= next_state;
    end

    // FSM next state logic
    always_comb begin
        next_state = state;
        case(state)
            IDLE:   if (tx_start) next_state = START;
            START:  next_state = DATA;
            DATA:   if (bit_cnt == (data_len ? 7 : 6))
                        next_state = (parity_en ? PARITY : STOP);
            PARITY: next_state = STOP;
            STOP:   if (bit_cnt == (stop_bits ? 1 : 0))
                        next_state = DONE;
            DONE:   next_state = IDLE;
        endcase
    end

    // Data handling and output generation - synchronous reset
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            shift_reg <= '0;
            bit_cnt   <= '0;
            tx_line   <= 1'b1;  // Idle state is high
            tx_busy   <= 1'b0;
            tx_done   <= 1'b0;
            parity_bit<= 1'b0;
        end else if (baud_tick) begin
            tx_done <= 1'b0;
            case(state)
                IDLE: begin
                    tx_line <= 1'b1;
                    tx_busy <= 1'b0;
                    if (tx_start) begin
                        shift_reg  <= data_in;
                        bit_cnt    <= '0;
                        // Calculate parity based on data length
                        parity_bit <= ^data_in[(data_len ? 7 : 6):0];
                        // Invert for odd parity
                        if (parity_type) 
                            parity_bit <= ~(^data_in[(data_len ? 7 : 6):0]);
                        tx_busy    <= 1'b1;
                    end
                end
                START: tx_line <= 1'b0;  // Start bit is always 0
                DATA: begin
                    tx_line <= shift_reg[0];  // LSB first
                    shift_reg <= shift_reg >> 1;
                    bit_cnt <= bit_cnt + 1'b1;
                end
                PARITY: tx_line <= parity_bit;
                STOP: begin
                    tx_line <= 1'b1;  // Stop bit is always 1
                    bit_cnt <= bit_cnt + 1'b1;
                end
                DONE: begin
                    tx_done <= 1'b1;  // One-cycle pulse
                end
            endcase
        end
    end
endmodule
