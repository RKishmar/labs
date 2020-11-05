

module packet_resolver #( parameter DATAWIDTH_PR,
                          parameter EMPTWIDTH_PR,  
                          parameter CHANWIDTH_PR,
                          parameter TARGETCHN_PR )
(
  input        clk_i,
  input        srst_i,

  avalon_st_if sink_if,
  avalon_st_if source_if
);

  logic fifo_dat_wrreq;
  logic fifo_inf_wrreq;
  logic fifo_dat_rdreq;
  logic fifo_inf_rdreq;
  logic fifo_dat_empty;
  logic fifo_inf_empty;
  logic fifo_dat_full;  
  logic fifo_inf_full;  

struct packed {
  logic [ DATAWIDTH_PR - 1 : 0 ] data;
  logic                          chan;
  logic                          s_o_p;
  logic                          e_o_p;
} snk_to_fifo, fifo_to_src;

localparam DATAWIDTH_DAT_FI = $bits ( snk_to_fifo );

fifo_ip #( DATAWIDTH_DAT_FI ) 
fifo_ip_data (
      .clock ( clk_i          ), 
      .sclr  ( srst_i         ),  
      .data  ( snk_to_fifo    ), 
      .q     ( fifo_to_src    ),      
      .rdreq ( fifo_dat_rdreq ),
      .wrreq ( fifo_dat_wrreq ),   
      .empty ( fifo_dat_empty ),
      .full  ( fifo_dat_full  )
);

fifo_ip #( .DATAWIDTH_FI ( EMPTWIDTH_PR ) ) 
fifo_ip_info (
      .clock ( clk_i           ),
      .sclr  ( srst_i          ),   
      .data  ( sink_if.empty   ),
      .q     ( source_if.empty ),     
      .rdreq ( fifo_inf_rdreq  ),
      .wrreq ( fifo_inf_wrreq  ),   
      .empty ( fifo_inf_empty  ),
      .full  ( fifo_inf_full   )
);

assign snk_to_fifo.data  = sink_if.data;
assign snk_to_fifo.chan  = sink_if.chan;
assign snk_to_fifo.s_o_p = sink_if.s_o_p;
assign snk_to_fifo.e_o_p = sink_if.e_o_p;

assign source_if.data    = fifo_to_src.data;
assign source_if.chan    = fifo_to_src.chan;
assign source_if.s_o_p   = fifo_to_src.s_o_p;
assign source_if.e_o_p   = fifo_to_src.e_o_p;

assign source_if.valid   = !fifo_dat_empty   && !fifo_inf_empty;
assign sink_if.ready     = !fifo_dat_full    && !fifo_inf_full;
  
assign fifo_dat_wrreq    = !fifo_dat_full    && sink_if.valid    && ( sink_if.chan == TARGETCHN_PR );
assign fifo_inf_wrreq    = snk_to_fifo.e_o_p && fifo_dat_wrreq;
assign fifo_dat_rdreq    = source_if.ready   && !fifo_dat_empty;
assign fifo_inf_rdreq    = fifo_to_src.e_o_p && fifo_dat_rdreq;

endmodule


