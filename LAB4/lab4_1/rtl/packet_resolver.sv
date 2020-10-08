

module packet_resolver #( parameter DATAWIDTH_PR ,
                          parameter EMPTWIDTH_PR ,  
                          parameter CHANWIDTH_PR ,
                          parameter TARGETCHN_PR ,
                          parameter MAXBYTESN_PR ,   
                          parameter MINBYTESN_PR )
(
  input                   clk_i,
  input                   srst_i,

  avalon_st_if.sink_if    sink_if,
  avalon_st_if.source_if  source_if
);

struct {
  logic wrreq;
  logic rdreq;
  logic empty;
  logic full;  
} srv_data, srv_info;

struct packed {
  logic [ DATAWIDTH_PR - 1 : 0 ] data;
  logic                          chan;
  logic                          s_o_p;
  logic                          e_o_p;
} snk_to_fifo, fifo_to_src;

localparam DATAWIDTH_DAT_FI = $bits ( snk_to_fifo );

fifo_ip #( .DATAWIDTH_FI ( DATAWIDTH_DAT_FI ) ) 
fifo_ip_data (
      .clock ( clk_i          ), //
      .sclr  ( srst_i         ), //  
      .data  ( snk_to_fifo    ), //
      .q     ( fifo_to_src    ),	  
      .rdreq ( srv_data.rdreq ),
      .wrreq ( srv_data.wrreq ),   
      .empty ( srv_data.empty ),
      .full  ( srv_data.full  )
);

assign snk_to_fifo.data  = sink_if.data;
assign snk_to_fifo.chan  = sink_if.chan;
assign snk_to_fifo.s_o_p = sink_if.s_o_p;
assign snk_to_fifo.e_o_p = sink_if.e_o_p;

assign source_if.data    = fifo_to_src.data;
assign source_if.chan    = fifo_to_src.chan;
assign source_if.s_o_p   = fifo_to_src.s_o_p;
assign source_if.e_o_p   = fifo_to_src.e_o_p;
assign source_if.valid   = !srv_data.empty && !srv_info.empty;

assign sink_if.ready     = !srv_data.full && !srv_info.full;

assign srv_data.rdreq    = source_if.ready && !srv_data.empty;
assign srv_data.wrreq    = sink_if.valid   && !srv_data.full;


fifo_ip #( .DATAWIDTH_FI ( EMPTWIDTH_PR ) ) 
fifo_ip_info (
      .clock ( clk_i           ),
      .sclr  ( srst_i          ),   
      .data  ( sink_if.empty   ),
      .q     ( source_if.empty ),	  
      .rdreq ( srv_info.rdreq  ),
      .wrreq ( srv_info.wrreq  ),   
      .empty ( srv_info.empty  ),
      .full  ( srv_info.full   )
);

assign srv_info.wrreq  = snk_to_fifo.e_o_p && !srv_info.full;
assign srv_info.rdreq  = !srv_info.empty;  

endmodule
