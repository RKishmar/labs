

module fifo #( parameter     DWIDTH,
               parameter     AWIDTH,  
               parameter bit SHOWAHEAD )
( input                           clk_i,
  input                           srst_i,      
  input  logic                    rd_req_i,  
  input  logic                    wr_req_i,
  input  logic [ DWIDTH - 1 : 0 ] data_i,
  output logic [ DWIDTH - 1 : 0 ] q_o,
  output logic [ AWIDTH - 1 : 0 ] usedw_o,         
  output logic                    empty_o,
  output logic                    full_o      
);

localparam               FIFO_SIZE = 2 ** AWIDTH;

logic [ AWIDTH - 1 : 0 ] wr_adr;
logic [ AWIDTH - 1 : 0 ] rd_adr;
logic [ DWIDTH - 1 : 0 ] fifo_mem [ FIFO_SIZE - 1 : 0 ];
logic                    almost_full;
logic                    almost_empty;
logic                    empty_sha;


always_ff @ ( posedge clk_i )
  begin 
    if ( !srst_i )
      begin
        wr_adr <= 0;
      end
    else 
      begin         
        if ( wr_req_i )
          begin
            fifo_mem [ wr_adr ] <= data_i;
            wr_adr <= wr_adr + 1; 
          end   
      end
  end  
 
 
always_ff @ ( posedge clk_i )
  begin 
    if ( !srst_i )
      begin
        rd_adr <= 0;
        q_o    <= 0;
      end
    else 
      begin 
        if ( rd_req_i ) 
          begin
            q_o <= fifo_mem [ rd_adr ];
            rd_adr <= rd_adr + 1;    
          end
      end
  end

  
always_ff @ ( posedge clk_i )
  begin
    if ( !srst_i )
      begin
        almost_empty <= 1;
        almost_full  <= 0;
      end
    else 
      begin       
        if      ( rd_adr == wr_adr + 2 ) almost_full  <= 1;
        else if ( rd_adr == wr_adr + 3 ) almost_full  <= 0; 
        if      ( rd_adr == wr_adr - 3 ) almost_empty <= 0;
        else if ( rd_adr == wr_adr - 2 ) almost_empty <= 1;           
      end
  end
  
  
always_ff @ ( posedge clk_i )
  begin
    if ( !srst_i )
      begin
        empty_sha <= 1;
      end
    else 
      begin       
        empty_sha <= ( ( ( rd_adr == wr_adr     ) & ( almost_empty )            ) |     
                       ( ( rd_adr == wr_adr - 1 ) & ( almost_empty ) & rd_req_i ) ) ? 1 : 0;   
      end
  end   
  
  
always_comb 
  begin
  
    if ( SHOWAHEAD ) empty_o = empty_sha;
    else             empty_o = ( ( rd_adr == wr_adr ) & ( almost_empty ) ) ? 1 : 0; 
    
    full_o  = ( ( rd_adr == wr_adr ) & ( almost_full  ) ) ? 1 : 0;    
    
    if      ( rd_adr == wr_adr ) usedw_o = 0;
    else if ( rd_adr <  wr_adr ) usedw_o = wr_adr - rd_adr;     
    else                         usedw_o = FIFO_SIZE - ( rd_adr - wr_adr );     
 end
 
 
endmodule
 