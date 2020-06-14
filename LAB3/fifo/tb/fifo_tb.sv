`timescale 10ns / 10ns

`define KISHMAR_FIFO; // INTEL_FIFO // KISHMAR_FIFO

module fifo_tb;
  localparam                      SHOWAHEAD_TB    = 1; // change Intell's fifo parameter manually ( q_scfifo.scfifo_component.lpm_showahead )
  
  localparam                      DATA_WIDTH_TB   = 8;
  localparam                      ADRS_WIDTH_TB   = 8; 
  
  localparam                      TEST_ITERS      = 100000;
  localparam                      CLK_HLF_PER     = 2;
 
  localparam                      FIFO_SIZE       = 2 ** ADRS_WIDTH_TB;
  localparam                      DATA_MAX        = 2 ** DATA_WIDTH_TB - 1;
  
  localparam                      WR_DELAY_MAX    = 2 ** ( ADRS_WIDTH_TB / 4 );
  localparam                      WR_DELAY_MIN    = 2 ** ( ADRS_WIDTH_TB / 8 );
  localparam                      RD_DELAY_MAX    = WR_DELAY_MAX * 2; 
  localparam                      RD_DELAY_MIN    = WR_DELAY_MIN * 2; 
  localparam                      TEST_EDGE_MAX   = 16;  
  
  logic                           clk_tb;
  logic                           srst_tb;      // synchronous 
  
  logic                           wr_req_tb;
  logic [ DATA_WIDTH_TB - 1 : 0 ] wr_dat_tb;
  
  logic                           rd_req_tb;  
  logic [ DATA_WIDTH_TB - 1 : 0 ] rd_dat_tb;
  
  logic [ ADRS_WIDTH_TB - 1 : 0 ] usedw_tb;    // read data word
  bit                             empty_tb;
  bit                             full_tb;     // number of used words in fifo 

  logic [ DATA_WIDTH_TB - 1 : 0 ] fifo_mem  [ FIFO_SIZE - 1 : 0 ];
  logic [ DATA_WIDTH_TB - 1 : 0 ] mbx_r_wrd;
  
  logic [ 31 : 0 ]                test_iter_num;
  logic                           bigger_read_delay;

//ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo 


task transmitter ( input mailbox #( logic [ DATA_WIDTH_TB - 1 : 0 ] ) mbx_t );
  repeat ( TEST_ITERS ) begin
    if ( srst_tb ) 
      begin
        @( posedge clk_tb );
        wr_req_tb = 0;
        
        repeat ( $urandom_range ( WR_DELAY_MAX, WR_DELAY_MIN ) ) @( posedge clk_tb );

        if ( mbx_t.num() < ( FIFO_SIZE ) ) 
          begin
            wr_dat_tb = $urandom_range ( DATA_MAX, 0 );
            wr_req_tb = 1;
            @( posedge clk_tb );
            wr_req_tb = 0;  
            if ( SHOWAHEAD_TB ) 
              @( posedge clk_tb );
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
static logic [ 31 : 0 ] b_r_d_cnt = 0;
static logic            bigger_read_delay_tmp = bigger_read_delay;
  forever begin
    test_iter_num = test_iter_num + 1;
    
    if      ( mbx_r.num() == FIFO_SIZE - 1 ) bigger_read_delay_tmp = 0;
    else if ( mbx_r.num() == 0             ) bigger_read_delay_tmp = 1;
    
    // this next if-else makes sure we keep testing a full or an empty FIFO for a while
    if      ( ( bigger_read_delay_tmp !== bigger_read_delay ) & ( b_r_d_cnt < TEST_EDGE_MAX ) )
      b_r_d_cnt = b_r_d_cnt + 1;
    else if ( ( bigger_read_delay_tmp !== bigger_read_delay ) & ( b_r_d_cnt > TEST_EDGE_MAX - 1 ) )
      begin 
        b_r_d_cnt = 0;
        bigger_read_delay = bigger_read_delay_tmp;
      end     
    
    if       ( bigger_read_delay  ) repeat ( $urandom_range ( RD_DELAY_MAX,     RD_DELAY_MIN     ) ) @( posedge clk_tb );
    else if  ( !bigger_read_delay ) repeat ( $urandom_range ( RD_DELAY_MAX / 4, RD_DELAY_MIN / 4 ) ) @( posedge clk_tb );      
    
    if ( mbx_r.num() > 0 )  
      begin
        rd_req_tb = 1; 
        @( posedge clk_tb );
        void '( mbx_r.try_get( mbx_r_wrd ) );
        rd_req_tb = 0;
      end
  end
endtask : receiver

//-----------------------------------------------------------------------

task static monitor ();
  forever begin
    fork 
      check_content   ();  
      check_full      ();      
      check_empty     ();
      check_usedw     ();
      $display ( " \n >>> ERROR LIST : ( iterations ) output_normal / usedw / full / empty / output_SHOWAHEAD : ( %0d ) %0d / %0d / %0d / %0d / %0d \n ", 
                   test_iter_num,            check_NORMAL.errors_norm,     
                   check_usedw.errors_usedw, check_full.errors_full, 
                   check_empty.errors_empty, check_SHOWAHEAD.errors_sh_ahead  );
    join
  end
endtask : monitor


task static check_content ( );
  begin
    if ( SHOWAHEAD_TB ) check_SHOWAHEAD ();
    else                check_NORMAL    ();
  end
endtask : check_content


task static check_NORMAL ( );
  static int errors_norm = 0;
  begin    
    @( posedge clk_tb );
    if ( rd_dat_tb !== mbx_r_wrd )
      begin
        errors_norm = errors_norm + 1; 
        //$display ( " \n ERROR! Wrong output - received / expected : %0d / %0d \n", rd_dat_tb, mbx_r_wrd );
        //$stop;
      end      
  end
endtask : check_NORMAL


task static check_SHOWAHEAD();
  static int errors_sh_ahead = 0;
  static logic [ DATA_WIDTH_TB - 1 : 0 ] mbx_peek_word = 0;
  begin
    void '( fifo_mbx.try_peek ( mbx_peek_word ) );
    @( posedge clk_tb );
    if ( rd_dat_tb !== mbx_peek_word )
      begin
        errors_sh_ahead = errors_sh_ahead + 1;        
        //$display ( " \n ERROR! Wrong SHOWAHEAD word - received / current : %0d / %0d \n", rd_dat_tb, mbx_peek_word );
        //$stop;
      end 
    else 
      $display ( " \n <<< SUCCESSFULL SHOWAHEAD CHECK - received / expected : %0d / %0d \n", rd_dat_tb, mbx_peek_word );   
  end
endtask : check_SHOWAHEAD


task static check_full();
  static int errors_full = 0;
  static logic full_tb_true;
  static logic wr_req_tb_del_f;
  begin
    @( posedge clk_tb );
    wr_req_tb_del_f = wr_req_tb;
    #1;  
    
    if ( ( fifo_mbx.num() == FIFO_SIZE ) | ( ( fifo_mbx.num() == FIFO_SIZE - 1  ) & ( wr_req_tb_del_f ) & ( SHOWAHEAD_TB ) ) )
      full_tb_true = 1;
    else 
      full_tb_true = 0;
    
    if ( full_tb !== full_tb_true )
      begin
        errors_full = errors_full + 1;  
        //$display ( " \n ERROR! Wrong FIFO full out - fifo_mbx.num() / full_tb : %0d / %0d \n ", fifo_mbx.num(), full_tb );
        //$stop;
      end    
  end
endtask : check_full


task static check_empty ();
  static int errors_empty = 0;
  begin
    @( posedge clk_tb ); #1;
    if ( ( ( fifo_mbx.num() == 0 ) & ( empty_tb !== 1 ) ) | ( ( fifo_mbx.num() !== 0 ) & ( empty_tb !== 0 ) ) ) 
      begin
        errors_empty = errors_empty + 1; 
        //$display ( " \n ERROR! Wrong FIFO empty out - fifo_mbx.num() / empty_tb : %0d / %0d \n ", fifo_mbx.num(), empty_tb ); 
        $stop;
      end   
  end
endtask : check_empty


task static check_usedw ();
  static int errors_usedw = 0;
  static int mbx_num = 0;
  static logic wr_req_tb_del;
  begin
    @( posedge clk_tb ); 
    wr_req_tb_del = wr_req_tb;
    #1;
    mbx_num = ( ( wr_req_tb_del ) & ( SHOWAHEAD_TB ) ) ? fifo_mbx.num() + 1 : fifo_mbx.num();
    if ( ( ( mbx_num !== FIFO_SIZE ) & ( usedw_tb !== mbx_num ) ) | 
         ( ( mbx_num ==  FIFO_SIZE ) & ( usedw_tb !== 0       ) ) )
      begin
        errors_usedw = errors_usedw + 1;      
        //$display ( " \n ERROR! Wrong FIFO words num - received / expected / fifo_mbx.num() : %0d / %0d / %0d \n", usedw_tb, mbx_num, fifo_mbx.num() );
        //$display ( " wr_req_tb_del / SHOWAHEAD_TB / full / empty : %0d / %0d / %0d / %0d \n", wr_req_tb_del, SHOWAHEAD_TB, full_tb, empty_tb );
        //$stop;
      end  
  end
endtask : check_usedw



//-----------------------------------------------------------------------

`ifdef KISHMAR_FIFO 
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


`elsif INTEL_FIFO
q_scfifo IP_fifo (
  .clock  ( clk_tb        ),
  .rdreq  ( rd_req_tb     ),
  .wrreq  ( wr_req_tb     ),
  .data   ( wr_dat_tb     ),
  .q      ( rd_dat_tb     ),
  .usedw  ( usedw_tb      ),
  .empty  ( empty_tb      ),
  .full   ( full_tb       )
);
`endif

  
  
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
      test_iter_num     = 0;
      bigger_read_delay = 1;
      wr_req_tb         = 0;
      rd_req_tb         = 0;
      wr_dat_tb         = '0;  
      mbx_r_wrd         = 0;
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

  
  
  
  