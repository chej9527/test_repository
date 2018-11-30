// +FHDR------------------------------------------------------------------------
// Copyright (c) . All rights reserved
// 
// -----------------------------------------------------------------------------
// FILE NAME 		:	uart_crtl.v
// DEPARTMENT 		: 	Hardware Department
// AUTHOR 			:	Alan He
// AUTHOR’S EMAIL 	: 	hecheng@feimarobotics.com
// -----------------------------------------------------------------------------
// RELEASE HISTORY
// VERSION DATE AUTHOR DESCRIPTION
// 1.0 2018-08-12 V1
// -----------------------------------------------------------------------------
// KEYWORDS : None
// -----------------------------------------------------------------------------
// PURPOSE : Uart Recive data modle
// 1: Set uart baud rate -- i_div = (i_clk/uart_rate) - 1
// 2: Set uart parity -- i_parity[0]: set parity check. i_parity[1]: parity check enable
// 3: Output parity check error signal
// 4: Output baud rate error signal
// -----------------------------------------------------------------------------
// PARAMETERS
// 
// 
// -----------------------------------------------------------------------------
// REUSE ISSUES
// Reset Strategy 		: 	i_reset_n signal falling edge reset
// Clock Domains 		: 	i_clk
// Critical Timing 		:
// Test Features		:
// Asynchronous I/F 	: 	i_reset_n
// Scan Methodology 	:
// Instantiations 		: 	N/A
// Synthesizable (y/n) 	: 	y
// Other :
// -FHDR------------------------------------------------------------------------
module uart_rx(
	i_clk,
	i_reset_n,
	i_parity,
	i_div,
	o_rx_int,
	i_rx_ack,
	o_rx_data,
	o_parity_err,
	o_rate_err,
	i_uart_rxd);
//************************************************//
//	Port description
//***********************************************//
input 				i_clk; 			//Input clock
input 				i_reset_n;		//Input reset low active
input 		[1:0] 	i_parity; 		//i_parity[0]: 0--Even check, 1--odd check; parity[1]: 1--Enabel parity check, 0--disable parity check
input 		[15:0] 	i_div; 			//Uart rate setting: i_div = (i_clk /rate) - 1
output 	reg			o_rx_int;		//Uart receive interrupt
input 				i_rx_ack; 		//Uart receive ack
output 	reg	[7:0] 	o_rx_data; 		//uart receive data
output 				o_parity_err; 	//Parity check error signal
output 	reg			o_rate_err; 	//Rate error signal
input 		 		i_uart_rxd; 	//Uart rxd signal

//************************************************//
//	Internal network definition
//***********************************************//
reg 	[1:0] 	rxd_temp;
reg 			rx_en;
reg 	[15:0] 	clk_div;
reg 	[3:0] 	rx_bits_cnt;
reg 			parity_check;
reg 			parity_result;


wire			rx_start;
wire			rx_end;
wire 			data_samp;
wire 			stop_end;
wire 			rx_bit_end;

always @(posedge i_clk or negedge i_reset_n)
begin
	if(!i_reset_n) 
		rxd_temp <= 2'b00;
	else 
		rxd_temp <= {rxd_temp[0],i_uart_rxd};
end

assign rx_start = ~rxd_temp[0] & rxd_temp[1];

always @(posedge i_clk or negedge i_reset_n) 
begin
	if(!i_reset_n) 
		rx_en <= 1'b0;
	else if(rx_start) 
		rx_en <= 1'b1;
	else if(rx_end) 
		rx_en <= 1'b0;
end

always @(posedge i_clk or negedge i_reset_n)
begin
	if(!i_reset_n) 
		clk_div <= 16'd0;
	else if(rx_en) begin
		if(rx_bit_end) 
			clk_div <= 16'd0;
		else 
			clk_div <= clk_div + 16'd1;
	end
	else 
		clk_div <= 16'd0;
end

assign rx_bit_end = (clk_div == i_div);
assign data_samp = (clk_div == i_div >> 1);

always @(posedge i_clk or negedge i_reset_n) 
begin
	if(!i_reset_n) 
		rx_bits_cnt <= 4'd0;
	else if(rx_en) begin
		if(rx_bit_end) 
			rx_bits_cnt <= rx_bits_cnt + 4'd1;
	end
	else 
		rx_bits_cnt <= 4'd0;
end

always @(posedge i_clk)
begin
	if(rx_en) begin
		if(rx_bits_cnt >= 4'd1 && rx_bits_cnt <= 4'd8 && data_samp) 
			o_rx_data <= {i_uart_rxd,o_rx_data[7:1]};
	end
end

always @(posedge i_clk or negedge i_reset_n)
begin
	if(!i_reset_n) 
		parity_check <= 1'b0;
	else if(rx_en) begin
		if(rx_bits_cnt == 4'd0) 
			parity_check <=  i_parity[0];
		else if(rx_bits_cnt >= 4'd1 && rx_bits_cnt <= 4'd8 && data_samp) 
			parity_check <= parity_check ^ i_uart_rxd;
	end
end

always @(posedge i_clk or negedge i_reset_n)
begin
	if(!i_reset_n) 
		parity_result <= 1'b0;
	else if(rx_bits_cnt == 4'd9 && data_samp && parity_check != i_uart_rxd && i_parity[1]) 
		parity_result <= 1'b1;
	else if(i_rx_ack) 
		parity_result <= 1'b0;
end

assign stop_bit_end = (clk_div == ((i_div >> 1) + (i_div >> 2)));

assign rx_end = (!i_parity[1] && rx_bits_cnt == 4'd9 && stop_bit_end) ? 1'b1 :
				(i_parity[1] && rx_bits_cnt == 4'd10 && stop_bit_end) ? 1'b1 : 1'b0;

always @(posedge i_clk or negedge i_reset_n) begin
	if(!i_reset_n) 
		o_rx_int <= 1'b0;
	else if(rx_end) 
		o_rx_int <= 1'b1;
	else if(i_rx_ack) 
		o_rx_int <= 1'b0;
end

assign o_parity_err = parity_result;

always @(posedge i_clk or negedge i_reset_n)
begin
	if(!i_reset_n) 
		o_rate_err <= 1'b0;
	else if(rx_end && !i_uart_rxd) 
		o_rate_err <= 1'b1;
	else if(i_rx_ack) 
		o_rate_err <= 1'b0;
end

endmodule