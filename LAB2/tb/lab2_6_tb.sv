`timescale 1ns/1ns
  

  localparam DATA_WIDTH  = 12;
  localparam TEST_LENGTH = 30000;
  

  logic                                                   clk;
  logic                                                   reset;
  logic   [ DATA_WIDTH - 1 : 0 ]                          data;
  logic   [ $clog2( DATA_WIDTH )-1 : 0 ]                  result;
  logic                                                   data_valid;
  logic                                                   result_valid;

  logic   [ DATA_WIDTH - 1 : 0 ]                          data_rnd;
  logic   [ DATA_WIDTH - 1 : 0 ]                          data_temp;
  logic   [ $clog2( DATA_WIDTH ) - 1 : 0 ]                result_expect;
  integer                                                 test_num; 
  integer                                                 errors;  
  
  
class transaction;
  logic [ DATA_WIDTH - 1 : 0 ] data_msg;
endclass : transaction

class generator;
  task transmit_tsk(input int unsigned n,
                    input mailbox #( transaction ) mbx );
    transaction trn;
    trn = new();
     
    repeat ( n ) begin
      $display( " Starting RANDOMIZER " );
      trn.data_msg = $urandom%{ 2** DATA_WIDTH - 1 };
      mbx.put( trn );
      $display( " put to mailbox is done " );
    end 
  
  endtask : transmit_tsk
endclass : generator

class receiver;
    task receiver_tsk( input mailbox #( transaction ) mbx );
      transaction trn;
      forever begin
        $display( " Starting RECEIVER " );
        mbx.peek( trn );
        #5;
        $display( "Sequence under test: trn.data_msg=%0h", trn.data_msg );
        mbx.get( trn );
        
        data_temp = trn.data_msg;
        $display( " DATA under test: trn.data_msg=%0h", data_temp );
        result_expect = 0;
      
        while ( data_temp !== 'b0 ) begin
          data_temp = data_temp & ( data_temp - 1 );
          result_expect += 1;
        end 
        
        test_tsk ( trn.data_msg, result_expect );
        
          if ( test_num == TEST_LENGTH )  
            summary_tsk();
  
      end
    endtask : receiver_tsk
endclass : receiver

//----------------------------------------------------------------------------  

task test_tsk ( input logic [ DATA_WIDTH - 1 : 0 ] data_msg, 
                input integer  result_expect );
  begin
    
    data = data_msg;
    
    @( result_valid == 1 ); 
    #10; 
     
    if ( result_expect !== result ) begin
      display_error ();
      errors = errors + 1;
    end
     
    test_num = test_num + 1;
    
    $display( " test number: %d", test_num );
            
  end 
endtask : test_tsk   


task automatic display_error ();
  begin
    $display( " " );
    $display( "Error! test iteration number = %d...", test_num );
    $display( "data was tested = %b", data );
    $display( "result received = %b", result );
    $display( "result expected = %b", result_expect );
    $stop;
  end
endtask


task summary_tsk ();
  begin
    $display( " " );
    $display( "%d tests completed with %d error(s)", test_num, errors );
    $display( " " );
    $stop;    
  end  
endtask

//----------------------------------------------------------------------------  

module lab2_6_tb;

  generator              gen;
  receiver               rcv;
  mailbox #(transaction) mbx;
  
  
//----------------------------------------------------------------------------  
  
  lab2_6  
  #( 
    .WIDTH       ( DATA_WIDTH  )) 
  DUT 
  (
    .clk_i       ( clk          ),
    .srst_i      ( reset        ),
    .data_i      ( data         ),
    .data_val_i  ( data_valid   ),
    .data_val_o  ( result_valid ),
    .data_o      ( result       )
  );
  
//---------------------------------------------------------------------------- 
  
  always begin
    clk = 1; #5; 
    clk = 0; #5;
  end

  initial begin
    reset      = 1;
    data_valid = 1;
    errors     = 0;
    test_num   = 0; 
  end


 initial begin
    mbx = new(1);
    gen = new();
    rcv = new();

    fork
       gen.transmit_tsk ( TEST_LENGTH, mbx );
       rcv.receiver_tsk ( mbx );
    join
    
  end  

endmodule