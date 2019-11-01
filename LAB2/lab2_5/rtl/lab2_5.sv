module lab2_5 #( parameter WIDTH = 8)
(  input                        clk_i,
   input                        srst_i,
   input  reg [ WIDTH - 1 : 0 ] data_i,
   output reg [ WIDTH - 1 : 0 ] data_left_o,
   output reg [ WIDTH - 1 : 0 ] data_right_o
);

// logic [ $clog2(WIDTH) : 0]   l, r;

logic [ WIDTH - 1 : 0 ]      tmp;
logic [ WIDTH - 1 : 0 ]      lft, rgh, data_left_r, data_right_r;

//-----------------------------------------------------------------------------


byte unsigned l, r;

always_ff @( posedge clk_i or negedge srst_i )
  begin
    tmp <= data_i; 
		  
    if( ! srst_i ) 
	   begin
        data_left_o  <= 0;
		  data_right_o <= 0;
	 end else
	   begin
		  data_left_o  <= data_left_r;
		  data_right_o <= data_right_r;
    end
end

/*

always_comb
  begin

  
    if ( tmp == 0 ) 
      begin
        data_left_r  = 0;
        data_right_r = 0;
    end else  
      begin
      
	     for ( l = 7; l >= 0; l-- )
    	    if ( tmp [ l ] == 1 ) 
			   break;
        end 
		  
		  for ( r = 0; r < 8; r++ )
	       if ( tmp [ r ] == 1 ) 
			   break;
        end
		  
		  
//        while ( ! tmp [ r ] ) 
//          r = r + 1;  

        lft = '0;
		  rgh = '0;
		  lft [ l ] = 1;
		  rgh [ r ] = 1;
        data_left_r  = lft;    
        data_right_r = rgh;
		  
		end
		  
end
*/


//------------------------------------------------------------------------------


/*
always_comb
  begin 
    lft = { << { data_i }};             // temporary reverse the data bus           
    rgh = data_i; 
    
    lft = lft - ( lft & ( lft - 1 ) );  // leave only the first 1 from the right
    rgh = rgh - ( rgh & ( rgh - 1 ) );  // leave only the first 1 from the right
    
    data_left_r  = { << { lft }};       // reverse the bus back
    data_right_r = rgh;                  
end

*/


//------------------------------------------------------------------------------

/*
always_comb
  begin 
    tmp = data_i;
    lft = tmp;
    while ( ! tmp ) begin
      lft = tmp;
      tmp = tmp & ( tmp - 1 );
    end
    
    data_left_o  = lft;
    data_right_o = data_i - ( data_i & ( data_i - 1 ) );
end
*/

//------------------------------------------------------------------------------


endmodule
