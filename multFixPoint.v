/*
Умножитель чисел с фиксированной точкой, поданных на вход в доп.коде
Переводятся в прямой код. Перемножаются. Возвращаются в доп.коде

Возвращает прямой код (см тестбенч ниже)
для первого b: 0001111101000000 (=15,625)
для второго b: 1111101100000000 (=-2,5)
*/

module 	multFixPoint  #(
	parameter Q = 14, // дробная часть
	parameter N = 16 // всего бит 
	)
	(
	 input			[N-1:0]	mul1, 
	 input			[N:0]	temp_mul2,
	 output			[N-1:0]	result
	 );
	 
	 //////////// преобр коэфов из прямого 17-битного в доп 16-битный 
	 wire [N-1:0] mul2;	 
	 assign mul2 = (temp_mul2[N] == 1'b0) ? (temp_mul2[N-1:0]) : (~(temp_mul2[N-1:0])+1'b1);
	 ////////////
	 	 
	reg [2*N-1:0]	r_result;											
	reg [N-1:0]		RetVal;
	wire [N-1:0] a,b;
	
	 assign a = mul1; // d2p d2p1  	(.x(mul1), .y(a)); 
	/* assign b = mul2; // */d2p d2p2  	(.x(mul2), .y(b));
	 /* assign result = RetVal; //  */p2d p2d1 	(.x(RetVal), .y(result));
	
	always @(a, b)	
	begin						
		 r_result = a[N-2:0] * b[N-2:0];	 
		 RetVal[N-1] = a[N-1] ^ b[N-1];	 // ИЛИ последн бита для определения знака
		 RetVal[N-2:0] = r_result[N-2+Q:Q];	//присваение целой части
    	end
	 

endmodule



/*
module mult_tb;
	reg [15:0] a,b;
	wire [15:0] res;
	mult m1(.mul1(a), .mul2(b), .result(res));
initial begin
	a = 16'b0000010100000000; //2,5
	b = 16'b0000110010000000; //6,25 
	#10;
	a = 16'b0000010100000000; //2,5
	b = 16'b1111111000000000; //-0,999 
	#10;
end
endmodule
*/
