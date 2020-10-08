
module packet_resolver_top #( parameter  DATAWIDTH_TP,
                              parameter  EMPTWIDTH_TP,  
                              parameter  CHANWIDTH_TP,
                              parameter  TARGETCHN_TP,
                              parameter  MAXBYTESN_TP,   
                              parameter  MINBYTESN_TP )
( input                                  clk_i,
  input                                  srst_i,
  // Avalon-ST Sink
  output logic                           ast_ready_o,
  input  logic [ DATAWIDTH_TP - 1 : 0 ]  ast_data_i,
  input  logic [ EMPTWIDTH_TP - 1 : 0 ]  ast_empty_i,
  input  logic [ CHANWIDTH_TP - 1 : 0 ]  ast_channel_i,  
  input  logic                           ast_valid_i,
  input  logic                           ast_startofpacket_i,
  input  logic                           ast_endofpacket_i,
  // Avalon-ST Source
  input  logic                           ast_ready_i,
  output logic [ DATAWIDTH_TP - 1 : 0 ]  ast_data_o,
  output logic [ EMPTWIDTH_TP - 1 : 0 ]  ast_empty_o,   
  output logic                           ast_valid_o,
  output logic                           ast_startofpacket_o,
  output logic                           ast_endofpacket_o
);

avalon_st_if    #( .DATAWIDTH_IF ( DATAWIDTH_TP ),
                   .EMPTWIDTH_IF ( EMPTWIDTH_TP ),  
                   .CHANWIDTH_IF ( CHANWIDTH_TP ),
                   .TARGETCHN_IF ( TARGETCHN_TP ),
                   .MAXBYTESN_IF ( MAXBYTESN_TP ),   
                   .MINBYTESN_IF ( MINBYTESN_TP ) ) 
sink_if_inst ( clk_i, srst_i );



avalon_st_if    #( .DATAWIDTH_IF ( DATAWIDTH_TP ),
                   .EMPTWIDTH_IF ( EMPTWIDTH_TP ),  
                   .CHANWIDTH_IF ( CHANWIDTH_TP ),
                   .TARGETCHN_IF ( TARGETCHN_TP ),
                   .MAXBYTESN_IF ( MAXBYTESN_TP ),   
                   .MINBYTESN_IF ( MINBYTESN_TP ) )  
source_if_inst ( clk_i, srst_i );


packet_resolver #( .DATAWIDTH_PR ( DATAWIDTH_TP ),
                   .EMPTWIDTH_PR ( EMPTWIDTH_TP ),  
                   .CHANWIDTH_PR ( CHANWIDTH_TP ),
                   .TARGETCHN_PR ( TARGETCHN_TP ),
                   .MAXBYTESN_PR ( MAXBYTESN_TP ),   
                   .MINBYTESN_PR ( MINBYTESN_TP ) ) resolver_0 (
                   .clk_i        ( clk_i          ),
                   .srst_i       ( srst_i         ),
                   .sink_if      ( sink_if_inst   ),
                   .source_if    ( source_if_inst )
);


always_ff @( posedge clk_i )
  begin
    source_if_inst.ready <= ast_ready_i;
    sink_if_inst.data    <= ast_data_i;
    sink_if_inst.valid   <= ast_valid_i;
    sink_if_inst.s_o_p   <= ast_startofpacket_i;
    sink_if_inst.e_o_p   <= ast_endofpacket_i;
    sink_if_inst.empty   <= ast_empty_i;
    sink_if_inst.chan    <= ast_channel_i;
  end

always_ff @( posedge clk_i )
  begin
    if ( !srst_i )
      begin
        ast_data_o          <= 0;
        ast_valid_o         <= 0;
        ast_startofpacket_o <= 0;
        ast_endofpacket_o   <= 0;
        ast_empty_o         <= 0;
        ast_ready_o         <= 0;
      end
    else
      begin
        ast_data_o          <= source_if_inst.data;
        ast_valid_o         <= source_if_inst.valid;
        ast_startofpacket_o <= source_if_inst.s_o_p;
        ast_endofpacket_o   <= source_if_inst.e_o_p;
        ast_empty_o         <= source_if_inst.empty;
        ast_ready_o         <= sink_if_inst.ready;
      end
  end

endmodule
 