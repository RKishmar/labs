
`timescale 10ns / 10ns

module packet_resolver_tb; 
  localparam                         TEST_LENGTH      = 222222;
  localparam                         ERR_CNT_SIZE     = 16;  
  localparam                         DEL_CNT_SIZE     = 8;  
  localparam                         CLK_HLFPER       = 2; 

  localparam                         DATAWIDTH_TB     = 64;
  localparam                         EMPTWIDTH_TB     = 3;  
  localparam                         CHANWIDTH_TB     = 1;
  localparam                         TARGETCHN_TB     = 1;
  localparam                         MAXBYTESN_TB     = 1514;   
  localparam                         MINBYTESN_TB     = 60; 
  
  localparam                         GEN_DEL_MAX      = CLK_HLFPER  * 2;  
  localparam                         SCB_DEL_MAX      = 4;
  localparam                         PACK_NUM_BITSIZE = $bits ( MAXBYTESN_TB );
  
  localparam                         BIG_PACK_DIST    = 1;
  localparam                         SMALL_PACK_DIST  = BIG_PACK_DIST * 10;
  
  logic                              srst_tb;  
  logic                              clk_tb;


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
      rand bit [ DATAWIDTH_TB - 1 : 0 ] data;
      rand bit [ EMPTWIDTH_TB - 1 : 0 ] empty;  
      rand bit                          valid;
      rand bit                          chan;
      rand bit                          s_o_p;
      rand bit                          e_o_p;
    } str;
    
    constraint s_o_p_cnst { this.str.s_o_p dist { 1 := 1, 0 := 9 }; }
    
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
      $display ( " Print packet content: %0p ", this.str );
    endfunction
  
  endclass 

//-----> generator <--------------------------------------------------------------------------------

  class generator;
    mailbox gen_mbx = new;
    packet  pck     = new;
    randc bit [ PACK_NUM_BITSIZE - 1 : 0 ] pack_size;  

    task run;
      forever
        begin
          this.pack_size = $random;
          #( $urandom_range( GEN_DEL_MAX ) );
          for ( int i = 0; i < this.pack_size; i++ ) 
            begin
              this.pck.randomize_packet;
              gen_mbx.put( this.pck );
              @( posedge clk_tb );
            end          
        end
    endtask : run  
  endclass : generator

//-----> driver <--------------------------------------------------------------------------------

  class driver;
    virtual avalon_st_if #( DATAWIDTH_TB, EMPTWIDTH_TB, 
                            CHANWIDTH_TB, TARGETCHN_TB ) drv_if; 
    mailbox dri_mbx = new;
    packet  pck     = new;
      
    task run;    
      forever 
        begin
          dri_mbx.get( pck );

          drv_if.data  = pck.str.data;     
          drv_if.empty = pck.str.empty;     
          drv_if.valid = pck.str.valid;
          drv_if.chan  = pck.str.chan;
          drv_if.s_o_p = pck.str.s_o_p;
          drv_if.e_o_p = pck.str.e_o_p;
          
          @ ( posedge clk_tb );

          drv_if.valid = 0; 
        end
    endtask 
  endclass : driver

//-----> monitor <---------------------------------------------------------------------------------

  class monitor;
    virtual avalon_st_if #( DATAWIDTH_TB, EMPTWIDTH_TB, 
                            CHANWIDTH_TB, TARGETCHN_TB ) .source_if mon_if;
    mailbox mon_mbx = new;
    packet  pck     = new; 
    
    task run;
      forever begin  
        pck.str.chan  = mon_if.chan; 
        pck.str.data  = mon_if.data;
        pck.str.valid = mon_if.valid;
        pck.str.empty = mon_if.empty;
        pck.str.s_o_p = mon_if.s_o_p;
        pck.str.e_o_p = mon_if.e_o_p;
        mon_if.ready  = 1;      
        this.mon_mbx.put( pck );
        @( posedge clk_tb ); 
        mon_if.ready  = 0;      
      end
    endtask
  endclass : monitor

//-----> scoreboard <------------------------------------------------------------------------------

  class scoreboard;
    logic [ ERR_CNT_SIZE - 1 : 0 ] err_cnt;
    logic [ DEL_CNT_SIZE - 1 : 0 ] del_cnt; 
    logic [ DATAWIDTH_TB - 1 : 0 ] pck_i_data_history [$];
    logic [ DATAWIDTH_TB - 1 : 0 ] pck_o_data_history [$];
    mailbox                        sbi_mbx = new;
    mailbox                        sbo_mbx = new;
    packet                         pck_i   = new;
    packet                         pck_o   = new;

    task run;
      begin  
        del_cnt = 0;
        err_cnt = 0;
        
        @( posedge clk_tb );
        
        forever begin 
        
          @( posedge clk_tb );

          fork 
            sbi_mbx.get( pck_i );
            sbo_mbx.get( pck_o );
          join
          
          pck_i_data_history = { pck_i_data_history, pck_i.str.data };        
          pck_o_data_history = { pck_o_data_history, pck_o.str.data };          
          
          if ( del_cnt < SCB_DEL_MAX )
            begin
              del_cnt = del_cnt + 1;
              pck_o_data_history.pop_front();
            end
          else
            begin
              if ( pck_i_data_history.pop_front() !== pck_o_data_history.pop_front() )
                if ( ( pck_i.str.valid ) && ( pck_i.str.chan == TARGETCHN_TB ) )     
                  err_cnt = err_cnt + 1;
              $display ( " ERRORS(timestamp): %d (%0t) \n", err_cnt, $time );
 
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
 
    virtual avalon_st_if #( DATAWIDTH_TB, EMPTWIDTH_TB, 
                            CHANWIDTH_TB, TARGETCHN_TB ) env_if_i;    
    virtual avalon_st_if #( DATAWIDTH_TB, EMPTWIDTH_TB, 
                            CHANWIDTH_TB, TARGETCHN_TB ) env_if_o;      

    function new;
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
      d_o.dri_mbx  = env_gen_mbx;
      g_o.gen_mbx  = env_gen_mbx;
      m_i.mon_mbx  = env_inp_mbx;
      s_i.sbi_mbx  = env_inp_mbx;
      s_i.sbo_mbx  = env_out_mbx;
      m_o.mon_mbx  = env_out_mbx;
    endfunction

    task run;
      begin 
        d_o.drv_if = env_if_i;
        m_o.mon_if = env_if_o;
        m_i.mon_if = env_if_i;
      
        fork
          d_o.run;
          m_i.run;
          m_o.run;
          g_o.run;
          s_i.run;
          #TEST_LENGTH $stop;
        join
      end
    endtask
  
  endclass : environment

//-----> test <------------------------------------------------------------------------------------

  class test;
    environment e0;

    function new;
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
    begin
      srst_tb = 0;
    end

  initial
    $timeformat(-9, 2, " ns", 20);
    
endmodule

  
  