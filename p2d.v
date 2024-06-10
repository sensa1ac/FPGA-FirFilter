/* Преобразование из прямого кода (для наглядности) в дполнительный (для вычислений)
10010(=-2) -> 11110(=-2) */

module p2d
#(
  parameter WIDTH = 16
)
(
  input  wire [WIDTH-1:0] x,
  output wire [WIDTH-1:0] y
);
  
  assign y =x[WIDTH-1]? {x[WIDTH-1],(~x[WIDTH-2:0]) + 1}: x;
  

  
  
  
endmodule