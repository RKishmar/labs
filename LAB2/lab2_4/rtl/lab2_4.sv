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

module lab2_4 #( parameter DATA_WIDTH          = 16,
                 parameter CLK_I_FREQ          = 20_000_000,
                 parameter BLINK_HALF_PERIOD   = 1000,
                 parameter GREEN_BLINKS_NUM    = 10,
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


localparam [ 2 : 0 ]             OFF_MODE     = 0;
localparam [ 2 : 0 ]             STD_MODE     = 1;
localparam [ 2 : 0 ]             YEL_BLN_MODE = 2;
localparam [ 2 : 0 ]             SET_GRN_DUR  = 3;
localparam [ 2 : 0 ]             SET_RED_DUR  = 4;
localparam [ 2 : 0 ]             SET_YEL_DUR  = 5;

localparam [ 2 : 0 ]             RED          = 0;
localparam [ 2 : 0 ]             YEL          = 1;
localparam [ 2 : 0 ]             GRN          = 2;

localparam [ 2 : 0 ]             red_reg      = 3'b100;
localparam [ 2 : 0 ]             yel_reg      = 3'b010;
localparam [ 2 : 0 ]             grn_reg      = 3'b001;
localparam [ 2 : 0 ]             r_y_reg      = 3'b110;
localparam [ 2 : 0 ]             off_reg      = 3'b000;

logic      [ 2 : 0 ]             ryg_reg      = off_reg;
assign                           red_o        = ryg_reg [ RED ];
assign                           yellow_o     = ryg_reg [ YEL ];
assign                           green_o      = ryg_reg [ GRN ];

logic      [ 2 : 0 ]             st_mode;

localparam                              GREEN_BLINK_TIME            = GREEN_BLINKS_NUM * BLINK_HALF_PERIOD * 2;
localparam logic [ DATA_WIDTH - 1 : 0 ] RYG_TIME_DEFAULTS [ 2 : 0 ] = '{ RED_TIME_DEFAULT, YELLOW_TIME_DEFAULT, GREEN_TIME_DEFAULT };
logic            [ DATA_WIDTH - 1 : 0 ] RYG_TIME          [ 2 : 0 ] = RYG_TIME_DEFAULTS;

typedef enum logic [ 2 : 0 ] { OFF_S, RED_S, RED_YEL_S, GRN_S, GRN_BLN_S, YEL_S, YEL_BLN_S } state_type;
state_type curr_state, next_state;

//-----------------------------------------------------------------------

logic [ 31 : 0 ]  RED_CNT_MAX, R_Y_CNT_MAX, GRN_CNT_MAX, GRN_BLN_CNT_MAX, MAX_CNT;

assign RED_CNT_MAX     = num_clks( RYG_TIME [ RED ] );
assign R_Y_CNT_MAX     = num_clks( RYG_TIME [ RED ] ) + num_clks( RED_YELLOW_TIME  );
assign GRN_CNT_MAX     = num_clks( RYG_TIME [ RED ] ) + num_clks( RED_YELLOW_TIME  ) + 
                         num_clks( RYG_TIME [ GRN ] );
assign GRN_BLN_CNT_MAX = num_clks( RYG_TIME [ RED ] ) + num_clks( RED_YELLOW_TIME  ) + 
                         num_clks( RYG_TIME [ GRN ] ) + num_clks( GREEN_BLINK_TIME );
assign MAX_CNT         = num_clks( RYG_TIME [ RED ] ) + num_clks( RED_YELLOW_TIME  ) + 
                         num_clks( RYG_TIME [ GRN ] ) + num_clks( GREEN_BLINK_TIME ) +  
                         num_clks( RYG_TIME [ YEL ] ); 

logic [ $size( MAX_CNT ) + 1 : 0 ] light_cnt   = 0;  
logic [ $size( MAX_CNT ) + 1 : 0 ] yel_bln_cnt = 0;             
logic [ $size( MAX_CNT ) + 1 : 0 ] grn_bln_cnt = 0; 

//-----------------------------------------------------------------------

function int num_clks ( logic [ DATA_WIDTH - 1 : 0 ] param );
  return ( param * ( CLK_I_FREQ / 1000 ) ); 
endfunction

task reset_cnts ();

  $display( " " );
  $display( " DUT RESETS BLINK COUNTERS " );
  $display( " NEXT STATE:    %b ", next_state );
  $display( " CURRENT STATE: %b ", curr_state );
  $display( " " );
  
  grn_bln_cnt <= 0;
  yel_bln_cnt <= 0;
  
endtask : reset_cnts

//-----------------------------------------------------------------------

always_ff @( posedge clk_i )
  if ( !srst_i ) 
    curr_state <= OFF_S;
  else
    curr_state <= next_state;
 
always_ff @( posedge clk_i )
  begin
    
    if ( !srst_i )
      begin 
        RYG_TIME  <= RYG_TIME_DEFAULTS;
        light_cnt <= 0;
        st_mode   <= 0;
      end
    else 
      begin
        light_cnt <= ( light_cnt < MAX_CNT ) ? ( light_cnt + 1 ) : 0;
        if ( cmd_valid_i == 1 )
          case ( cmd_type_i )
            OFF_MODE, STD_MODE, YEL_BLN_MODE : 
              begin 
                light_cnt <= 0;
                st_mode   <= cmd_type_i;
              end
            SET_RED_DUR : RYG_TIME [ RED ] <= cmd_data_i;
            SET_GRN_DUR : RYG_TIME [ GRN ] <= cmd_data_i;
            SET_YEL_DUR : RYG_TIME [ YEL ] <= cmd_data_i;
        endcase   
  end
end
 
always_comb 
  begin
    unique case ( st_mode )
    
      STD_MODE:
      
        if ( light_cnt < RED_CNT_MAX )
          next_state = RED_S;
        else if ( light_cnt < R_Y_CNT_MAX )
          next_state = RED_YEL_S;
        else if ( light_cnt < GRN_CNT_MAX )
          next_state = GRN_S;
        else if ( light_cnt < GRN_BLN_CNT_MAX )
          next_state = GRN_BLN_S;
        else 
          next_state = YEL_S;
		  
      OFF_MODE     : next_state = OFF_S;
      YEL_BLN_MODE : next_state = YEL_BLN_S;
      default      : next_state = OFF_S;
      
    endcase
  end
 
 
always_ff @( posedge clk_i )
  begin 
    if ( !srst_i ) 
      ryg_reg <= off_reg;
    else 
      unique case ( curr_state )
        OFF_S     : ryg_reg <= off_reg;
        RED_S     : ryg_reg <= red_reg;
        YEL_S     : ryg_reg <= yel_reg;
        GRN_S     : ryg_reg <= grn_reg;
        RED_YEL_S : ryg_reg <= r_y_reg;
        GRN_BLN_S : 
          begin
            grn_bln_cnt <= ( grn_bln_cnt < 2 * BLINK_HALF_PERIOD ) ? grn_bln_cnt + 1 : 0; 
            ryg_reg     <= ( grn_bln_cnt <     BLINK_HALF_PERIOD ) ? grn_reg : off_reg;
          end

        YEL_BLN_S : 
          begin
            yel_bln_cnt <= ( yel_bln_cnt < 2 * BLINK_HALF_PERIOD ) ? yel_bln_cnt + 1 : 0; 
            ryg_reg     <= ( yel_bln_cnt <     BLINK_HALF_PERIOD ) ? yel_reg : off_reg;
          end
	  
        default  : 
          begin
            ryg_reg <= off_reg;
          end
      endcase	
    
    if ( next_state !== curr_state )
      reset_cnts();
      
  end 
  

endmodule 