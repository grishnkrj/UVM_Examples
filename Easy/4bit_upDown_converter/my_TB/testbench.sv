`include "uvm_macros.svh"
import uvm_pkg::*;

`include "interface.sv"
`include "sequence_item.sv"
`include "sequence.sv"
`include "sequencer.sv"
`include "driver.sv"
`include "monitor.sv"
`include "agent.sv"
`include "scoreboard.sv"
`include "env.sv"
`include "test.sv"

module top;

    initial	#100000 $finish;
  	intf_4b		#(4) intf();
  	initial uvm_config_db#(virtual intf_4b)::set(null,"*","VIF",intf);	
  	dut			#(4) d1(.clk(intf.clk),.rst_n(intf.rst_n),.up_down(intf.up_down),.count(intf.count));
  initial run_test("my_test");
  	
    initial begin
        $dumpfile("d.vcd");
        $dumpvars();
    end
endmodule
