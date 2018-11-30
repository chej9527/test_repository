// +FHDR------------------------------------------------------------------------
// Copyright (c) . All rights reserved
// 
// -----------------------------------------------------------------------------
// FILE NAME 		:	uart_tx.v
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
// PURPOSE : uart Send data modle
// 1: Set uart baud rate -- i_div = (i_clk/uart_rate) - 1
// 2: Set uart parity -- i_parity[0]: set parity check. i_parity[1]: parity check enable
// 3: Set stop bits
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
module uart_tx(
	i_clk,
	i_reset_n,
	i_parity,
	i_stop,
	i_div,
	i_tx_req,
	o_tx_ack,
	i_tx_data,
	o_uart_txd);
//************************************************//
//	Port description
//***********************************************//
input 				i_clk; 			//Input clock
input 				i_reset_n; 		//Input reset low active
input 		[1:0] 	i_parity; 		//i_parity[0]: 0--Even check, 1--odd check; parity[1]: 1--Enabel parity check, 0--disable parity check
input 		[1:0] 	i_stop; 		//STOP bits setting
input 		[15:0] 	i_div; 			//Uart rate setting: i_div = (i_clk /rate) - 1
input 				i_tx_req;		//Uart send request
output 				o_tx_ack; 		//Uart send ack
input 		[7:0] 	i_tx_data; 		//uart send data
output 	reg 		o_uart_txd; 	//uart txd signal

//************************************************//
//	Internal network definition
//***********************************************//

reg 	[15:0]  	clk_div;
reg 	[3:0] 		send_bits_cnt;
reg 				parity_buf;
wire				bit_end;


always @(posedge i_clk or negedge i_reset_n) 
begin
	if(!i_reset_n) 
		clk_div <= 16'd0;
	else if(i_tx_req) begin
		if(bit_end) 
			clk_div <= 16'd0;
		else 
			clk_div <= clk_div + 16'd1;
	end
	else 
		clk_div <= 16'd0;
end

assign bit_end = (clk_div == i_div);

always @(posedge i_clk or negedge i_reset_n)
begin
	if(!i_reset_n) 
		send_bits_cnt <= 4'd0;
	else if(i_tx_req) begin
		if(bit_end) 
			send_bits_cnt <= send_bits_cnt + 4'd1;
	end
	else 
		send_bits_cnt <= 4'd0;
end

//always @(i_tx_req  or send_bits_cnt or i_reset_n)
always @(posedge i_clk or negedge i_reset_n)
begin
	if(!i_reset_n) 
		o_uart_txd <= 1'b1;
	if(!i_tx_req) 
		o_uart_txd <= 1'b1;
	else begin
		case(send_bits_cnt)
			4'd0 : o_uart_txd <= 4'd0;
			4'd1 : o_uart_txd <= i_tx_data[0];
			4'd2 : o_uart_txd <= i_tx_data[1];
			4'd3 : o_uart_txd <= i_tx_data[2];
			4'd4 : o_uart_txd <= i_tx_data[3];
			4'd5 : o_uart_txd <= i_tx_data[4];
			4'd6 : o_uart_txd <= i_tx_data[5];
			4'd7 : o_uart_txd <= i_tx_data[6];
			4'd8 : o_uart_txd <= i_tx_data[7];
			4'd9 : begin
				if(i_parity[1]) 
					o_uart_txd <= parity_buf;
				else 
					o_uart_txd <= 1'b1;
			end
			4'd10 : o_uart_txd = 1'b1;
			4'd11 : o_uart_txd = 1'b1;
			4'd12 : o_uart_txd = 1'b1;
			4'd13 : o_uart_txd = 1'b1;
			default : ;
		endcase
	end
end

always @(posedge i_clk or negedge i_reset_n)
begin
	if(!i_reset_n) 
		parity_buf <= 1'b0;
	else if(send_bits_cnt == 4'd0) 
		parity_buf <= i_parity[0];
	else if(send_bits_cnt >= 4'd1 && send_bits_cnt <= 4'd8) begin
		if(bit_end) 
			parity_buf <= parity_buf ^ o_uart_txd;
	end
end

assign o_tx_ack = (!i_parity[1] && (i_stop == 2'd0) && (send_bits_cnt == 4'd9) && bit_end) ? 1'b1 : 
				(!i_parity[1] && (i_stop == 2'd1) && (send_bits_cnt == 4'd10) && bit_end) ? 1'b1 :
				(!i_parity[1] && (i_stop == 2'd2) && (send_bits_cnt == 4'd11) && bit_end) ? 1'b1 :
				(!i_parity[1] && (i_stop == 2'd3) && (send_bits_cnt == 4'd12) && bit_end) ? 1'b1 :
				(i_parity[1] && (i_stop == 2'd0) && (send_bits_cnt == 4'd10) && bit_end) ? 1'b1 :
				(i_parity[1] && (i_stop == 2'd1) && (send_bits_cnt == 4'd11) && bit_end) ? 1'b1 :
				(i_parity[1] && (i_stop == 2'd2) && (send_bits_cnt == 4'd12) && bit_end) ? 1'b1 :
				(i_parity[1] && (i_stop == 2'd3) && (send_bits_cnt == 4'd13) && bit_end) ? 1'b1 : 1'b0;

endmodule