`timescale 10ns/10ns
  
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

localparam CLK_I_FREQ_T = 20_000_000;
localparam CLK_MS_NUM_T = CLK_I_FREQ_T / 1000;
localparam DATA_WIDTH_T = 16;

localparam MIN_DATA_RND = 50;  
localparam MAX_DATA_RND = 500; 
localparam TEST_LENGTH  = 300;

localparam BLNK_HLF_PER = 400;
localparam GRN_BLNK_NUM = 5;
localparam RED_YLW_TIME = 300;
localparam RED_TIME_DFT = 700;
localparam YLW_TIME_DFT = 300;
localparam GRN_TIME_DFT = 700;

localparam [ 2 : 0 ] red_reg = 3'b100;
localparam [ 2 : 0 ] yel_reg = 3'b010;
localparam [ 2 : 0 ] grn_reg = 3'b001;
localparam [ 2 : 0 ] r_y_reg = 3'b110;
localparam [ 2 : 0 ] off_reg = 3'b000;

localparam                          GREEN_BLNK_TIME             = GRN_BLNK_NUM * BLNK_HLF_PER * 2;
localparam [ DATA_WIDTH_T - 1 : 0 ] RYG_TIME_DEFAULTS [ 2 : 0 ] = { RED_TIME_DFT, YLW_TIME_DFT, GRN_TIME_DFT };
logic      [ DATA_WIDTH_T - 1 : 0 ] RYG_TIME          [ 2 : 0 ] = RYG_TIME_DEFAULTS;

logic                          clk_t;
logic                          srst_t;
logic [ 2 : 0 ]                cmd_type_t;
logic                          cmd_valid_t;  
logic [ DATA_WIDTH_T - 1 : 0 ] cmd_data_t;

logic [ 2 : 0 ]                ryg_reg  ;
logic [ 2 : 0 ]                ryg_reg_t;

int                            cnt = 0;
int                            errors  = 0, test_num   = 0;
bit                            rcv_end = 0, trm_end    = 0;

static int             cnt_t [ 2 : 0 ] = { 0, 0, 0 }; 
static logic [ 2 : 0 ] state_t = 0;
  
//--------------------------------------------------------------------------------

class transaction;
  rand bit [ DATA_WIDTH_T - 1 : 0 ] cmd_data_tr;
  rand bit                          cmd_valid_tr;
  rand bit [ 2 : 0 ]                cmd_type_tr;
  rand int                          duration_tr;
  
  function void randomizes ();
    cmd_data_tr  = $urandom_range( MIN_DATA_RND, MAX_DATA_RND );
    cmd_valid_tr = $urandom_range( 0, 1 );
    cmd_type_tr  = $urandom_range( 0, 5 );	
    duration_tr  = $urandom_range( MAX_DATA_RND, 2 * MAX_DATA_RND );
  endfunction
  
endclass

//---------------------------------------------------------------------------- 
 
task transmit_tsk( input int unsigned n,
                   input mailbox #( transaction ) mbx );
    
  automatic transaction trn = new();
    
  repeat ( n ) begin   
       
    trn.randomizes();
    mbx.put( trn );
	
	trm_end = 1;
	#1;
    trm_end = 0;
	 
    cmd_data_t  = trn.cmd_data_tr;
    cmd_type_t  = trn.cmd_type_tr;
    cmd_valid_t = trn.cmd_valid_tr;

    test_num = test_num + 1;
	
    wait ( rcv_end );
	
  end

endtask : transmit_tsk

//---------------------------------------------------------------------------- 

task receiver_tsk( input mailbox #( transaction ) mbx );
  transaction trn;
  
  forever begin

    if ( cnt == 0 ) 
      begin
        
      rcv_end = 1;
      wait ( trm_end );
      rcv_end = 0;
		
        mbx.get( trn );
		
        if ( trn.cmd_valid_tr == 1 )
          begin 
            unique case ( trn.cmd_type_tr ) 
              0:
                begin
                  $display( " " );
                  $display( " ~  STATE CHANGE TO: OFF STATE " );
                  state_t = 0;
                  cnt_t   = { 0, 0, 0 };
              end
			  
              1:
                begin
                  $display( " " );
                  $display( " ~  STATE CHANGE TO: STANDARD " );
                  state_t = 1;
                  cnt_t   = { 0, 0, 0 };
              end	
			  
              2:
                begin
                  $display( " " );
                  $display( " ~  STATE CHANGE TO: UNREGULATED " );
                  state_t = 2;
                  cnt_t   = { 0, 0, 0 };
              end
			  
              3:
                begin 
                  RYG_TIME [ 2 ] = trn.cmd_data_tr;
              end
			  
              4:
                begin 
                  RYG_TIME [ 0 ] = trn.cmd_data_tr;                 
              end
			  
              5:
                begin 
                  RYG_TIME [ 1 ] = trn.cmd_data_tr;                
              end
			  
            endcase
        end

        cnt = RYG_TIME [ state_t ];   
  
    end else 
      begin 
		
        unique case ( state_t ) 
          0:
            begin
              ryg_reg_t = off_reg;
          end
	  
          1:
            begin 
              cnt_t [ 1 ] = cnt_t [ 1 ] + 1;
	            if ( cnt_t [ 1 ] < ( CLK_MS_NUM_T * RYG_TIME [ 0 ] ) ) 
                  begin
                    ryg_reg_t = red_reg;
                end else if ( cnt_t [ 1 ] < ( CLK_MS_NUM_T * RYG_TIME [ 0 ] + CLK_MS_NUM_T * RED_YLW_TIME ) )
                  begin
                    ryg_reg_t = r_y_reg;
                end else if ( cnt_t [ 1 ] < ( CLK_MS_NUM_T * RYG_TIME [ 0 ] + CLK_MS_NUM_T * RED_YLW_TIME + 
                                              CLK_MS_NUM_T * RYG_TIME [ 2 ] ) )
                  begin
                    ryg_reg_t = grn_reg;
                end else if ( cnt_t [ 1 ] < ( CLK_MS_NUM_T * RYG_TIME [ 0 ] + CLK_MS_NUM_T * RED_YLW_TIME + 
                                              CLK_MS_NUM_T * RYG_TIME [ 2 ] + CLK_MS_NUM_T * GREEN_BLNK_TIME ) )
                  begin
                    cnt_t [ 0 ] = cnt_t [ 0 ] + 1; 
                    if ( cnt_t [ 0 ] < BLNK_HLF_PER * CLK_MS_NUM_T ) 
                      begin
                        ryg_reg_t = grn_reg;
                    end else if ( cnt_t [ 0 ] < ( 2 * BLNK_HLF_PER * CLK_MS_NUM_T ) ) 
                      begin
                        ryg_reg_t = off_reg;
                    end else 
                      cnt_t [ 0 ] = 0;
                   
                end else if ( cnt_t [ 1 ] < ( CLK_MS_NUM_T * RYG_TIME [ 0 ] + CLK_MS_NUM_T * RED_YLW_TIME + 
                                              CLK_MS_NUM_T * RYG_TIME [ 2 ] + CLK_MS_NUM_T * GREEN_BLNK_TIME +  
                                              CLK_MS_NUM_T * RYG_TIME [ 1 ] ) )
                  begin
                    ryg_reg_t = yel_reg;
                end else 
                  cnt_t [ 1 ] = 0;
          end

          2:
            begin
              cnt_t [ 2 ] = cnt_t [ 2 ] + 1; 
              if ( cnt_t [ 2 ] < BLNK_HLF_PER * CLK_MS_NUM_T ) 
                begin
                  ryg_reg_t = yel_reg;
              end else if ( cnt_t [ 2 ] < ( 2 * BLNK_HLF_PER * CLK_MS_NUM_T ) ) 
                begin
                  ryg_reg_t = off_reg;
              end else 
                cnt_t [ 2 ] = 0;
          end	 
           
        endcase
        
		//----------------------------------------------------------------------------------
		
    end
      
  cnt = cnt - 1;
	
  @( posedge clk_t );

    if ( ryg_reg !== ryg_reg_t ) 
      report_error();
    else
      report_success();

  if ( test_num == TEST_LENGTH )  
    summary_tsk();
  
  end
endtask : receiver_tsk

//---------------------------------------------------------------------------- 

task automatic report_error ();
  begin
    errors = errors + 1;
    $display( " " );
    $display( " -  Error test  #                 %d ", test_num                      );
    $display( "    traffic light state expected: %b ", ryg_reg_t                     );
    $display( "    traffic light state actual:   %b ", ryg_reg                       ); 
    $display( "    State expected:               %d ", state_t                       );
    $display( "    count length / cnt: %d /      %d ", RYG_TIME [ state_t ], cnt );	  
    $stop;
  end
endtask : report_error

task automatic report_success ();
  begin
    $display( " " );
    $display( " +  TEST SUCCESS, trafic light state: %b ", ryg_reg );  
  end 
endtask : report_success

task automatic summary_tsk ();
  begin
    $display( " " );
    $display( "  Summary: %d tests completed with %d error(s) ", test_num, errors );
    $display( " " );
    $stop;    
  end  
endtask : summary_tsk

//----------------------------------------------------------------------------

mailbox #( transaction ) mbx;
  
//----------------------------------------------------------------------------  
  
lab2_4 #( 
  .DATA_WIDTH          ( DATA_WIDTH_T ),
  .CLK_I_FREQ          ( CLK_I_FREQ_T ),
  .BLINK_HALF_PERIOD   ( BLNK_HLF_PER ),
  .GREEN_BLINKS_NUM    ( GRN_BLNK_NUM ),
  .RED_YELLOW_TIME     ( RED_YLW_TIME ),
  .RED_TIME_DEFAULT    ( RED_TIME_DFT ),
  .YELLOW_TIME_DEFAULT ( YLW_TIME_DFT ),
  .GREEN_TIME_DEFAULT  ( GRN_TIME_DFT ))
DUT
( .clk_i               ( clk_t        ),
  .srst_i              ( srst_t       ),
  .cmd_type_i          ( cmd_type_t   ),
  .cmd_valid_i         ( cmd_valid_t  ),  
  .cmd_data_i          ( cmd_data_t   ),
  .red_o               ( ryg_reg [0]  ),
  .yellow_o            ( ryg_reg [1]  ),
  .green_o             ( ryg_reg [2]  )  
);

//---------------------------------------------------------------------------- 
  
  always begin
    clk_t = 1; #5; 
    clk_t = 0; #5;
  end

  initial begin
    ryg_reg_t = off_reg;
    srst_t    = 1;
    errors    = 0;
    test_num  = 0;
    @( posedge clk_t );
    srst_t = 0;
    @( posedge clk_t );
    srst_t = 1;
    
  end

  initial begin
    mbx = new( 1 );

    fork
      process::self.srandom( 373 );  
      transmit_tsk ( TEST_LENGTH, mbx );
      process::self.srandom( 737 );  
      receiver_tsk ( mbx );
    join
    
  end  

endmodule
