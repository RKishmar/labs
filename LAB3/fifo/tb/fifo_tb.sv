`timescale 10ns / 10ns


/* запросы на чтение и запись могут приходить одновременно
   запросы на чтение и на запись всегда валидны
   usedw_o = 0 когда очередь пуста или полна
   wr_req_i приходит только когда очередь не полна
   rd_req_i приходит только когда очередь не пуста

   режим showahead это когда верхнее слово fifo всегда “видно” на выходе q,
   сигналом readrq вы просто подтверждаете что вы его прочитали, а не
   запрашиваете
   
*/

module fifo_tb;
  localparam                      TEST_ITERS       = 100000;
  localparam                      CLK_HLF_PER      = 2;
  localparam                      DATA_WIDTH_TB    = 16;
  localparam                      ADRS_WIDTH_TB    = 8;  // Mem adress width
  localparam                      SHOWAHEAD_TB     = 0;
  localparam                      FIFO_SIZE        = 2 ** ADRS_WIDTH_TB;
  localparam                      DATA_MAX         = 2 ** DATA_WIDTH_TB - 1;
  
  localparam                      WR_DELAY_MAX = 2 ** ( ADRS_WIDTH_TB / 4 );
  localparam                      WR_DELAY_MIN = 2 ** ( ADRS_WIDTH_TB / 8 );
  localparam                      RD_DELAY_MAX = 2 ** ( ADRS_WIDTH_TB / 2 );
  localparam                      RD_DELAY_MIN = 2 ** ( ADRS_WIDTH_TB / 4 );
  
  logic                           clk_tb;
  logic                           srst_tb;      // synchronous 
  
  logic                           wr_req_tb;
  logic [ ADRS_WIDTH_TB - 1 : 0 ] wr_adr_tb;
  logic [ DATA_WIDTH_TB - 1 : 0 ] wr_dat_tb;
  
  logic                           rd_req_tb; 
  logic [ ADRS_WIDTH_TB - 1 : 0 ] rd_adr_tb;  
  logic [ DATA_WIDTH_TB - 1 : 0 ] rd_dat_tb;
  
  logic [ ADRS_WIDTH_TB - 1 : 0 ] usedw_tb;    // read data word
  bit                             empty_tb;
  bit                             full_tb;     // number of used words in fifo 

  logic [ DATA_WIDTH_TB - 1 : 0 ] fifo_mem  [ FIFO_SIZE - 1 : 0 ];
  logic [ DATA_WIDTH_TB - 1 : 0 ] mbx_r_wrd;

//ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo 

task transmitter ( input mailbox #( logic [ DATA_WIDTH_TB - 1 : 0 ] ) mbx_t );
  repeat ( TEST_ITERS ) begin
    if ( srst_tb ) 
      begin
        @( posedge clk_tb );
        wr_req_tb = 0;  
        process::self.srandom( $realtime ); 
        repeat ( $urandom_range ( WR_DELAY_MAX, WR_DELAY_MIN ) ) @( posedge clk_tb );

        if ( mbx_t.num() < ( FIFO_SIZE - 1 ) ) 
          begin
            wr_dat_tb = $urandom_range ( DATA_MAX, 0 );
            wr_req_tb = 1;
            mbx_t.put( wr_dat_tb );
          end
      end
    else
      begin
        wr_req_tb = 0;
        wait ( srst_tb == 1 );
      end
  end
endtask : transmitter

task receiver ( input mailbox #( logic [ DATA_WIDTH_TB - 1 : 0 ] ) mbx_r );
  forever begin
    rd_req_tb = 0;
      process::self.srandom( $realtime ); 
      repeat ( $urandom_range ( RD_DELAY_MAX, RD_DELAY_MIN ) ) @( posedge clk_tb );  
    rd_req_tb = 1; 
    @( posedge clk_tb );

    mbx_r.get( mbx_r_wrd );
    //$display ( " MBX : %0p ", mbx_r );

  end
endtask : receiver

//-----------------------------------------------------------------------

task static monitor ();
  forever begin
    fork 
      check_content    ();  
      check_full_empty ();
      check_usedw      ();
	  check_SHOWAHEAD  ();
      $display ( " \n >>> ERROR TYPES -> usedw / content / full / empty / SHOWAHEAD : %0d / %0d / %0d / %0d / %0d \n ", 
                   check_usedw.errors_usedw,      check_content.errors_cont,      check_full_empty.errors_full, 
				   check_full_empty.errors_empty, check_SHOWAHEAD.errors_sh_ahead  );
    join
  end
endtask : monitor


task static check_content ( );
  static int errors_cont = 0;
  begin
    wait ( rd_req_tb == 1 );
    @( posedge clk_tb );

    if ( rd_dat_tb !== mbx_r_wrd )
      begin
        $display ( " \n ERROR! Wrong content - received / expected : %0d / %0d \n", rd_dat_tb, mbx_r_wrd );
        $display ( " fifo_mbx.num() : %0d ", fifo_mbx.num() );
        errors_cont = errors_cont + 1;  
        $stop;
      end
  end
endtask : check_content


task automatic check_full_empty ();
  static int errors_full = 0;
  static int errors_empty = 0;
  begin
    @( posedge clk_tb );
    if ( ( fifo_mbx.num() == 0 ) & ( empty_tb !== 1 ) ) 
      begin
        errors_empty = errors_empty + 1; 
        $display ( " \n ERROR! Wrong FIFO empty out - fifo_mbx.num() / empty_tb : %0d / %0d \n ", fifo_mbx.num(), empty_tb ); 
        $stop;
      end   
    if ( ( fifo_mbx.num() == FIFO_SIZE - 1 ) & ( full_tb !== 1 ) )
      begin
        errors_full = errors_full + 1;  
        $display ( " \n ERROR! Wrong FIFO full out - fifo_mbx.num() / full_tb : %0d / %0d \n ", fifo_mbx.num(), full_tb );
        //$stop;
      end    
  end
endtask : check_full_empty


task automatic check_usedw ();
  static int errors_usedw = 0;
  begin
    @( posedge clk_tb );
    if ( ( usedw_tb !== fifo_mbx.num() ) | ( ( fifo_mbx.num() == FIFO_SIZE - 1 ) & ( usedw_tb !== 0 ) ) )
      begin
        $display ( " \n ERROR! Wrong FIFO words num - received / expected : %0d / %0d \n", usedw_tb, fifo_mbx.num() );
        errors_usedw = errors_usedw + 1;
        //$stop;
      end  
  end
endtask : check_usedw


task automatic check_SHOWAHEAD();
  static int errors_sh_ahead = 0;
  automatic logic [ DATA_WIDTH_TB - 1 : 0 ] mbx_peek_word;
  begin
    @( posedge clk_tb );
    fifo_mbx.peek ( mbx_peek_word );
    if ( ( SHOWAHEAD_TB ) & ( !rd_req_tb ) & ( rd_dat_tb !== mbx_peek_word ) )
      begin
        $display ( " \n ERROR! Wrong content - received / expected : %0d / %0d \n", rd_dat_tb, mbx_peek_word );
        $display ( " fifo_mbx.num() : %0d ", fifo_mbx.num() );
        errors_sh_ahead = errors_sh_ahead + 1;
        //$stop;
      end  
  end
endtask : check_SHOWAHEAD


//-----------------------------------------------------------------------

fifo # (
  .DWIDTH    ( DATA_WIDTH_TB ),
  .AWIDTH    ( ADRS_WIDTH_TB ),
  .SHOWAHEAD ( SHOWAHEAD_TB  ) )
DUT (
  .clk_i     ( clk_tb        ),
  .srst_i    ( srst_tb       ),
  .rd_req_i  ( rd_req_tb     ),
  .wr_req_i  ( wr_req_tb     ),
  .data_i    ( wr_dat_tb     ),
  .q_o       ( rd_dat_tb     ),
  .usedw_o   ( usedw_tb      ),
  .empty_o   ( empty_tb      ),
  .full_o    ( full_tb       )
);  
  
//-----------------------------------------------------------------------

  always begin
    clk_tb = 1; #CLK_HLF_PER; 
    clk_tb = 0; #CLK_HLF_PER;
  end
  
  initial
    begin
      srst_tb = 0; 
      #1;
      srst_tb = 1;
    end
  
  initial
    begin
      wr_adr_tb = 0;
      rd_adr_tb = 0;
      wr_req_tb = 0;
      rd_req_tb = 0;
      wr_dat_tb = 'x;  
    end


  mailbox #( logic [ DATA_WIDTH_TB - 1 : 0 ] ) fifo_mbx;    
  initial 
    begin
      fifo_mbx = new ( FIFO_SIZE );
      fork
        receiver   ( fifo_mbx );
        transmitter( fifo_mbx );
        monitor    ();
      join
    end
    
endmodule
  

//ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo 

  
  
  
  