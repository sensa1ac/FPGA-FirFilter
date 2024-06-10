/* Преобразование из доп кода (для наглядности) в прямой (для вычислений)
10010(=-2) -> 11110(=-2) */

module d2p
#(
  parameter WIDTH = 16
)
(
  input  wire [WIDTH-1:0] x,
  output wire [WIDTH-1:0] y
);
  assign y =x[WIDTH-1]? {x[WIDTH-1], ~(x[WIDTH-2:0]-1) }: x;


  
  
  endmodule