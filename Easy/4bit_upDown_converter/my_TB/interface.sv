
interface intf_4b#(parameter int WIDTH=4);
    bit clk;
    initial begin
        clk=0;
        forever #5 clk= ~clk;
    end

    logic             rst_n;
    logic             up_down;
    logic [WIDTH-1:0] count;
  
  
  clocking cb @(posedge clk);
        input rst_n, up_down, count;
    endclocking

endinterface //intf_4b