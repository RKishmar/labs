`timescale 1ns/1ns

//------------------ DESERIALIZER TB ----------------------------------
  
module lab2_3_tb;

  localparam DATA_WIDTH      = 16;
  localparam TEST_BIT_LENGTH = 50000;

  logic                           clk;
  logic                           reset;
  logic                           data_inp;
  logic   [ DATA_WIDTH - 1 : 0 ]  data_out;
  logic                           data_inp_val;
  logic                           data_out_val;
  
  logic   [ DATA_WIDTH - 1 : 0 ]  true_reg = 'x;
  integer                         test_num, errors, cnt = 0; 
  string                          next_step [ $ ];
  
//---------------------------------------------------------------------------- 

class transaction;
  rand bit data_tr;
  rand bit trn_val;

  function void randomizes ();
  
    data_tr = $urandom_range(0,1);
    trn_val = $urandom_range(0,1);
   
  endfunction
  
endclass

//---------------------------------------------------------------------------- 
 
task transmit_tsk( input int unsigned n );
                     
  automatic transaction trn = new();
    
  repeat ( n ) begin 
      
    trn.randomizes();
     
    data_inp     = trn.data_tr;
    data_inp_val = trn.trn_val;
    @( posedge clk ); 
      
    if ( trn.trn_val == 1 )
      begin
        if ( cnt == DATA_WIDTH )
          begin
            next_step [ 1 ] = "end_iteration";
            next_step [ 0 ] = "check_start";
            @( next_step [ 0 ] == "end_iteration" );
            $display ( next_step );
			  
            cnt = 0;
            true_reg = 'x;
        end
          else begin
            true_reg [ cnt ] = trn.data_tr;
            cnt = cnt + 1;
        end
          
    end
	  
  end // end repeat
	
    summary_tsk();
  
endtask : transmit_tsk

//----------------------------------------------------------------------------   
  
task receiver_tsk();

  forever begin
    @( next_step [ 0 ] == "check_start" );	  
    @( data_out_val );
            
    if ( data_out !== true_reg )
      report_error();
    else 
      begin
        $display ( " " );
        $display ( "output data is     %b", data_out );
        $display ( "expected result is %b", true_reg );
        $display ( " " );
        $display ( "============>>> TEST NUMBER %d SUCCESFULLY DONE <<<===============", test_num );	  
        $display ( " " );
    end		  
  
    test_num = test_num + 1;
    
    next_step [ 1 ] = "check_start";
    next_step [ 0 ] = "end_iteration";
      
    @( posedge clk ); 
	  
  end
endtask : receiver_tsk

//---------------------------------------------------------------------------- 

task automatic report_error ();
  begin
    errors = errors + 1;
    $display( " " );
    $display( "Error in test number %d", test_num     );
    $display( "Input data valid   = %d", data_inp_val );
    $display( "Output data valid  = %b", data_out_val );
    $display( "Result received    = %b", data_out     );    
    $display( "Result expected    = %b", true_reg     );   
    $display( " " );    
    $stop;
  end
endtask : report_error

task summary_tsk ();
  begin
    $display( " " );
    $display( "Summary: %d tests completed with %d error(s)", test_num, errors );
    $display( " " );
    $stop;    
  end  
endtask : summary_tsk

//----------------------------------------------------------------------------  
  
  lab2_3  
  #( 
    .DATA_WIDTH  ( DATA_WIDTH    )) 
  DUT 
  (
    .clk_i       ( clk           ),
    .srst_i      ( reset         ),
    .data_i      ( data_inp      ),
    .data_val_i  ( data_inp_val  ),
    .data_o      ( data_out      ),
    .data_val_o  ( data_out_val  )
  );
  
  always begin
    clk = 1; #5; 
    clk = 0; #5;
  end

  initial begin
    reset      = 0; #10;
    reset      = 1;
    errors     = 0;
    test_num   = 0; 
  end

  initial begin

    fork
      transmit_tsk ( TEST_BIT_LENGTH );
      receiver_tsk ( );
    join
    
  end  

endmodule