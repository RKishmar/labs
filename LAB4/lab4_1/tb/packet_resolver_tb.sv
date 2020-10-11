
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
  
  localparam                         MIN_RST_DLY      = CLK_HLFPER * MAXBYTESN_TB * 2;
  localparam                         MAX_RST_DLY      = 32 * MIN_RST_DLY;
  localparam                         MIN_RST_HLD      = 1;
  localparam                         MAX_RST_HLD      = CLK_HLFPER * 8;

  localparam                         PACK_NUM_BITSIZE = $bits ( MAXBYTESN_TB );
  localparam                         TEST_NUM_BITSIZE = $bits ( TEST_ITERS   );
  
  localparam                         BIG_PACK_DIST    = 2;
  localparam                         SMALL_PACK_DIST  = BIG_PACK_DIST * 10;
  
  logic                              clk_tb;
  logic [ DATAWIDTH_TB - 1 : 0 ]     fifo_mem  [ PACK_NUM_BITSIZE - 1 : 0 ];
  logic [ DATAWIDTH_TB - 1 : 0 ]     mbx_r_wrd;
  
  logic [ TEST_NUM_BITSIZE - 1 : 0 ] test_iter_num;


//-----> DUT interface <-----------------------------------------------------------------------------------
 
  interface dut_if ( input logic   clk_tb );
    logic                          srst;    
 
    logic                          ready_o;
    logic [ DATAWIDTH_TB - 1 : 0 ] data_i;
    logic [ EMPTWIDTH_TB - 1 : 0 ] empty_i;
    logic [ CHANWIDTH_TB - 1 : 0 ] channel_i;  
    logic                          valid_i;
    logic                          startofpacket_i;
    logic                          endofpacket_i;

    logic                          ready_i;
    logic [ DATAWIDTH_TB - 1 : 0 ] data_o;
    logic [ EMPTWIDTH_TB - 1 : 0 ] empty_o;   
    logic                          valid_o;
    logic                          startofpacket_o;
    logic                          endofpacket_o;
  endinterface 

  virtual dut_if top_if;  
  
//-----> DUT inst <-----------------------------------------------------------------------------------

  packet_resolver_top #( 
    .DATAWIDTH_TP        ( DATAWIDTH_TB           ),
    .EMPTWIDTH_TP        ( EMPTWIDTH_TB           ),  
    .CHANWIDTH_TP        ( CHANWIDTH_TB           ),
    .TARGETCHN_TP        ( TARGETCHN_TB           ),
    .MAXBYTESN_TP        ( MAXBYTESN_TB           ),   
    .MINBYTESN_TP        ( MINBYTESN_TB           ) )
  packet_resolver_DUT
  ( .clk_i               ( clk_tb                 ),
    .srst_i              ( top_if.srst            ),
    .ast_ready_o         ( top_if.ready_o         ),
    .ast_data_i          ( top_if.data_i          ),
    .ast_empty_i         ( top_if.empty_i         ),
    .ast_channel_i       ( top_if.channel_i       ),  
    .ast_valid_i         ( top_if.valid_i         ),
    .ast_startofpacket_i ( top_if.startofpacket_i ),
    .ast_endofpacket_i   ( top_if.endofpacket_i   ),
    .ast_ready_i         ( top_if.ready_i         ),
    .ast_data_o          ( top_if.data_o          ),
    .ast_empty_o         ( top_if.empty_o         ),   
    .ast_valid_o         ( top_if.valid_o         ),
    .ast_startofpacket_o ( top_if.startofpacket_o ),
    .ast_endofpacket_o   ( top_if.endofpacket_o   )
  );  

//-----> transaction <--------------------------------------------------------------------------------

  class packet;
    randc bit [ DATAWIDTH_TB - 1 : 0 ] data;
    randc bit [ EMPTWIDTH_TB - 1 : 0 ] empty;  
    rand  bit                          valid;
    rand  bit                          chan;
          bit                          s_o_p;
          bit                          e_o_p;
    
    function void print ( );
      $display ( " Packet content -> data: %0d, empty: %0d, valid: %0b, chan: %0d, sop/eop: %0b/%0b ", 
                 data, empty, valid, chan, s_o_p, e_o_p );
    endfunction
  
  endclass : packet

//-----> generator <--------------------------------------------------------------------------------

  class generator;
    mailbox gen_mbx;
    event drv_done;

    randc bit [ PACK_NUM_BITSIZE - 1 : 0 ] pack_size;  
    constraint config_packet_size { pack_size dist { [     MAXBYTESN_TB     : 3 * MINBYTESN_TB ] := BIG_PACK_DIST, 
                                                     [ 3 * MINBYTESN_TB - 1 :     MINBYTESN_TB ] := SMALL_PACK_DIST }; }  
    task run();
      forever
        begin
          this.pack_size = $urandom_range ( MINBYTESN_TB : MAXBYTESN_TB );
          #( $urandom_range( 16 * CLK_HLFPER ) );
          for ( int i = 0; i < this.pack_size; i++ ) 
            begin
              packet pck = new;
              pck.randomize();
              gen_mbx.put( pck );
            end
          @( drv_done );            
        end
    endtask : run
  
  endclass : generator

//-----> driver <--------------------------------------------------------------------------------

  class driver;
    virtual dut_if drv_if;
    event drv_done;
    mailbox dri_mbx;
    mailbox dro_mbx;

    task run();
      forever 
        begin
          packet pck = new; 
          while ( dri_mbx.try_peek( pck ) )
            begin
              dri_mbx.get( pck );

              drv_if.data_i          <= pck.data;     
              drv_if.empty_i         <= pck.empty;     
              drv_if.valid_i         <= pck.valid;
              drv_if.channel_i       <= pck.chan;
              drv_if.startofpacket_i <= pck.s_o_p;
              drv_if.endofpacket_i   <= pck.e_o_p;
          
              @ ( posedge clk_tb );
        
              dro_mbx.put( pck );     
        
              drv_if.valid <= 0; 
            end
          -> drv_done;
        end
    endtask
  
  endclass : driver

//-----> monitor <---------------------------------------------------------------------------------

  class monitor;
    virtual dut_if mon_if;
    mailbox mon_mbx;

    task run();
      sample_port();
    endtask

    task sample_port();
      forever begin
        if ( mon_if.srst )
          begin
            packet pck = new;
          
            @( posedge clk_tb );   
          
            pck.chan  = mon_if.channel_i; 
            pck.data  = mon_if.data_o;
            pck.valid = mon_if.valid_o;
            pck.empty = mon_if.empty_o;
            pck.s_o_p = mon_if.startofpacket_o;
            pck.e_o_p = mon_if.endofpacket_o;
        
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
  
    task run();
      forever begin
      
        fork 
          sbi_mbx.get( pck_i );
          sbo_mbx.get( pck_o );
        join 
        
// expand/rewrite the final checker
        if ( pck_i.chan == TARGETCHN_TB )
          begin     
            assert ( pck_o == pck_i )
            else 
              begin
                err = err + 1;
                $error ( " input/output mismatch " );
              end
          end
        
        pck_i.print();
        pck_o.print();
            
      end
    endtask
  endclass : scoreboard

//-----> environment <-----------------------------------------------------------------------------

  class environment;
    driver        d0;         
    monitor       m0;         
    generator     g0;         
    scoreboard    s0;         

    mailbox   env_gen_mbx;        
    mailbox   env_inp_mbx;        
    mailbox   env_out_mbx;        
    event     drv_done;           
 
    virtual dut_if env_if;    

    function new();
      d0          = new;
      m0          = new;
      g0          = new;
      s0          = new;
      env_gen_mbx = new();
      env_inp_mbx = new();
      env_out_mbx = new();

      d0.dri_mbx  = env_gen_mbx;
      g0.gen_mbx  = env_gen_mbx;
      d0.dro_mbx  = env_inp_mbx;
      s0.sbi_mbx  = env_inp_mbx;
      s0.sbo_mbx  = env_out_mbx;
      m0.mon_mbx  = env_out_mbx;
      
      d0.drv_done = drv_done;
      g0.drv_done = drv_done;
    endfunction

    virtual task run();
      d0.drv_if = env_if;
      m0.mon_if = env_if;
      
      fork
        d0.run();
        m0.run();
        g0.run();
        s0.run();
      join_any
    endtask
  
  endclass : environment

//-----> test <------------------------------------------------------------------------------------

  class test;
    environment e0;

    function new();
      e0 = new;
    endfunction

    task run();
      e0.run();
    endtask
  
  endclass : test

//-----> initial <---------------------------------------------------------------------------------


  initial 
    begin
      automatic test t0 = new;
      t0.e0.env_if = top_if;
      t0.run();
    end

  always 
    begin
      clk_tb = 1; #CLK_HLFPER; 
      clk_tb = 0; #CLK_HLFPER;
    end
  
  initial
    forever 
      begin
        top_if.srst = 0; #( $urandom_range ( MIN_RST_HLD, MAX_RST_HLD ) );      
        top_if.srst = 1; #( $urandom_range ( MIN_RST_DLY, MAX_RST_DLY ) );   
      end
  
  initial
    begin
      test_iter_num = 0; 
    end


    
endmodule

  
  