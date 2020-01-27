/*
  1. последовательность: красный, красный и желтый, зелен, зеленый моргает, желтый, красный.
     При включении переходит в режим “красный”.
  2. Коды команд:
     0 Режим "стандартный"
     1 Режим "выключен"
     2 Режим "неуправляемый переход"
     3 Установить время горения зеленого
     4 Установить время горения красного
     5 Установить время горения желтого
  3. BLINK_HALF_PERIOD     static                    Длительность полупериода моргания в ms для режимов желтый мигает и зелый мигает
     GREEN_BLINKS_NUM      static                    Кол-во периодов моргания в состоянии “зеленый мигает”
     RED_YELLOW_TIME       static                    Время нахождения в состоянии “красный+желтый”
     RED_TIME_DEFAULT      dynamic   RYG_TIME [ 0 ]  Время нахождения в состоянии “красный” по умолчанию
     YELLOW_TIME_DEFAULT   dynamic   RYG_TIME [ 1 ]  Время нахождения в состоянии “желтый”  по умолчанию
     GREEN_TIME_DEFAULT    dynamic   RYG_TIME [ 2 ]  Время нахождения в состоянии “зеленый” по умолчанию
  4. Время нахождения в остальных состояниях может быть настроено динамически в ms. Для настроек исп. шину cmd_i, с кодами команд.

*/

/*  introduce CLK_I_FREQ parameter  */


module lab2_4 #( parameter DATA_WIDTH          = 16,
                 parameter CLK_I_FREQ          = 20_000_000,
                 parameter BLINK_HALF_PERIOD   = 1000,
                 parameter GREEN_BLINKS_NUM    = 1000,
                 parameter RED_YELLOW_TIME     = 1000,
                 parameter RED_TIME_DEFAULT    = 1000,
                 parameter YELLOW_TIME_DEFAULT = 1000,
                 parameter GREEN_TIME_DEFAULT  = 1000 )
( input                          clk_i,
  input                          srst_i,
  input   [ 2 : 0 ]              cmd_type_i,
  input                          cmd_valid_i,  
  input   [ DATA_WIDTH - 1 : 0 ] cmd_data_i,

  output logic                   red_o,
  output logic                   yellow_o,
  output logic                   green_o  
);

int                              blink_cnt = 0;
int                              light_cnt = 0;

localparam [ 2 : 0 ]             red_reg   = 3'b100;
localparam [ 2 : 0 ]             yel_reg   = 3'b010;
localparam [ 2 : 0 ]             grn_reg   = 3'b001;
localparam [ 2 : 0 ]             r_y_reg   = 3'b110;
localparam [ 2 : 0 ]             off_reg   = 3'b000;

logic      [ 2 : 0 ]             ryg_reg   = 0;
assign                           red_o     = ryg_reg [ 0 ];
assign                           yellow_o  = ryg_reg [ 1 ];
assign                           green_o   = ryg_reg [ 2 ];

localparam                              GREEN_BLINK_TIME            = GREEN_BLINKS_NUM * BLINK_HALF_PERIOD * 2;
localparam logic [ DATA_WIDTH - 1 : 0 ] RYG_TIME_DEFAULTS [ 2 : 0 ] = '{ RED_TIME_DEFAULT, YELLOW_TIME_DEFAULT, GREEN_TIME_DEFAULT };
logic            [ DATA_WIDTH - 1 : 0 ] RYG_TIME          [ 2 : 0 ] = RYG_TIME_DEFAULTS;

typedef enum logic [ 1 : 0 ] { IDLED, BASIC, UNREG } state_type;
state_type curr_state, next_state;

//-----------------------------------------------------------------------

function int num_of_clks ( int param );
  return ( param * ( CLK_I_FREQ / 1000 ) ); // $rtoi ?
endfunction

task reset_cnts ();
  blink_cnt <= 0;
  light_cnt <= 0;
endtask : reset_cnts;

task blink( logic [ 2 : 0 ] on_state, int half_period );
  
  blink_cnt <= blink_cnt + 1; 
  
  if ( blink_cnt < half_period ) 
    begin
      ryg_reg <= on_state;
  end else if ( blink_cnt < ( 2 * half_period ) )
    begin
      ryg_reg <= off_reg;
  end else 
    blink_cnt <= 0;
    
endtask : blink;

//-----------------------------------------------------------------------

always_ff @( posedge clk_i )
  if ( !srst_i ) 
    curr_state <= IDLED;
  else
    curr_state <= next_state;
 
 
always_comb begin

  if ( !cmd_valid_i )
    next_state = curr_state;
  else 
    unique case ( cmd_type_i )
      0 : 
        begin
          next_state = BASIC;
        end
		
      1 : 
        begin
          next_state = IDLED;
        end

      2 : 
        begin
          next_state = UNREG;
        end		
		
      3 : 
        begin
		      RYG_TIME [ 0 ] = cmd_data_i;
          next_state = curr_state;
        end

      4 : 
        begin
          RYG_TIME [ 1 ] = cmd_data_i;
          next_state = curr_state;
        end

      5 : 
        begin
          RYG_TIME [ 2 ] = cmd_data_i;
          next_state = curr_state;
        end
	
      default : 
        begin
          next_state = curr_state;		  
        end

  endcase
end
 
 
always_ff @( posedge clk_i )
  begin 
    if ( !srst_i ) 
      begin
        reset_cnts();
    //    RYG_TIME <= RYG_TIME_DEFAULTS;
    end
    else 
      begin
        if ( curr_state == IDLED )
          begin
            ryg_reg <= off_reg;
            reset_cnts();			
        end
		  
        else if ( curr_state == BASIC )
          begin
            light_cnt <= light_cnt + 1;
	          if ( light_cnt < num_of_clks( RYG_TIME [ 0 ] ) ) 
              begin
                ryg_reg <= red_reg;
            end else if ( light_cnt < ( num_of_clks( RYG_TIME [ 0 ] ) + num_of_clks( RED_YELLOW_TIME ) ) )
              begin
                ryg_reg <= r_y_reg;
            end else if ( light_cnt < ( num_of_clks( RYG_TIME [ 0 ] ) + num_of_clks( RED_YELLOW_TIME ) + 
                                        num_of_clks( RYG_TIME [ 2 ] ) ) )
              begin
                ryg_reg <= grn_reg;
            end else if ( light_cnt < ( num_of_clks( RYG_TIME [ 0 ] ) + num_of_clks( RED_YELLOW_TIME  ) + 
                                        num_of_clks( RYG_TIME [ 2 ] ) + num_of_clks( GREEN_BLINK_TIME ) ) )
              begin
                blink ( grn_reg, num_of_clks( BLINK_HALF_PERIOD ) );
            end else if ( light_cnt < ( num_of_clks( RYG_TIME [ 0 ] ) + num_of_clks( RED_YELLOW_TIME  ) + 
                                        num_of_clks( RYG_TIME [ 2 ] ) + num_of_clks( GREEN_BLINK_TIME ) +  
                                        num_of_clks( RYG_TIME [ 1 ] ) ) )
              begin
                ryg_reg <= yel_reg;
            end else 
              reset_cnts();
                     
        end
			 
        else if ( curr_state == UNREG )
          begin
            blink ( yel_reg, num_of_clks( BLINK_HALF_PERIOD ) );
        end 

        if ( next_state !== curr_state )
          reset_cnts();
		
    end
end 

endmodule 