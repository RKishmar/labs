`timescale 1ns/1ns
  

  localparam DATA_WIDTH     = 16;
  localparam MIN_VALID_LEN  = 3;
  localparam TEST_LENGTH    = 100000;

  logic                                   clk;
  logic                                   reset;
  logic   [ DATA_WIDTH - 1 : 0 ]          data_to_input;
  logic   [ $clog2( DATA_WIDTH )-1 : 0 ]  data_size;
  logic                                   data_val;
  logic                                   serial_out;
  logic                                   serial_val;
  logic                                   busy;
  
  logic   [ DATA_WIDTH - 1 : 0 ]          temp;
  integer                                 test_num, errors, m; 
  logic   [ $clog2 (DATA_WIDTH) - 1 : 0 ] partition_size;  

//---------------------------------------------------------------------------- 

event length_check_ev;

class transaction;
  rand bit [ DATA_WIDTH - 1 : 0 ]         data_tr;
  rand bit [ $clog2( DATA_WIDTH )-1 : 0 ] tr_size;

  function void randomizing ();
  
    data_tr = $urandom%{ 2 ** DATA_WIDTH - 1 };
    tr_size = $urandom%{ DATA_WIDTH - 1 };
    
    $display ("random_data - ", data_tr);
    $display ("random_size - ", tr_size);
    
  endfunction
  
endclass

//---------------------------------------------------------------------------- 
 
  task transmit_tsk( input int unsigned n,
                     input mailbox #( transaction ) mbx );
    
    automatic transaction trn = new();
    
    repeat ( n ) begin   
      $display ("TRANSMIT START");
      trn.randomizing();
      mbx.put( trn );
      wait ( busy == 0 );
	  	  
      @( posedge clk ) ;	  
      data_to_input = trn.data_tr;
      data_size     = trn.tr_size;
      data_val      = 1;
	  
      @( posedge clk ) ;
      data_val      = 0;
  
	    if ( trn.tr_size >= MIN_VALID_LEN )
	      begin
	        -> length_check_ev;
      end else
        begin 
	        mbx.get( trn );
		      $display ("Random size less than MIN_VALID_LEN", trn.tr_size);
		  end
      
      test_num = test_num + 1;

      $display ("TRANSMIT END");
    end 
  
  endtask : transmit_tsk

//----------------------------------------------------------------------------   
  
  task receiver_tsk( input mailbox #( transaction ) mbx );
    transaction trn;
    forever begin
      $display ("RECEIVER START");
      @( length_check_ev.triggered );
      @( serial_val );
      @( posedge clk );

      for ( int b = 0; b < DATA_WIDTH; b++ )
        if ( serial_val )
          begin 
            temp [ DATA_WIDTH - 1 - b ] = serial_out;
            @( posedge clk );
        end
        
      mbx.get( trn );

      for ( int t = DATA_WIDTH - 1; t < DATA_WIDTH - trn.tr_size - 1; t-- )
        if ( temp [ t ] !== trn.data_tr [ t ] )
          display_error ();  
		  
      if ( test_num == TEST_LENGTH )  
        summary_tsk();
        
		  $display ("RECEIVER FINISH", test_num );

    end
  endtask : receiver_tsk

//---------------------------------------------------------------------------- 

  task automatic display_error ();
    begin
      $display( " " );
      $display( "Error test  ?%d",          test_num  );
      $display( "Random data to test = %b", data_to_input );
      $display( "Random data size =   %d" , data_size  );
      $display( "Result received  =    %b", temp  );   
      $display( " " );    
      $stop;
      errors = errors + 1;
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

module lab2_2_tb;

  mailbox #( transaction ) mbx;

  
//----------------------------------------------------------------------------  
  
  lab2_2  
  #( 
    .DATA_WIDTH        ( DATA_WIDTH  )) 
  DUT 
  (
    .clk_i           ( clk           ),
    .srst_i          ( reset         ),
    .data_i          ( data_to_input ),
    .data_mod_i      ( data_size     ),
    .data_val_i      ( data_val      ),
    .ser_data_o      ( serial_out    ),
    .ser_data_val_o  ( serial_val    ),
    .busy_o          ( busy          )
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
      process::self.srandom(737);  
      transmit_tsk ( TEST_LENGTH, mbx );
      process::self.srandom(373);  
      receiver_tsk ( mbx );
    join
    
  end  

endmodule