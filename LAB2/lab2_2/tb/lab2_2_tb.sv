`timescale 1ns/1ns
  

  localparam DATA_WIDTH  = 16;
  localparam TEST_LENGTH = 5000;

  logic                                                   clk;
  logic                                                   reset;
  logic   [ DATA_WIDTH - 1 : 0 ]                          data_to_input;
  logic   [ $clog2( DATA_WIDTH )-1 : 0 ]                  data_size;
  logic                                                   data_val;
  logic                                                   serial_out;
  logic                                                   serial_val;
  logic                                                   busy;
  
  logic   [ DATA_WIDTH - 1 : 0 ]                          temp;
  integer                                                 test_num, errors, m; 
  logic   [ $clog2 (DATA_WIDTH) - 1 : 0 ]                 partition_size;  

//---------------------------------------------------------------------------- 

class transaction;
  rand bit [ DATA_WIDTH - 1 : 0 ]         data_tr;
  rand bit [ $clog2( DATA_WIDTH )-1 : 0 ] tr_size;
  
  function void randomizing ();
    data_tr = $urandom%{ 2 ** DATA_WIDTH - 1 };
    tr_size = $urandom%{ DATA_WIDTH - 1 };
  endfunction
  
endclass

//---------------------------------------------------------------------------- 
 
  task transmit_tsk( input int unsigned n,
                     input mailbox #( transaction ) mbx );
    
    automatic transaction trn = new();
    
    repeat ( n ) begin    
      trn.randomizing();
      mbx.put( trn );
    end 
  
  endtask : transmit_tsk

//----------------------------------------------------------------------------   
  
  task receiver_tsk( input mailbox #( transaction ) mbx );
    transaction trn;
    forever begin
      mbx.get( trn );
      test_tsk ( trn );
      
        if ( test_num == TEST_LENGTH )  
          summary_tsk();
    end
  endtask : receiver_tsk

//----------------------------------------------------------------------------  

task test_tsk ( transaction trn );
  begin
    m             = DATA_WIDTH - 1;
    temp          = '0;
    
    data_to_input = trn.data_tr;
    data_size     = trn.tr_size;
    data_val      = 1;
    
    @(posedge clk);
    data_val      = 0;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
            
    $display ( "                      Data = %b", data_to_input );
    $display ( "                      Size = %d", data_size );
    $display( " " );
    
    for ( m = DATA_WIDTH - 1; m > DATA_WIDTH - 1 - data_size; m = m - 1 ) begin
    
    $display( "Paralel input_bit = %d", data_to_input [ m ] );
    $display( "Serial output_bit = %d", serial_out );
    $display( " " );
    
    if ( data_size >= 3 ) 
      begin 
        if ( m > DATA_WIDTH - data_size ) 
          begin
            temp[ m ] = serial_out;
            if ( data_to_input [ m ] !== serial_out )
              begin
                $display ("Wrong bits error");
                display_error ();
                errors = errors + 1;
            end
        end
      end else 
        if ( serial_val == 1 ) 
          begin
            $display ("Validation error");
            display_error ();
            errors = errors + 1;
        end 

    @( posedge clk );
      
    end 

    test_num = test_num + 1;
    
  end 
endtask : test_tsk   

//---------------------------------------------------------------------------- 

task automatic display_error ();
  begin
    $display( " " );
    $display( "Error test  ?%d", test_num  );
    $display( "Random data to test = %b", data_to_input );
    $display( "Random data size =   %d" , data_size  );
    $display( "Output was valid? =   %b", serial_val );
    $display( "Module was busy? =    %b", busy );
    $display( "Bit number = %d"         , m );
    $display( "Serial_out =          %b", serial_out );
    $display( "Result received  =    %b", temp  );   
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
      transmit_tsk ( TEST_LENGTH, mbx );
      receiver_tsk ( mbx );
    join
    
  end  

endmodule