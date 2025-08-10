/**
 * Configurable Pulse Width Modulator (PWM)
 * Parameterized PWM generator with programmable period and duty cycle
 */
module pwm #(
    parameter int WIDTH = 8  // Width of counter and configuration registers
) (
    input  logic              clk,        // System clock
    input  logic              rst_n,      // Active-low synchronous reset
    input  logic [WIDTH-1:0]  period,     // PWM period in clock cycles
    input  logic [WIDTH-1:0]  duty_cycle, // PWM high time in clock cycles
    output logic              pwm_out     // PWM output signal
);
    // Internal counter for timing
    logic [WIDTH-1:0] counter;

    // Counter logic with synchronous reset
    always_ff @(posedge clk) begin
        if (!rst_n)
            counter <= '0;
        else if (counter >= period - 1'b1)
            counter <= '0;
        else
            counter <= counter + 1'b1;
    end

    // PWM output generation with synchronous reset
    always_ff @(posedge clk) begin
        if (!rst_n)
            pwm_out <= 1'b0;
        else
            // Output is high when counter < duty_cycle
            // If duty_cycle >= period, output stays high
            // If duty_cycle = 0, output stays low
            pwm_out <= (counter < duty_cycle);
    end
endmodule
