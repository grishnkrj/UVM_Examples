
class seq_item extends uvm_sequence_item;
    `uvm_object_utils(seq_item)

    rand bit up_down;
    rand bit rst_n;
  logic [3:0] count;
  constraint rst_c { soft rst_n == 1'b1; } // Default: no reset during normal operation

    function new(string name = "seq_item");
        super.new(name);
    endfunction
endclass