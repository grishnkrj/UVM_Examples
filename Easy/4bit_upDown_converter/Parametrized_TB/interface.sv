// Parameterized interface for Up/Down Counter
interface param_counter_if #(parameter int WIDTH=4);
    bit clk;
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    logic             rst_n;
    logic             up_down;
    logic [WIDTH-1:0] count;
  
    clocking cb @(posedge clk);
        input rst_n, up_down, count;
    endclocking

    // For use by driver
    modport DRV (input clk, output rst_n, up_down, input count);
    
    // For use by monitor
    modport MON (input clk, rst_n, up_down, count);

endinterface //param_counter_if