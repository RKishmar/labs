`timescale 1ns/1ns
  

  localparam DATA_WIDTH  = 12;
  localparam TEST_LENGTH = 30000;
  

  logic                                                   clk;
  logic                                                   reset;
  logic   [ DATA_WIDTH - 1 : 0 ]                          data;
  logic   [ DATA_WIDTH - 1 : 0 ]                          result_lft, result_rgh;

  logic   [ DATA_WIDTH - 1 : 0 ]                          lf, rg, ref_res_lft, ref_res_rgh, data_temp;
  integer                                                 test_num; 
  integer                                                 errors;  
  
  typedef logic [ DATA_WIDTH - 1 : 0 ] t_transaction;
  t_transaction trn;

//---------------------------------------------------------------------------- 
  
  task prelim_tsk ( t_transaction trn );
  
    lf = { << { trn }};             // reverse the data bus           
    rg = trn; 
    
    lf = lf - ( lf & ( lf - 1 ) );  // leave only the first 1 from the right
    rg = rg - ( rg & ( rg - 1 ) );  // -//-
    
    ref_res_lft = { << { lf }};     // reverse the bus back
    ref_res_rgh = rg;    
  
  endtask : prelim_tsk
 
//---------------------------------------------------------------------------- 
 
  task transmit_tsk( input int unsigned n,
                     input mailbox #( t_transaction ) mbx );
    t_transaction trn;
     
    repeat ( n ) begin
      trn = $urandom%{ 2 ** DATA_WIDTH - 1 };
      mbx.put( trn );
    end 
  
  endtask : transmit_tsk

//----------------------------------------------------------------------------   
  
  task receiver_tsk( input mailbox #( t_transaction ) mbx );
    t_transaction trn;
    forever begin
      mbx.get( trn );
      $display ( " Sequence under check: %b", trn );
      
      prelim_tsk ( trn );
      
      test_tsk ( trn, ref_res_lft, ref_res_rgh );
       
        if ( test_num == TEST_LENGTH )  
          summary_tsk();
    end
  endtask : receiver_tsk

//----------------------------------------------------------------------------  

task test_tsk ( input logic [ DATA_WIDTH - 1 : 0 ] trn_msg, 
                input logic [ DATA_WIDTH - 1 : 0 ] ref_res_lfteft,
                input logic [ DATA_WIDTH - 1 : 0 ] ref_res_rghight);
  begin
    
    data = trn_msg;
    @(posedge clk);
    @(posedge clk);
    $display ( " Put to DUT this data: %b", data );
    
    if ( ( ref_res_lfteft !== result_lft ) || ( ref_res_rghight !== result_rgh ) )
      begin
        display_error ();
        errors = errors + 1;
    end
     
    test_num = test_num + 1;
    
  end 
endtask : test_tsk   

//---------------------------------------------------------------------------- 

task automatic display_error ();
  begin
    $display( " " );
    $display( "ERROR! Test number    %d", test_num  );
    $display( "Random data to test = %b", data      );
    $display( "Result received (l) = %b", result_lft  );
    $display( "Result expected {l} = %b", ref_res_lft );
    
    $display( "Result received (r) = %b", result_rgh  ); 
    $display( "Result expected {r} = %b", ref_res_rgh );   
    $display( " " );    
    $stop;
  end
endtask : display_error


task summary_tsk ();
  begin
    $display( " " );
    $display( "Summary: %d tests completed with %d error(s)", test_num, errors );
    $display( " " );
    $stop;    
  end  
endtask : summary_tsk

//----------------------------------------------------------------------------  

module lab2_5_tb;

  mailbox #( t_transaction ) mbx;
  
//----------------------------------------------------------------------------  
  
  lab2_5  
  #( 
    .WIDTH        ( DATA_WIDTH  )) 
  DUT 
  (
    .clk_i        ( clk          ),
    .srst_i       ( reset        ),
    .data_i       ( data         ),
    .data_left_o  ( result_lft     ),
    .data_right_o ( result_rgh     )
  );
  
//---------------------------------------------------------------------------- 
  
  always begin
    clk = 1; #5; 
    clk = 0; #5;
  end

  initial begin
    reset      = 1;
    errors     = 0;
    test_num   = 0; 
  end


 initial begin
    mbx = new(1);

    fork
      transmit_tsk ( TEST_LENGTH, mbx );
      receiver_tsk ( mbx );
    join
    
  end  

endmodule