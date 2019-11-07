module lab2_5 #( parameter WIDTH = 8)
(  input                        clk_i,
   input                        srst_i,
   input  reg [ WIDTH - 1 : 0 ] data_i,
   output reg [ WIDTH - 1 : 0 ] data_left_o,
   output reg [ WIDTH - 1 : 0 ] data_right_o
);

logic [ WIDTH - 1 : 0 ]      lft, rgh, lft_rev, tmp;
logic [ $clog2(WIDTH) : 0 ]  n, m;

//---------------------------------------------------------------------------------------------

always_ff @( posedge clk_i or negedge srst_i )
  begin 
    if( ! srst_i ) 
      begin
        data_left_o  <= 0;
        data_right_o <= 0;
    end else
      begin
        if ( data_i == '0 )
          begin
            data_left_o  <= '0;
            data_right_o <= '0;
        end else 
          begin
            data_left_o  <= lft;
            data_right_o <= rgh;
        end
    end
end

//--------( example 1 without reversing the bus / works fine in ModelSim )------

always_comb
  begin 
    tmp = data_i;
    lft = '0;
    rgh = '0;
    n = 0; 
    m = WIDTH - 1;
	 
    for ( int i = WIDTH - 1; i >= 0; i = i - 1 ) 
      begin
        if ( ( tmp [i] == 1 ) && ( i > n ) )
          n = i;
        if ( ( tmp [i] == 1 ) && ( i < m ) )
          m = i;
    end 
	 
    lft[n] = 1;
    rgh[m] = 1;
	 
end 

//--------( example 2 without reversing the bus / special thanx to Br.Kernighan / works fine in ModelSim )------
/*
always_comb
  begin 
    tmp = data_i;
    lft = '0;
    n = 0; 
	 
    for ( int i = WIDTH - 1; i >= 0; i = i - 1 ) 
      begin
        if ( ( tmp [i] == 1 ) && ( i > n ) )
          n = i;
    end 
	 
	  lft[n] = 1;
	 
	  rgh = tmp - ( tmp & ( tmp - 1 ) );	 
	 
 end 	  
*/	  
//--------( example 3 with reversing the bus / special thanx to Br.Kernighan / works fine )--------
/*
always_comb
  begin 
    lft_rev = tmp - ( tmp & ( tmp - 1 ) );
    rgh = data_i - ( data_i & ( data_i - 1 ) );
end

genvar k;
generate 
  for( k = 0; k < WIDTH; k = k + 1 )
    begin : wre
      assign tmp [ WIDTH - 1 - k ] = data_i[ k ];
  end
endgenerate

genvar p;
generate 
  for( p = 0; p < WIDTH; p = p + 1 )
    begin : qwe
      assign lft [ WIDTH - 1 - p ] = lft_rev[ p ];
  end
endgenerate 
*/
//---------------------------------------------------------------------------------------------

endmodule