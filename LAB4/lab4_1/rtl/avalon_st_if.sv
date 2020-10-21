interface avalon_st_if #( parameter DATAWIDTH_IF,
                          parameter EMPTWIDTH_IF,  
                          parameter CHANWIDTH_IF,
                          parameter TARGETCHN_IF )
                        ( input     clk_i,
                          input     srst_i );
                                  
  parameter DATBYTNUM_IF = DATAWIDTH_IF / 8;  
  
  logic [ DATBYTNUM_IF - 1 : 0 ] [ 7 : 0 ] data;  
  logic [ EMPTWIDTH_IF - 1 : 0 ]           empty;
  logic                                    valid;  
  logic [ CHANWIDTH_IF - 1 : 0 ]           chan;  
  logic                                    ready;
  logic                                    s_o_p;
  logic                                    e_o_p;

  modport source_if ( input  ready, output data, valid, empty, chan, s_o_p, e_o_p );
  modport sink_if   ( output ready, input  data, valid, empty, chan, s_o_p, e_o_p );

endinterface