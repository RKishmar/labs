module lab2_5 #( parameter WIDTH = 8)
(  input                        clk_i,
   input                        srst_i,
   input  reg [ WIDTH - 1 : 0 ] data_i,
   output reg [ WIDTH - 1 : 0 ] data_left_o,
   output reg [ WIDTH - 1 : 0 ] data_right_o
);

logic [ WIDTH - 1 : 0 ]      lft, rgh, lft_rev, tmp;

//-----------------------------------------------------------------------------

always_ff @( posedge clk_i or negedge srst_i )
  begin 
    if( ! srst_i ) 
	    begin
        data_left_o  <= 0;
		    data_right_o <= 0;
	  end else
	    begin
		    data_left_o  <= lft;
		    data_right_o <= rgh;
    end
end


always_comb
  begin 
    lft_rev = tmp - ( tmp & ( tmp - 1 ) );
    rgh = data_i - ( data_i & ( data_i - 1 ) );
end

//------------------------------------------------------------------------------

genvar n;
generate 
  for( n = 0; n < WIDTH; n = n + 1 )
    begin : wre
      assign tmp [ WIDTH - 1 - n ] = data_i[ n ];
  end
endgenerate

genvar m;
generate 
  for( m = 0; m < WIDTH; m = m + 1 )
    begin : qwe
      assign lft [ WIDTH - 1 - m ] = lft_rev[ m ];
  end
endgenerate

//------------------------------------------------------------------------------

endmodule