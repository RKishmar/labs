module lab2_2 #(
  parameter DATA_WIDTH = 16
)
( input                                   clk_i,
  input                                   srst_i,
  input   [ DATA_WIDTH - 1 : 0 ]          data_i,
  input   [ $clog2 (DATA_WIDTH) - 1 : 0 ] data_mod_i,
  input                                   data_val_i,
  output                                  ser_data_o,
  output                                  ser_data_val_o,
  output                                  busy_o  
);

integer                                   bit_num;

logic [ DATA_WIDTH - 1 : 0 ]          data_r;
logic [ $clog2 (DATA_WIDTH) - 1 : 0 ] data_mod_r;

typedef enum logic [ 1 : 0 ] { IDLE, READ, SEND } state_type;
state_type curr_state, next_state;

always_ff @( posedge clk_i )
  if ( !srst_i ) 
    begin
	   curr_state <= IDLE;
	 end
  else
    begin
	   curr_state <= next_state;
  end
 
 
always_comb begin
  unique case ( curr_state )
    IDLE : 
	   begin
        if( data_val_i )
          next_state = READ;
        else
          next_state = IDLE;
      end
    	 
    READ : 
	   begin
        if( data_mod_i < 4 )
          next_state = IDLE;
		  else 
		    next_state = SEND;
      end
    
	 SEND : 
	   begin
        if( bit_num == DATA_WIDTH - 1 - data_mod_r )
          next_state = IDLE;
        else 
          next_state = SEND;
      end
		
    default : 
	   begin
		  next_state = IDLE;		  
		end

  endcase
end
 
 
always_ff @( posedge clk_i )
begin 
  if ( !srst_i ) 
    begin
      busy_o         =  0;
		ser_data_val_o =  0;
		ser_data_o     = '0;
		bit_num        =  DATA_WIDTH;
  end
    else 
	   begin
        if ( curr_state == IDLE )
		    begin
            busy_o         =  0;
		      ser_data_val_o =  0;
		      ser_data_o     = '0;	
            bit_num        =  DATA_WIDTH;				
		  end
		  
		  else if ( curr_state == READ )
			 begin
            busy_o         =  1;
		      ser_data_val_o =  0;
		      ser_data_o     = '0;	
	         data_r         =  data_i;			
				data_mod_r     =  data_mod_i;
				bit_num        =  DATA_WIDTH;
			 end
			 
        else if ( curr_state == SEND )
			 begin
            busy_o         =  1;
		      ser_data_val_o =  1;
		      ser_data_o     = '0;	
            bit_num = bit_num - 1;
            ser_data_o = data_r [ bit_num ];	
          end 
		 
			 
			
    end
end 

endmodule 