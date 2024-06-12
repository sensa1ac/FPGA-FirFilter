/*

SW0==0 => ВЫВОДИТСЯ СИГНАЛ ДО КИХ
SW0==1 => ВЫВОДИТ СИГНАЛ ПОСЛЕ КИХ
*/


module Top (

///
//output reg barker11,

input[3:0] sw0,sw1,sw2,sw3,
///


	input clk  , 
	key0, // reset
	key2, // 
	key3,  // увеличение частоты (-10)
	key1, // увеличение амплитуды: 1 нажатие - в 2 раза; 2 нажатия - в 3 раза; 3 нажатия - в 1 раз
	
	inout SDIN,
	output SCLK,USB_clk,BCLK,
	output reg DAC_LR_CLK,
	output DAC_DATA,
	output [2:0] ACK_LEDR
	
);
///
parameter FREQ_STEP = 10; // шаг изменения частоты в увеличение и уменьшение по нажатию key3 и key2
reg [17:0] step = 10;

wire pwm_out;

wire reset; assign reset = key0;
///





reg [3:0] counter; //selecting register address and its corresponding data
reg counting_state,ignition,read_enable; 	
reg [15:0] MUX_input;
reg [17:0] read_counter; //256 В том коде это step

///
reg [17:0] read_counter_1; // для второго синуса
reg [17:0] read_counter_2; // для 3 синуса
reg [17:0] read_counter_3; // для 4 синуса


reg [17:0] read_counter_10;
///

///reg [3:0] ROM_output_mux_counter;
reg [4:0] ROM_output_mux_counter;
reg [4:0] DAC_LR_CLK_counter;
wire [15:0]ROM_out;  // первый синус
wire shim_clk;
wire shim_out; 
wire finish_flag;
wire increse, decrese; //Для манипуляции частотой

reg  [1:0] key1_reg; initial key1_reg = 1; // 1 - в1 		2 - в2		3 - в3
wire w_sw0; assign w_sw0 = (sw0[0]==1) ? 1 : 0; 
////wire w_sw1; assign w_sw1 = (sw0[1]==1) ? 1 : 0;


///
wire [17:0] ROM_out2, // вспом

		ROM_out_10,

		ROM_out_1, // второй синус
		ROM_out_2, // третий синус
		ROM_out_3, // 4ый синус
		signalFromKih, // 
		signalToKih;
assign DAC_DATA = ROM_out2[15-ROM_output_mux_counter];
			
///синус 1
//assign ROM_out2 = ROM_out*2; 
///cинус 2
//assign ROM_out2 = ROM_out_1; 
///синус 3
//assign ROM_out2 = ROM_out_2; 
///cинус 4
//assign ROM_out2 = ROM_out_3*2; 


// Сигнал на вход КИХ-фильтра (подали 4 гармоники)		
assign signalToKih = 2*ROM_out + ROM_out_1  + ROM_out_2   + 2*ROM_out_3 ; 
// Подаём дельта-функцию через полсекунды длительностью	0.02 мкс , чтобы посмотреть Импульсную характеристику 	
///assign signalToKih = delta;
// Подаём синус с увеличивающейся частотой
//assign signalToKih = ROM_out_10;

/// Вывод сигнала с аудиовыхода: входе/выходе КИХ-фильтра (подали 4 гармоники или дельа-функция)
assign ROM_out2 = /* (firDelay<7) ? */ ((w_sw0==0) ? (signalToKih) : (signalFromKih)) /* : 0 */ ;
/// Вывод сигнала с аудиовыхода для поданного на вход КИХ синуса с увеличивающейся частотой
//assign ROM_out2 = (kolvoPrtkov==11) ? 0 : ((w_sw0==0) ? (signalToKih) : (signalFromKih)) ;


///*
FirFilter fir1 
(
	.clk(clk),
	.x(signalToKih),
	.y(signalFromKih)
);
//*/


/* firdop #( .TAPS(43) ) fir1(
  .clk(clk),
  .coefs( {
-16'd188,
16'd46,
16'd379,
16'd877,
16'd1333,
16'd1467,
16'd1066,
16'd148,
-16'd957,
-16'd1686,
-16'd1474,
-16'd41,
16'd2408,
16'd5191,
16'd7389,
16'd8223,
16'd7389,
16'd5191,
16'd2408,
-16'd41,
-16'd1474,
-16'd1686,
-16'd957,
16'd148,
16'd1066,
16'd1467,
16'd1333,
16'd877,
16'd379,
16'd46,
-16'd188


    } ),
  .in(signalToKih),
  .out(signalFromKih)
);
*/


// Генерация дельа-функции через 0.5 сек на 0.02 мкс
/*
reg [15:0] delta; initial delta=0;
reg [24:0] td; initial td =0;
always @ (posedge clk)
begin
	if (td==25000001)
	begin
		delta <= 0;
		td <= 0;
	end
	else
	if (td==25000000)
		delta <= 16'b1111111111111111;
		
	td <= td + 1;
end
*/















//управление фазой посредством SW0 (переключение=смена фазы)
//assign ROM_out2 = (ph==1) ? ROM_out1 : -ROM_out1; 


//Постоянный синусоидальный Баркер11-код
///assign ROM_out1 = (barker11==1) ? (ROM_out*key1_reg) : -(ROM_out*key1_reg); // изменение фазы на 180* по фронту и спаду 11битного кода баркера + увеличение громкости умножителем + cдвиг фазы на 180 по фронту key0

// 1секунда (около 4 периодов) синусоидального Баркер11-кода, 
// [1.5, 2 или 4] секунды - сигнала нет  (что выбрано ниже)
///assign ROM_out1 = (vnol==0)	? ( (barker11==1) ? (ROM_out*key1_reg) : -(ROM_out*key1_reg) ) : 0;


// ДЛЯ ВЫБОРА ВРЕМЕНИ, КОГДА СИГНАЛ В НУЛЕ: РАСКОММЕНТИРОВАТЬ НУЖНОЕ, ЗАКОМЕНТИРОВАТЬ НЕНУЖНОЕ
// vnol==1 по прошествии 1 секунды, далее по прошествии [] ==0 
/* reg [27:0]sek;  initial sek =0;
reg vnol; initial vnol = 0;
always @ (posedge clk)
begin */
	
	//  СИГНАЛ В НУЛЕ 2 периода от 1кГц
	/* 
	if (sek==150000)
	begin
		vnol <= 0;
		sek <= 0;
	end 
	*/
	
	//  СИГНАЛ В НУЛЕ  100 периода от 1кГц
 	/*
	if (sek==5200000)
	begin
		vnol <= 0;
		sek <= 0;
	end 
	*/
	
	
	 /* 
	/// СИГНАЛ В НУЛЕ  10 периода от 1кГц
	if (sek==700000)
	begin
		vnol <= 0;
		sek <= 0;
	end
	 */
	
/* 	else
	  // 1 периода прошло
	begin
		if (sek==50000)
			vnol <= 1;		
		sek <= sek + 1;
	end */
	
		
//end

/////////////////////




// УПРАВЛЕНИЕ ГРОМКОСТЬЮ
// настройка key1_reg с тремя состояниями для увеличения громкости
always@ (posedge ~key1)
begin

	if (key1_reg==1)
		key1_reg <= 2;
	else
	if (key1_reg==2)
		key1_reg <= 3;
	else 
	if (key1_reg==3)
		key1_reg <= 1;
	
end










////////////////////////////////////////////////////////////////////////////////
//assign test=test1; //test
//============================================
//Instantiation section
I2C_Protocol I2C(
	
	.clk(clk),
	.reset(reset),
	.ignition(ignition),
	.MUX_input(MUX_input),
	.ACK(ACK_LEDR),
	.SDIN(SDIN),
	.finish_flag(finish_flag),
	.SCLK(SCLK)
);


USB_Clock_PLL	USB_Clock_PLL_inst (
	.inclk0 ( clk ),
	.c0 ( USB_clk ),
	.c1 ( BCLK )
	);
	
	
	
	
	
	
	
	
	
	
	// синус увеличивающейся частоты
	sine16by256_ROM	sine16by256_inst10 (
	.address ( read_counter_10 ),
	.clock ( clk ),
	.rden ( read_enable ),
	.q ( ROM_out_10 )
	);
	
	
	
	
	
	
	
	
	
	
// 1
	sine16by256_ROM	sine16by256_inst1 (
	.address ( read_counter ),
	.clock ( clk),//8k ),
	.rden ( read_enable ),
	.q ( ROM_out )
	);
// 2	
	sine16by256_ROM	sine16by256_inst2 (
	.address ( read_counter_1 ),
	.clock ( clk),//8k ),
	.rden ( read_enable ),
	.q ( ROM_out_1 )
	);
//3
	sine16by256_ROM	sine16by256_inst3 (
	.address ( read_counter_2 ),
	.clock ( clk),//8k ),
	.rden ( read_enable ),
	.q ( ROM_out_2 )
	);
//4
	 sine16by256_ROM	sine16by256_inst4 (
	.address ( read_counter_3 ),
	.clock ( clk),//8k ),
	.rden ( read_enable ),
	.q ( ROM_out_3 )
	); 


	/*
	Five_Centimeters_Per_Second_ROM	Five_Centimeters_Per_Second_ROM_inst (
	.address ( read_counter ),
	.clock ( clk ),
	.rden ( read_enable ),
	.q ( ROM_out )
	);
	*/
	
/*	
PLL_SHIM PLL_SHIM_inst (
	.inclk0 (clk),
	.c0 (shim_clk)
);*/
//манипулируем частотой

//Если держишь  key2 или key3 одну секунду, то частота увеличивается на +-FREQ_STEP соответственно
button_to_1pulse inst1
(
.clk50(clk),
.button(key2),
.button_debounced_pulse(increse)
);

button_to_1pulse inst2
(
.clk50(clk),
.button(key3),
.button_debounced_pulse(decrese)
);

/*
shim sh
(
.clk(shim_clk),
.in0(tau0),
.in1(tau1),
.out(shim_out),
.test(test1) //test
);*/

///
/*
PWM pwm1 
(
	.clk(clk4Hz),
	.sw0(sw0),sw1(sw1),sw2(sw2),sw3(sw3),
	.out(pwm_out)
);*/
///

//============================================

//УПРАВЛЕНИЕ ФАЗОЙ (при нажатии key0 сдвиг на 180)
/* reg ph; initial ph = 1;
always@(posedge clk)
	if (sw0[0]==1)
		ph <= 0;
	else 
		ph <= 1; */


//УПРАВЛЕНИЕ ДЛИТЕЛЬНОСТЬЮ
/*
reg [25:0] T; initial cnt1=0;
reg en_t; initial en_t=0;
always@(posedge clk)
begin
	
	if ( (T+1)*read_counter > 50000000 && (T-1)*read_counter < 50000000  )
		en_t<=1;
	else
		T<=T+1;
		
if (en_t==1)
begin
	if (pwm_out==1)
		if (ROM_out1<0) 
			ph1<=ph1*(-1); // если был в минусе- стал в плюсе
		else
			
		
		
end				
			
	


end
*/




//УПРАВЛЕНИЕ ЧАСТОТОЙ  

reg [26:0] polsek; initial polsek=0;
reg [3:0] kolvoPrtkov; initial kolvoPrtkov=0; // 11 промежутков по секунду: увеличивается частота на 39 Гц (step+10)
reg [2:0] firDelay;
always@(posedge clk)
begin

	if (polsek==50000000) 	
		begin	
		step  <= step + FREQ_STEP;
		polsek <= 0;
		if (kolvoPrtkov<11)
			kolvoPrtkov <= kolvoPrtkov + 1;
		if (firDelay<7)
			firDelay <= firDelay + 1;
		else
			firDelay <= 0;
		end	
	else
		polsek <= polsek + 1;
	
//else if (decrese) 	step  <= step - FREQ_STEP;
end


always @(posedge DAC_LR_CLK)
	begin
	if(read_enable) 
		begin
			read_counter <= read_counter + 100;
			read_counter_1 <= read_counter_1 + 200;
			read_counter_2 <= read_counter_2 + 400;
			read_counter_3 <= read_counter_3 + 500;
			
			read_counter_10 <= read_counter_10 + step;
			
			//if (read_counter == 214198 ) read_counter <= 0;
			//if (read_counter_1 == 214198 ) read_counter_1 <= 0;
		end
	end
//============================================
// ROM output mux
always @(posedge BCLK) 
	begin
	if(read_enable)
		begin
		
		
			ROM_output_mux_counter <= ROM_output_mux_counter + 1;
		
		
		if (DAC_LR_CLK_counter == 31) DAC_LR_CLK <= 1;
		else DAC_LR_CLK <= 0;
		end
	end
always @(posedge BCLK)
	begin
	if(read_enable)
		begin
		DAC_LR_CLK_counter <= DAC_LR_CLK_counter + 1;
		end
	end
//============================================
// generate 6 configuration pulses 
always @(posedge clk)
	begin
	if(!reset) 
		begin
		counting_state <= 0;
		read_enable <= 0;
		end
	else
		begin
		case(counting_state)
		0:
			begin
			ignition <= 1;
			read_enable <= 0;
			///if(counter == 8) counting_state <= 1; //was 8
			
			///
			if(counter == 9) counting_state <= 1; // выполняет (1-counter) действий
			///
			
			end
		1:
			begin
			read_enable <= 1;
			ignition <= 0;
			
			end
		endcase
		end
	end
//============================================
// this counter is used to switch between registers
always @(posedge SCLK)
	begin
		case(counter) //MUX_input[15:9] register address, MUX_input[8:0] register data
		1: MUX_input <= 16'h1201; // activate interface
		
		
		
		//1: MUX_input <= 16'h0470; // left headphone out =1110000
		2: MUX_input <= (16'b0000010001111000) ;///+ vol_val);
		
		
		3: MUX_input <= 16'h0C00; // power down control
		
		
		
		4: MUX_input <= 16'h0812; // analog audio path control 	выход с ЦАП
		///3:MUX_input <= 16'b0000100000100111;							выход с MicIn
		
		
		5: MUX_input <= 16'h0A00; // digital audio path control
		6: MUX_input <= 16'h102F; // sampling control
		7: MUX_input <= 16'h0E23; // digital audio interface format
		
		
		
		///8: MUX_input <= 16'h0670; // right headphone out       =1110000
		//	7'b010111 = -74Дб  звука нет
		8: MUX_input <= (16'b0000011001111000 );///+ vol_val); было 1100000
 		
		

		
		//9: begin MUX_input <= (16'b000001000111100); ///MUX_input <= (16'b0000010001111100); //+ vol_val);	///

			//end
			
		endcase		
	
		
		
	end
always @(posedge finish_flag)
		counter <= counter + 1; 

	

	
	
	
	
	
	
// формируем частоту clk_8000Hz
reg clk8k; 
reg [23:0]count_b; initial count_b=0;
always@ (posedge clk)
begin
	
	if (count_b==3125) // Хочу сделать 4 периода синуса на бит => т.к. count_b==6250000 это 4ГЦ, а надо (для 1000 Гц синуса) 250, то делим	6250000 на 62.5 = 100000			//12500000) если 125000000 то 500мс на бит, а при 650000- нужные 250мс на бит (см фото). Интересно почему так
	begin
		clk8k <= ~clk8k;
		count_b <= 0;
	end
	else
		count_b <= count_b + 1;

end
	
	


endmodule 