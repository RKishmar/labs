
module fifo_ad 
( input                           clk_i,
  input                           srst_i,      
  input  logic                    rd_req_i,  
  input  logic                    wr_req_i,
  input  logic [ DWID - 1 : 0 ] data_i,
  output logic [ DWID - 1 : 0 ] q_o,
  output logic [ AWID - 1 : 0 ] usedw_o,         
  output logic                    empty_o,
  output logic                    full_o      
);

localparam DWID = 8;
localparam AWID = 8;
localparam SHWA = 0;


fifo # (
  .DWIDTH    ( DWID     ),
  .AWIDTH    ( AWID     ),
  .SHOWAHEAD ( SHWA     ) )
FIFO_0 (
  .clk_i     ( clk_i    ),
  .srst_i    ( srst_i   ),
  .rd_req_i  ( rd_req_i ),
  .wr_req_i  ( wr_req_i ),
  .data_i    ( data_i   ),
  .q_o       ( q_o      ),
  .usedw_o   ( usedw_o  ),
  .empty_o   ( empty_o  ),
  .full_o    ( full_o   )
);  

endmodule
