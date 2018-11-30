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
// PURPOSE : Uart controller 
// 1: Set uart baud rate -- i_div = (i_clk/uart_rate) - 1
// 2: Set uart parity -- i_parity[0]: set parity check. i_parity[1]: parity check enable
// 3: Set stop bits
// 4: Output parity check error signal
// 5: Output baud rate error signal
// 
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
// Instantiations 		: 	uart_tx, uart_rx
// Synthesizable (y/n) 	: 	y
// Other :
// -FHDR------------------------------------------------------------------------
module uart_crtl(
	i_clk 		,
	i_reset_n 	,
	i_parity 	,
	i_stop 		,
	i_div 		,
	i_tx_req 	,
	o_tx_ack 	,
	i_tx_data 	,

	o_rx_int 	,
	i_rx_ack 	,
	o_rx_data 	,
	o_uart_err 	,

	o_uart_txd	,
	i_uart_rxd) ;

//************************************************//
//	Port description
//***********************************************//
input 				i_clk;			//Input clock
input 				i_reset_n;		//Input reset low active
input 		[1:0] 	i_parity; 		//i_parity[0]: 0--Even check, 1--odd check; parity[1]: 1--Enabel parity check, 0--disable parity check
input 		[1:0] 	i_stop; 		//STOP bits setting
input 		[15:0] 	i_div; 			//Uart rate setting: i_div = (clk_in /rate) - 1
input 				i_tx_req;		//Uart send request
output 				o_tx_ack; 		//Uart send ack
input 		[7:0] 	i_tx_data; 		//uart send data

output 				o_rx_int;		//Uart receive interrupt
input 				i_rx_ack; 		//Uart receive ack
output 		[7:0] 	o_rx_data; 		//uart receive data
output 		[1:0]	o_uart_err; 	//o_uart_err[0] : uart baud rate error .  o_uart_err[1] : Parity check error

output 	 			o_uart_txd; 	//uart txd signal
input 				i_uart_rxd; 	////Uart rxd signal

//************************************************//
//	Instantiations
//***********************************************//
uart_tx inst_tx(
	.i_clk 			(i_clk),
	.i_reset_n 		(i_reset_n),
	.i_parity 		(i_parity),
	.i_stop 		(i_stop),
	.i_div 			(i_div),
	.i_tx_req		(i_tx_req),
	.o_tx_ack 		(o_tx_ack),
	.i_tx_data 		(i_tx_data),
	.o_uart_txd		(o_uart_txd)
);

uart_rx inst_rx(
	.i_clk 			(i_clk),
	.i_reset_n 		(i_reset_n),
	.i_parity 		(i_parity),
	.i_div	 		(i_div),
	.o_rx_int 		(o_rx_int),
	.i_rx_ack 		(i_rx_ack),
	.o_rx_data 		(o_rx_data),
	.o_parity_err 	(o_uart_err[1]),
	.o_rate_err		(o_uart_err[0]),
	.i_uart_rxd		(i_uart_rxd)
);

endmodule