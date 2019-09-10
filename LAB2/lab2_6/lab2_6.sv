module lab2_6 (
   input  bit_array_i,
   output bit_sum_o
);

logic [$clog2(bit_array_i)-1:0] sum = 0;

always_comb begin
  sum = 0;  
  foreach(bit_array_i[i]) 
    sum += bit_array_i[i];
end

assign bit_sum_o = sum;

endmodule