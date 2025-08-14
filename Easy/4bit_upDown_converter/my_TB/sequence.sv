//  Class: rst_seq
//
class rst_seq extends uvm_sequence#(seq_item);
    `uvm_object_utils(rst_seq)


    function new(string name = "rst_seq");
        super.new(name);
    endfunction: new

    task body();
    seq_item item;
    item=seq_item::type_id::create("item");
    item.rst_n=0;
    item.up_down=0;
    start_item(item);
    finish_item(item);
    endtask
    
endclass: rst_seq



class up_seq extends uvm_sequence#(seq_item);
    `uvm_object_utils(up_seq)


    function new(string name = "up_seq");
        super.new(name);
    endfunction: new

    task body();
    seq_item item;
    item=seq_item::type_id::create("item");
    item.rst_n=1;
    item.up_down=1;
    start_item(item);
    finish_item(item);
    endtask
    
endclass: up_seq



class dw_seq extends uvm_sequence#(seq_item);
    `uvm_object_utils(dw_seq)


    function new(string name = "dw_seq");
        super.new(name);
    endfunction: new

    task body();
    seq_item item;
    item=seq_item::type_id::create("item");
    item.rst_n=1;
    item.up_down=0;
    start_item(item);
    finish_item(item);
    endtask
    
endclass: dw_seq