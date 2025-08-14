// Base sequence class (parameterized)
class param_base_seq #(parameter int WIDTH=4) extends uvm_sequence #(param_seq_item #(WIDTH));
    `uvm_object_param_utils(param_base_seq #(WIDTH))
    
    function new(string name = "param_base_seq");
        super.new(name);
    endfunction
endclass

// Reset sequence
class param_rst_seq #(parameter int WIDTH=4) extends param_base_seq #(WIDTH);
    `uvm_object_param_utils(param_rst_seq #(WIDTH))
    
    function new(string name = "param_rst_seq");
        super.new(name);
    endfunction
    
    task body();
        param_seq_item #(WIDTH) seq_item;
        seq_item = param_seq_item #(WIDTH)::type_id::create("seq_item");
        start_item(seq_item);
        seq_item.rst_n = 1'b0; // Assert reset
        seq_item.up_down = 1'b0; // Default value during reset
        finish_item(seq_item);
    endtask
endclass

// Up-count sequence
class param_up_seq #(parameter int WIDTH=4) extends param_base_seq #(WIDTH);
    `uvm_object_param_utils(param_up_seq #(WIDTH))
    
    function new(string name = "param_up_seq");
        super.new(name);
    endfunction
    
    task body();
        param_seq_item #(WIDTH) seq_item;
        seq_item = param_seq_item #(WIDTH)::type_id::create("seq_item");
        start_item(seq_item);
        seq_item.rst_n = 1'b1; // No reset
        seq_item.up_down = 1'b1; // Count up
        finish_item(seq_item);
    endtask
endclass

// Down-count sequence
class param_dw_seq #(parameter int WIDTH=4) extends param_base_seq #(WIDTH);
    `uvm_object_param_utils(param_dw_seq #(WIDTH))
    
    function new(string name = "param_dw_seq");
        super.new(name);
    endfunction
    
    task body();
        param_seq_item #(WIDTH) seq_item;
        seq_item = param_seq_item #(WIDTH)::type_id::create("seq_item");
        start_item(seq_item);
        seq_item.rst_n = 1'b1; // No reset
        seq_item.up_down = 1'b0; // Count down
        finish_item(seq_item);
    endtask
endclass

// Random sequence
class param_random_seq #(parameter int WIDTH=4) extends param_base_seq #(WIDTH);
    `uvm_object_param_utils(param_random_seq #(WIDTH))
    
    function new(string name = "param_random_seq");
        super.new(name);
    endfunction
    
    task body();
        param_seq_item #(WIDTH) seq_item;
        seq_item = param_seq_item #(WIDTH)::type_id::create("seq_item");
        start_item(seq_item);
        if (!seq_item.randomize()) begin
            `uvm_error(get_type_name(), "Randomization failed")
        end
        finish_item(seq_item);
    endtask
endclass