`timescale 1ns/1ns

module lab2_6_tb;

  localparam                                              DATA_WIDTH  = 12;
  localparam                                              TEST_LENGTH = 1000000;
 
  logic                                                   clk;
  logic                                                   reset;
  logic [ DATA_WIDTH - 1 : 0 ]                            data;
  logic [ $clog2( DATA_WIDTH )-1 : 0 ]                    result;
  logic                                                   data_valid;
  logic                                                   result_valid;

  logic [ DATA_WIDTH - 1 : 0 ]                            data_rnd;
  logic [ DATA_WIDTH - 1 : 0 ]                            data_temp;
  logic [ $clog2( DATA_WIDTH ) - 1 : 0 ]                  result_expect;
  logic [ ( $clog2( DATA_WIDTH ) + DATA_WIDTH ) - 1 : 0 ] testvectors[1000:0];
  integer                                                 test_num; 
  integer                                                 errors;
 
  
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

  task automatic display_error ();
    begin
      $display( " " );
      $display( "Error! test iteration number = %d...", test_num );
      $display( "data was tested = %b", data );
      $display( "result received = %b", result );
      $display( "result expected = %b", result_expect );
    end
  endtask
  
  initial begin
    while ( test_num < TEST_LENGTH ) begin
      
      @( result_valid == 0 ); 
      #1; 
      
      data_rnd      = $urandom%{2**(DATA_WIDTH)-1};  
      data_temp     = data_rnd;
      data          = data_rnd;      
      result_expect = 0;
      
      while ( data_temp !== 'b0 ) begin
        data_temp     = data_temp & ( data_temp - 1 );
        result_expect += 1;
      end 
      
      @( result_valid == 1 ); 
      #1; 
     
      if ( result_expect !== result ) begin
        display_error ();
        errors = errors + 1;
      end
      
      test_num = test_num + 1;
            
    end    
      
      $display( " " );
      $display( "%d tests completed with %d errors", test_num, errors );
      $display( " " );
      
  $stop;    
   
  end  

endmodule