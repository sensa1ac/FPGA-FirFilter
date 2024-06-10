module button_to_1pulse
(
input clk50, button,
//output button_debounced_pulse //fpga button is active low
output reg button_debounced_pulse 
);

reg [31:0] count = 0;
 always@(posedge clk50)
 begin
		if(!button) begin //must keep button pressed until u get pulse, then let go
			if(count < 50000000) begin
			button_debounced_pulse <= 0;
			count <= count + 1;
			end
			
			else begin
			button_debounced_pulse <= 1;
			count <= 0;
			end
			
		end
		
		else count <= 0;
 end
 
endmodule