/* запросы на чтение и запись могут приходить одновременно
   запросы на чтение и на запись всегда валидны
   usedw_o = 0 когда очередь пуста или полна
   wr_req_i приходит только когда очередь не полна
   rd_req_i приходит только когда очередь не пуста

   режим showahead это когда верхнее слово fifo всегда “видно” на выходе q,
   сигналом readrq вы просто подтверждаете что вы его прочитали, а не
   запрашиваете
   
*/

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
  output bit                      empty_o,
  output bit                      full_o      
);

localparam               FIFO_SIZE = 2 ** AWIDTH;

logic [ AWIDTH - 1 : 0 ] wr_adr;
logic [ AWIDTH - 1 : 0 ] rd_adr;
logic                    read_possible;
logic                    write_possible;
logic [ DWIDTH - 1 : 0 ] fifo_mem [ FIFO_SIZE - 1 : 0 ];

assign                   read_possible  = rd_req_i & !empty_o;
assign                   write_possible = wr_req_i & !full_o; 

//ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo 

always_ff @ ( posedge clk_i )
  begin // WRITE PROCESS
    if ( !srst_i )
      begin
        wr_adr   <= 0;
        fifo_mem <= '{default:'0};
      end
    else 
      begin 
        if ( write_possible )
          begin
            fifo_mem [ wr_adr ] <= data_i;
            wr_adr <= wr_adr + 1; 
          end   
      end
  end  
 
 
always_ff @ ( posedge clk_i )
  begin // READ PROCESS
    if ( !srst_i )
      begin
        rd_adr <= 0;
        q_o    <= 'x;
      end
    else 
      begin 
        if ( SHOWAHEAD | read_possible ) 
          begin
            q_o <= fifo_mem [ rd_adr ];
            if ( read_possible ) 
              rd_adr <= rd_adr + 1;    
          end
      end
     //$display ( " \n FIFO CONTENT : %p \n", fifo_mem );
  end
 
 
always_comb 
  begin
    usedw_o = 0;
    empty_o = 0;
    full_o  = 0; 
    if      ( rd_adr <  wr_adr     ) usedw_o = wr_adr - rd_adr;
    else if ( rd_adr == wr_adr     ) empty_o = 1;
    else if ( rd_adr == wr_adr + 1 ) full_o  = 1;
    else                             usedw_o = FIFO_SIZE - ( rd_adr - wr_adr );     
  end
    
endmodule
  
  
//ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo 
  
  
  
  
  
  
  