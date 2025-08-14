interface intf(input bit clk);
input  logic                  clk;           
input  logic                  rst_n;         
input  logic                  rx;       //Encoded data            
output logic [DATA_WIDTH-1:0] data_out;      
output logic                  data_valid;    
output logic                  parity_error;  
output logic                  framing_error; 
output logic                  overrun_error;
endinterface //intf