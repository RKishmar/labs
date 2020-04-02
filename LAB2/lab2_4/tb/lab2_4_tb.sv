`timescale 10ns / 10ns
  
  
/*
  1. последовательность: красный, красный и желтый, зелен, зеленый моргает, желтый, красный.
     При включении переходит в режим “красный”.
  2. Коды команд:
     0 Режим "стандартный"                RYG [ 0 ] + RED_YLW_TIME + RYG [ 2 ] + GREEN_BLNK_TIME + RYG [ 1 ]
     1 Режим "выключен"
     2 Режим "неуправляемый переход"
     3 Установить время горения зеленого
     4 Установить время горения красного
     5 Установить время горения желтого
  3. BLNK_HLF_PER      Длительность полупериода моргания в ms для режимов желтый мигает и зелый мигает
     GRN_BLNK_NUM       Кол-во периодов моргания в состоянии “зеленый мигает”
     RED_YLW_TIME        Время нахождения в состоянии “красный+желтый”
     RED_TIME_DFT       Время нахождения в состоянии “красный” по умолчанию
     YLW_TIME_DFT    Время нахождения в состоянии “желтый”  по умолчанию
     GRN_TIME_DFT     Время нахождения в состоянии “зеленый” по умолчанию
  4. Период “моргания” желтого и зеленого одинаковый и определяется статически. в ms.
     Время нахождения в состоянии “зеленый мигает” задается статически параметром в кол-ве периодов моргания.
     Время нахождения в состоянии “красный+желтый” равно и задается статически параметром в ms.
     Время нахождения в остальных состояниях может быть настроено динамически в ms. Для настроек исп. шину cmd_i, с кодами команд.

     
*/



module lab2_4_tb;

localparam           CLK_HLF_PER  = 2;
localparam           CLK_I_FREQ_T = 20_000_000;
localparam           CLK_MS_NUM_T = CLK_I_FREQ_T / 1000_000;
localparam           DATA_WIDTH_T = 16;

localparam           TEST_LENGTH  = 3000;

localparam           TIME_QUANT   = 20;
localparam           GRN_BLNK_NUM = 6;
localparam           RED_YLW_TIME = 3 * TIME_QUANT;
localparam           RED_TIME_DFT = 5 * TIME_QUANT;
localparam           YLW_TIME_DFT = 3 * TIME_QUANT;
localparam           GRN_TIME_DFT = 5 * TIME_QUANT;
localparam           MIN_DATA_RND = 3 * TIME_QUANT;  
localparam           MAX_DATA_RND = 5 * TIME_QUANT; 
localparam           BLNK_HLF_PER = 1 * TIME_QUANT;
localparam           BLINK_PERIOD    = 2 * BLNK_HLF_PER * CLK_MS_NUM_T; 
localparam           GREEN_BLNK_TIME = 2 * BLNK_HLF_PER * GRN_BLNK_NUM;

localparam [ 2 : 0 ] OFF_MODE     = 0;
localparam [ 2 : 0 ] STD_MODE     = 1;
localparam [ 2 : 0 ] YEL_BLN_MODE = 2;
localparam [ 2 : 0 ] SET_GRN_DUR  = 3;
localparam [ 2 : 0 ] SET_RED_DUR  = 4;
localparam [ 2 : 0 ] SET_YEL_DUR  = 5;

localparam [ 2 : 0 ] RED          = 0;
localparam [ 2 : 0 ] YEL          = 1;
localparam [ 2 : 0 ] GRN          = 2;

localparam [ 2 : 0 ] red_reg      = 3'b100;
localparam [ 2 : 0 ] yel_reg      = 3'b010;
localparam [ 2 : 0 ] grn_reg      = 3'b001;
localparam [ 2 : 0 ] r_y_reg      = 3'b110;
localparam [ 2 : 0 ] off_reg      = 3'b000;

localparam logic [ DATA_WIDTH_T - 1 : 0 ] RYG_TIME_DEFAULTS [ 2 : 0 ] = '{ RED_TIME_DFT, YLW_TIME_DFT, GRN_TIME_DFT };
           logic [ DATA_WIDTH_T - 1 : 0 ] RYG_TIME          [ 2 : 0 ] = RYG_TIME_DEFAULTS;

logic                          clk_t;
logic                          srst_t;
logic [ 2 : 0 ]                cmd_type_t;
logic                          cmd_valid_t;  
logic [ DATA_WIDTH_T - 1 : 0 ] cmd_data_t;

logic [ 2 : 0 ]                ryg_reg  ;
logic [ 2 : 0 ]                grn_bln  ;
logic [ 2 : 0 ]                yel_bln  ;
logic [ 2 : 0 ]                ryg_reg_t;

int                            cnt;
int                            errors, test_num;
bit                            rcv_end, trm_end;

static logic [ DATA_WIDTH_T + 15 : 0 ] std_cnt, ybl_cnt, gbl_cnt; 
static logic [ 2 : 0 ]                 mode_t, curr_mode;

//-----------------------------------------------------------------------

logic [ 31 : 0 ]  RED_CNT_MAX, R_Y_CNT_MAX, GRN_CNT_MAX, GRN_BLN_CNT_MAX, MAX_CNT;

function int num_clks ( logic [ DATA_WIDTH_T - 1 : 0 ] param );
  return ( param * CLK_MS_NUM_T ); 
endfunction

assign     RED_CNT_MAX     = num_clks ( RYG_TIME [ RED ] );
assign     R_Y_CNT_MAX     = num_clks ( RYG_TIME [ RED ] ) + num_clks( RED_YLW_TIME );
assign     GRN_CNT_MAX     = num_clks ( RYG_TIME [ RED ] ) + num_clks( RED_YLW_TIME ) + num_clks( RYG_TIME [ GRN ] );
assign     GRN_BLN_CNT_MAX = num_clks ( RYG_TIME [ RED ] ) + num_clks( RED_YLW_TIME ) + num_clks( RYG_TIME [ GRN ] ) + num_clks( GREEN_BLNK_TIME );
assign     MAX_CNT         = num_clks ( RYG_TIME [ RED ] ) + num_clks( RED_YLW_TIME ) + num_clks( RYG_TIME [ GRN ] ) + num_clks( GREEN_BLNK_TIME ) + num_clks( RYG_TIME [ YEL ] ); 
localparam MIN_DURN_RND    = num_clks ( 24 * TIME_QUANT  );  
localparam MAX_DURN_RND    = num_clks ( 32 * TIME_QUANT  );  
 
//--------------------------------------------------------------------------------

class transaction;
  rand bit [ DATA_WIDTH_T + 15 : 0 ] cmd_data_tr;
  rand bit                           cmd_valid_tr;
  rand bit [ 2 : 0 ]                 cmd_type_tr;
  rand int                           test_duration_tr;
  
  function void randomizes ();
    process::self.srandom( $realtime ); 
    cmd_data_tr  = $urandom_range( MAX_DATA_RND, MIN_DATA_RND );
    cmd_valid_tr = $urandom_range( 0, 1 );
    cmd_type_tr  = $urandom_range( 0, 5 );	
    test_duration_tr  = $urandom_range( MAX_DURN_RND, MIN_DURN_RND );
  endfunction
  
endclass

//---------------------------------------------------------------------------- 
 
task transmit_tsk( input int unsigned n,
                   input mailbox #( transaction ) mbx );  
  automatic transaction trn = new();
    
  repeat ( n ) begin  
  
    trm_end = 0;  
    wait ( rcv_end ); 

    $display ( " TB TRANSMIT START " );  
	
    trn.randomizes();
    mbx.put( trn );
   
    cmd_data_t  = trn.cmd_data_tr;
    cmd_type_t  = trn.cmd_type_tr;
    cmd_valid_t = trn.cmd_valid_tr;

    test_num = test_num + 1;
     
    trm_end = 1;
    #1; //wait ( !rcv_end );
	
  end

endtask : transmit_tsk

//---------------------------------------------------------------------------- 

task receiver_tsk( input mailbox #( transaction ) mbx );
  transaction trn;
  
  forever begin
    $display( " TB cnt :            %0d", cnt );
    if ( cnt == 0 ) 
      begin 
        rcv_end = 1;
        wait ( trm_end );
        rcv_end = 0;	  
        
        mbx.get( trn );
        change_mode_if_valid ( trn );       		
      end 
 
    set_lights   ( );
    set_counters ( trn );
	
    if ( ryg_reg !== ryg_reg_t ) 
      report_error();
    else
      report_success();

    if ( test_num == TEST_LENGTH )  
      summary_tsk();
	  
  end
endtask : receiver_tsk


task automatic set_lights ( );
  begin
    grn_bln = ( gbl_cnt <= BLINK_PERIOD / 2 ) ?  grn_reg : off_reg;
    yel_bln = ( ybl_cnt <= BLINK_PERIOD / 2 ) ?  yel_reg : off_reg;   
    unique case ( mode_t ) 
      OFF_MODE:
        begin $display( " TB MODE : OFF_MODE " );
          ryg_reg_t = off_reg; 
        end
      STD_MODE:
        begin $display( " TB MODE : STD_MODE, %0d / %0d / %0d / %0d / %0d  ", std_cnt, RED_CNT_MAX, R_Y_CNT_MAX, GRN_CNT_MAX, GRN_BLN_CNT_MAX );
          if      ( std_cnt <= RED_CNT_MAX       ) begin ryg_reg_t = red_reg; end
          else if ( std_cnt <= R_Y_CNT_MAX       ) begin ryg_reg_t = r_y_reg; end
          else if ( std_cnt <= GRN_CNT_MAX       ) begin ryg_reg_t = grn_reg; end
          else if ( std_cnt <= GRN_BLN_CNT_MAX   ) begin ryg_reg_t = grn_bln; end
          else                                     begin ryg_reg_t = yel_reg; end
        end
      YEL_BLN_MODE:
        begin $display( " TB MODE : YEL_BLN_MODE, %0d ", ybl_cnt );
          ryg_reg_t = yel_bln; 	  
        end	 
    endcase
	
  end
endtask : set_lights

//=========================================================================================================

task automatic set_counters ( transaction sc_trn );
  begin
    if ( mode_t == STD_MODE ) 
      begin
        std_cnt = ( std_cnt <= MAX_CNT ) ? ( std_cnt + 1 ) : 0;
        if ( ( std_cnt <= GRN_BLN_CNT_MAX ) & ( std_cnt >= GRN_CNT_MAX ) ) 
          gbl_cnt = ( gbl_cnt < BLINK_PERIOD ) ? ( gbl_cnt + 1 ) : 0;
      end
    else if ( mode_t == YEL_BLN_MODE )
      begin
        ybl_cnt   = ( ybl_cnt < BLINK_PERIOD ) ? ( ybl_cnt + 1 ) : 0;   
      end	 
	
    if ( cnt == 0 )
      begin
        cnt = sc_trn.test_duration_tr; 
        @( posedge clk_t ); @( posedge clk_t ); @( posedge clk_t );
      end
    else 
      begin
        cnt = cnt - 1;
        @( posedge clk_t );
      end	
  end
endtask : set_counters

//========================================================================================================

task automatic change_mode_if_valid ( transaction chm_trn );
  automatic bit                          val  = chm_trn.cmd_valid_tr; 
  automatic bit [ 2 : 0 ]                comm = chm_trn.cmd_type_tr; 
  automatic bit [ DATA_WIDTH_T - 1 : 0 ] data = chm_trn.cmd_data_tr;
    begin  
      if ( val == 1 )
        begin 
          curr_mode = mode_t;		
          unique case ( comm ) 
            OFF_MODE    : mode_t = OFF_MODE;
            STD_MODE    : mode_t = STD_MODE;	
            YEL_BLN_MODE: mode_t = YEL_BLN_MODE;
			
            SET_GRN_DUR : RYG_TIME [ GRN ] = data;
            SET_RED_DUR : RYG_TIME [ RED ] = data;                 
            SET_YEL_DUR : RYG_TIME [ YEL ] = data;                  
          endcase
        end	
  end
endtask : change_mode_if_valid


//======================================================================================


task automatic report_error ();
  begin
    errors = errors + 1;
    $display( " " );
    $display( " -  Error test  # %0d ",                   test_num  );
    $display( "    traffic light ryg_reg expected : %b ", ryg_reg_t );
    $display( "    traffic light ryg_reg actual   : %b ", ryg_reg   ); 
	  
    $stop;
  end
endtask : report_error

task automatic report_success ();
  begin
    $display( " " );
    $display( " +  TEST SUCCESS, trafic light ryg_reg: %b ", ryg_reg );  
  end 
endtask : report_success

task automatic summary_tsk ();
  begin
    $display( " " );
    $display( "  Summary: %0d tests completed with %0d error(s) ", test_num, errors );
    $display( " " );
    $stop;    
  end  
endtask : summary_tsk

//----------------------------------------------------------------------------

mailbox #( transaction ) mbx;
  
//----------------------------------------------------------------------------  
  
lab2_4 #( 
  .DATA_WIDTH          ( DATA_WIDTH_T   ),
  .CLK_I_FREQ          ( CLK_I_FREQ_T   ),
  .BLINK_HALF_PERIOD   ( BLNK_HLF_PER   ),
  .GREEN_BLINKS_NUM    ( GRN_BLNK_NUM   ),
  .RED_YELLOW_TIME     ( RED_YLW_TIME   ),
  .RED_TIME_DEFAULT    ( RED_TIME_DFT   ),
  .YELLOW_TIME_DEFAULT ( YLW_TIME_DFT   ),
  .GREEN_TIME_DEFAULT  ( GRN_TIME_DFT   ))
DUT
( .clk_i               ( clk_t          ),
  .srst_i              ( srst_t         ),
  .cmd_type_i          ( cmd_type_t     ),
  .cmd_valid_i         ( cmd_valid_t    ),  
  .cmd_data_i          ( cmd_data_t     ),
  .red_o               ( ryg_reg [RED]  ),
  .yellow_o            ( ryg_reg [YEL]  ),
  .green_o             ( ryg_reg [GRN]  )  
);

//---------------------------------------------------------------------------- 
  
  always begin
    clk_t = 1; #CLK_HLF_PER; 
    clk_t = 0; #CLK_HLF_PER;
  end

  initial begin
    ryg_reg_t = off_reg;
    cnt       = 0; 
    std_cnt   = 0; 
    ybl_cnt   = 0; 
    gbl_cnt   = 0; 
    mode_t    = 0;
    curr_mode = mode_t;
    errors    = 0;
    test_num  = 0;
    rcv_end   = 0; 
    trm_end   = 0;
    
    srst_t    = 1;
    
  end

  initial begin
    mbx = new( 1 );

    fork 
      transmit_tsk ( TEST_LENGTH, mbx );
      receiver_tsk ( mbx );
    join
    
  end  

endmodule
