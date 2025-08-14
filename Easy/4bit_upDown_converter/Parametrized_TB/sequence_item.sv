class param_seq_item #(parameter int WIDTH=4) extends uvm_sequence_item;
    // Register with factory using parameterized class
    `uvm_object_param_utils(param_seq_item#(WIDTH))

    rand bit up_down;
    rand bit rst_n;
    logic [WIDTH-1:0] count;
    
    constraint rst_c { soft rst_n == 1'b1; } // Default: no reset during normal operation

    function new(string name = "param_seq_item");
        super.new(name);
    endfunction
    
    // Print function for debug
    function void do_print(uvm_printer printer);
        super.do_print(printer);
        printer.print_field("up_down", up_down, 1, UVM_DEC);
        printer.print_field("rst_n", rst_n, 1, UVM_DEC);
        printer.print_field("count", count, WIDTH, UVM_HEX);
    endfunction
endclass