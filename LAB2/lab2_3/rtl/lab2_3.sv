/*
  Десериализатор выполняет функцию обратную сериализатору. 
  Модуль “набирает” выходное слово из валидных входных бит начиная с нулевого бита. 
  Как только набралось 16 валидных бит модуль выдает данные на выход.
*/

module lab2_3 #( parameter DATA_WIDTH = 16 )
( input                               clk_i,
  input                               srst_i,
  input                               data_i,
  input                               data_val_i,
  output logic [ DATA_WIDTH - 1 : 0 ] data_o,
  output logic                        data_val_o
);

integer                               bit_num = 0;
logic [ DATA_WIDTH - 1 : 0 ]          data_r = 'x;

 
always_ff @( posedge clk_i )
  begin 
   
    if ( data_val_i == 1 )
      begin 
	    
        data_r [ bit_num ] <= data_i;
		
        if ( bit_num < DATA_WIDTH ) 
          begin 
            bit_num    <= bit_num + 1;
            data_val_o <= 0;
            data_o     <= 'x; 
        end else
          begin
            bit_num    <= 0;
            data_val_o <= 1;
            data_o     <= data_r;	
            data_r     <= 'x; 
        end
        $display ( "data_r = %b", data_r );
    end
end 

endmodule 

