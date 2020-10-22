
`timescale 10ns / 10ns

module packet_resolver_tb; 
  localparam                         TEST_ITERS       = 22222;
  localparam                         ERR_CNT_SIZE     = 16;  
  localparam                         CLK_HLFPER       = 2; 

  localparam                         DATAWIDTH_TB     = 64;
  localparam                         EMPTWIDTH_TB     = 3;  
  localparam                         CHANWIDTH_TB     = 1;
  localparam                         TARGETCHN_TB     = 1;
  localparam                         MAXBYTESN_TB     = 1514;   
  localparam                         MINBYTESN_TB     = 60; 
  localparam                         GEN_DEL_MAX      = CLK_HLFPER * 16;  
  localparam                         MIN_RST_DLY      = CLK_HLFPER * MAXBYTESN_TB * 2;
  localparam                         MAX_RST_DLY      = 32 * MIN_RST_DLY;
  localparam                         MIN_RST_HLD      = 1;
  localparam                         MAX_RST_HLD      = CLK_HLFPER * 8;

  localparam                         PACK_NUM_BITSIZE = $bits ( MAXBYTESN_TB );
  localparam                         TEST_NUM_BITSIZE = $bits ( TEST_ITERS   );
  
  localparam                         BIG_PACK_DIST    = 2;
  localparam                         SMALL_PACK_DIST  = BIG_PACK_DIST * 10;
  
  logic                              srst_tb;  
  logic                              clk_tb;
  logic [ DATAWIDTH_TB - 1 : 0 ]     fifo_mem  [ PACK_NUM_BITSIZE - 1 : 0 ];
  logic [ DATAWIDTH_TB - 1 : 0 ]     mbx_r_wrd;
  
  logic [ TEST_NUM_BITSIZE - 1 : 0 ] test_iter_num;


//-----> DUT interface <-----------------------------------------------------------------------------------


  avalon_st_if #( DATAWIDTH_TB, EMPTWIDTH_TB, CHANWIDTH_TB, TARGETCHN_TB ) 
    top_if_i ( clk_tb, srst_tb );
  
  avalon_st_if #( DATAWIDTH_TB, EMPTWIDTH_TB, CHANWIDTH_TB, TARGETCHN_TB ) 
    top_if_o ( clk_tb, srst_tb );

  
//-----> DUT inst <-----------------------------------------------------------------------------------

  packet_resolver_top #( DATAWIDTH_TB, EMPTWIDTH_TB, 
                         CHANWIDTH_TB, TARGETCHN_TB )
  packet_resolver_DUT
  ( .clk_i               ( clk_tb         ),
    .srst_i              ( srst_tb        ),
    .ast_ready_o         ( top_if_i.ready ),
    .ast_data_i          ( top_if_i.data  ),
    .ast_empty_i         ( top_if_i.empty ),
    .ast_channel_i       ( top_if_i.chan  ),  
    .ast_valid_i         ( top_if_i.valid ),
    .ast_startofpacket_i ( top_if_i.s_o_p ),
    .ast_endofpacket_i   ( top_if_i.e_o_p ), 
    .ast_ready_i         ( top_if_o.ready ),
    .ast_data_o          ( top_if_o.data  ),
    .ast_empty_o         ( top_if_o.empty ),   
    .ast_valid_o         ( top_if_o.valid ),
    .ast_startofpacket_o ( top_if_o.s_o_p ),
    .ast_endofpacket_o   ( top_if_o.e_o_p )
  );  

//-----> transaction <--------------------------------------------------------------------------------

  class packet;
    struct {
      bit [ DATAWIDTH_TB - 1 : 0 ] data;
      bit [ EMPTWIDTH_TB - 1 : 0 ] empty;  
      bit                          valid;
      bit                          chan;
      bit                          s_o_p;
      bit                          e_o_p;
    } str;
    
    
    function void randomize_packet;
      begin
        this.str.data  = $random;
        this.str.empty = $random;
        this.str.valid = $random;
        this.str.chan  = $random;
        this.str.s_o_p = $random;
        this.str.e_o_p = $random;
      end
    endfunction
          
    function void print;
      $display ( " Packet content -> data: %0d, empty: %0d, valid: %0b, chan: %0d, sop/eop: %0b/%0b ", 
                 str.data, str.empty, str.valid, str.chan, str.s_o_p, str.e_o_p );
    endfunction
  
  endclass 

//-----> generator <--------------------------------------------------------------------------------

  class generator;
    mailbox gen_mbx;
    event drv_done;
    randc bit [ PACK_NUM_BITSIZE - 1 : 0 ] pack_size;  
    /*constraint config_packet_size { pack_size dist { [     MAXBYTESN_TB     : 2 * MINBYTESN_TB ] := BIG_PACK_DIST, 
                                                     [ 2 * MINBYTESN_TB - 1 :     MINBYTESN_TB ] := SMALL_PACK_DIST }; } */ 
    task run;
      $display ( " GEN RUN START " );
        forever
          begin
            this.pack_size = $random;
            #( $urandom_range( GEN_DEL_MAX ) );
            for ( int i = 0; i < this.pack_size; i++ ) 
              begin
                packet pck = new;
                pck.randomize_packet;
                gen_mbx.put( pck );
              end
            @( drv_done );            
          end

    endtask : run
  
  endclass 

//-----> driver <--------------------------------------------------------------------------------

  class driver;
    virtual avalon_st_if #( DATAWIDTH_TB, EMPTWIDTH_TB, 
                            CHANWIDTH_TB, TARGETCHN_TB ) drv_if; 
    event   drv_done;
    mailbox dri_mbx;
    packet  pck;

    task run;
      begin
	    $display ( " DRV RUN START " );
        pck = new;     
        forever 
          begin  
            dri_mbx.get( pck );
            $display ( " DRIVER GET PACKAGE DONE " );
            { >> { drv_if } } = pck.str; // drive packed data to unpacked structure (interface)
            $display ( " DRIVER DRIVE IF DONE " );
            @ ( posedge clk_tb );
          end
        -> drv_done;

      end 
    endtask
  
  endclass : driver

//-----> monitor <---------------------------------------------------------------------------------

  class monitor;
    virtual avalon_st_if #( DATAWIDTH_TB, EMPTWIDTH_TB, 
                            CHANWIDTH_TB, TARGETCHN_TB ) mon_if;
    mailbox mon_mbx;
    packet  pck;

    task run; 
      begin $display ( " MON NEW START " );
        pck = new;         
        forever begin $display ( " MON SAMPLEPORT START2 " );
          @( posedge clk_tb );   
          pck.str = { >> { mon_if } }; // drive unpacked data to a packed structure
          $display ( " MONITOR pck.str: %0p", pck.str );
          mon_mbx.put( pck );
        end
      end
    endtask
  endclass : monitor

//-----> scoreboard <------------------------------------------------------------------------------

  class scoreboard;
    logic [ ERR_CNT_SIZE - 1 : 0 ] err;

    mailbox      sbi_mbx;
    mailbox      sbo_mbx;
    packet       pck_i;
    packet       pck_o;
  
    task run;
      begin  
        pck_i = new;
        pck_o = new;
        forever begin $display ( " SCB RUN START " );
          @( posedge clk_tb );
          if ( srst_tb )
            begin 
              fork 
                sbi_mbx.get( pck_i );
                sbo_mbx.get( pck_o );
              join 
              $display ( " SCOREBOARD CHECK START pck_o / pck_i: %0h / %0h", pck_o, pck_i );
            if ( pck_i.str.chan == TARGETCHN_TB )
              begin     
                if ( pck_o !== pck_i ) 
                  begin
                    err = err + 1;
                    $error ( " input/output mismatch " );
                  end
                else
                  $display ( "OK! packages match: %0h", pck_i );
              end
        
            pck_i.print;
            pck_o.print;
          end 
        end       
      end
    endtask
  endclass : scoreboard

//-----> environment <-----------------------------------------------------------------------------

  class environment;
    driver        d_o;         
    monitor       m_o;         
    monitor       m_i;         
    generator     g_o;         
    scoreboard    s_i;         

    mailbox   env_gen_mbx;        
    mailbox   env_inp_mbx;        
    mailbox   env_out_mbx;        
    event     drv_done;           
 
    virtual avalon_st_if #( DATAWIDTH_TB, EMPTWIDTH_TB, 
                            CHANWIDTH_TB, TARGETCHN_TB ) env_if_i;    
    virtual avalon_st_if #( DATAWIDTH_TB, EMPTWIDTH_TB, 
                            CHANWIDTH_TB, TARGETCHN_TB ) env_if_o;      

    function new;
      $display ( " ENV NEW START " );
	  fork
        d_o          = new;
        g_o          = new;	  
        m_o          = new;
        m_i          = new;
        s_i          = new;
        env_gen_mbx  = new;
        env_inp_mbx  = new;
        env_out_mbx  = new;
	  join
      $display ( " ENV NEW2 START " );
      d_o.dri_mbx  = env_gen_mbx;
      g_o.gen_mbx  = env_gen_mbx;
      m_i.mon_mbx  = env_inp_mbx;
      s_i.sbi_mbx  = env_inp_mbx;
      s_i.sbo_mbx  = env_out_mbx;
      m_o.mon_mbx  = env_out_mbx;
      $display ( " ENV NEW3 START " );
      d_o.drv_done = drv_done;
      g_o.drv_done = drv_done;
    endfunction

    task run;
      begin 
        d_o.drv_if = env_if_i;
        m_o.mon_if = env_if_o;
        m_i.mon_if = env_if_i;
      
        fork
          $display ( " ENV ALL MODS RUN START " );
          d_o.run;
          m_i.run;
          m_o.run;
          g_o.run;
          s_i.run;
		  #222;
        join
      end
    endtask
  
  endclass : environment

//-----> test <------------------------------------------------------------------------------------

  class test;
    environment e0;

    function new;
      $display ( " TEST NEW START " );
      e0 = new;
    endfunction

    task run;
      e0.run;
    endtask
  
  endclass : test

//-----> initial <---------------------------------------------------------------------------------


  initial // main
    begin
      automatic test t0 = new;
      t0.e0.env_if_i = top_if_i;
      t0.e0.env_if_o = top_if_o;

      t0.run;
    end

  always 
    begin
      clk_tb = 1; #CLK_HLFPER; 
      clk_tb = 0; #CLK_HLFPER;
    end
  
  initial
    forever 
      begin
        //srst_tb = 0; #( $urandom_range ( MIN_RST_HLD, MAX_RST_HLD ) );      
        srst_tb = 1; #( $urandom_range ( MIN_RST_DLY, MAX_RST_DLY ) );   
      end
  
  initial
    begin
      test_iter_num = 0; 
    end


    
endmodule

  
  