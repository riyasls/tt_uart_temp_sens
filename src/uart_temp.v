//-------------------------------------------------------------------------------
// @   Copyright (c) 2025, System Level Solutions (India) Pvt. Ltd.       @
// @                     All rights reserved.                             @
//
//-------------------------------------------------------------------------------
//-F I L E D E T A I L S---------------------------------------------------------
// Description  : This module is used to count the low period of the PWM digital
//                serial signal. Then that value will be transmitted via the
//                UART tx pin using the 115200 baud rate. Here we have used the
//                50MHz clock cycle.
//
//-------------------------------------------------------------------------------

`timescale 1ns/100ps

module uart_temp
  (
   input wire clk,
   input wire reset_n,
   input wire pwm_in_data_i,

   output reg uart_tx_o

   );

  // no_of_clock_count width
  localparam  COUNTER_WIDTH = 16;

  // Set localparam CLKS_PER_BIT as follows:
  // CLKS_PER_BIT = (Frequency of clk)/(Frequency of UART)
  // Example: 25 MHz Clock, 115200 baud UART
  // (25000000)/(115200) = 217
  localparam  BAUD_RATE        = 115200; // bits / sec

  // No of clock cycles based on frequency
  localparam  NO_OF_CLK_CYCLES = 50_000_000;

  // Input bit rate of the UART line.
  localparam  CLKS_PER_BIT     = NO_OF_CLK_CYCLES/BAUD_RATE;

  // The ASCII codes for CRLF (Carriage Return and Line Feed)
  // are 13 for Carriage Return (\(CR\), \r) and 10 for Line Feed (\(LF\), \n)
  localparam  CRLF_BYTE_WITH_START_STOP_BITS = {1'b1, 8'h0A, 1'b0, 1'b1, 8'h0D, 1'b0};

  // 16 bit crlf + 32 bit data + 12 start / stop bit for all bytes
  localparam  TOTAL_NO_BITS = 16 + ( COUNTER_WIDTH * 2 ) + ( ( COUNTER_WIDTH/2 ) + 4 );

  // Data width for the bit count
  localparam  BIT_COUNT_WIDTH = $clog2 ( TOTAL_NO_BITS );

  reg [ ( ( ( COUNTER_WIDTH * 2 ) + 8 ) - 1 ) :0]  store_no_of_clock_count_ascii;
  reg [ ( BIT_COUNT_WIDTH - 1 ) :0]                bit_count;
  reg [ ( COUNTER_WIDTH - 1 ) :0]                  no_of_clock_count;
  reg [ ( COUNTER_WIDTH - 1 ) :0]                  store_no_of_clock_count;
  reg [ ( TOTAL_NO_BITS - 1 ) :0]                  uart_tx_data;
  reg [ 8:0]                                       mp_counter;
  reg                                              prepare_tx_data_pl;
  reg                                              prepare_tx_data_pl_f1;
  reg                                              prepare_tx_data_pl_f2;
  reg                                              uart_tx_en;
  reg                                              pwm_in_data_f1;
  reg                                              capture_signal_data;
  reg                                              data_captured_pl;
  reg                                              uart_data_transmission;
  wire                                             pwm_in_data_ne;
  wire                                             uart_bit_transmitted_pl;
  wire                                             pwm_in_data_pe;

  // Simple flop
  always @ ( posedge clk or negedge reset_n )
    begin
      if ( ~ reset_n )
        begin
          pwm_in_data_f1 <= 1'b0;
        end
      else
        begin
          pwm_in_data_f1 <= pwm_in_data_i;
        end
    end

  // Positive edge
  assign pwm_in_data_pe = pwm_in_data_i & ( ~ pwm_in_data_f1 );

  // Negative edge
  assign pwm_in_data_ne = ( ~ pwm_in_data_i ) & pwm_in_data_f1;

  // Whenever negative edge detected it this signal will start
  // to capture the data
  always @ ( posedge clk or negedge reset_n )
    begin
      if ( ~ reset_n )
        begin
          capture_signal_data <= 1'b0;
        end
      else if ( uart_tx_en | ( pwm_in_data_i & capture_signal_data) )
        begin
          capture_signal_data <= 1'b0;
        end
      else if ( pwm_in_data_ne )
        begin
          capture_signal_data <= 1'b1;
        end
    end

  // Whenever positive edge detected it will generate one pulse
  always @ ( posedge clk or negedge reset_n )
    begin
      if ( ~ reset_n )
        begin
          data_captured_pl <= 1'b0;
        end
      else
        begin
          data_captured_pl <= ( pwm_in_data_pe & capture_signal_data );
        end
    end

  // Count the number of clk cycle between two pulses
  always @ ( posedge clk or negedge reset_n )
    begin
      if ( ~ reset_n )
        begin
          no_of_clock_count <= 'd0;
        end
      else if ( data_captured_pl | uart_tx_en )
        begin
          no_of_clock_count <= 'd0;
        end
      else if ( no_of_clock_count == 16'hFFFF )
        begin
          no_of_clock_count <= no_of_clock_count;
        end
      else if ( ( ( ~ pwm_in_data_f1 ) & capture_signal_data ) )
        begin
          no_of_clock_count <= no_of_clock_count + 'd1;
        end
    end

  // Store the no_of_clock_count value
  always @ ( posedge clk or negedge reset_n )
    begin
      if ( ~ reset_n )
        begin
          store_no_of_clock_count <= 'd0;
        end
      else if ( data_captured_pl )
        begin
          store_no_of_clock_count <= no_of_clock_count;
        end
      else
        begin
          store_no_of_clock_count <= store_no_of_clock_count;
        end
    end

  // Simple flop
  always @ ( posedge clk or negedge reset_n )
    begin
      if ( ~ reset_n )
        begin
          prepare_tx_data_pl <= 1'b0;
        end
      else
        begin
          prepare_tx_data_pl <= data_captured_pl;
        end
    end


  // Simple flop
  always @ ( posedge clk or negedge reset_n )
    begin
      if ( ~ reset_n )
        begin
          prepare_tx_data_pl_f1 <= 1'b0;
          prepare_tx_data_pl_f2 <= 1'b0;
        end
      else
        begin
          prepare_tx_data_pl_f1 <= prepare_tx_data_pl;
          prepare_tx_data_pl_f2 <= prepare_tx_data_pl_f1;
        end
    end


  // UART Transmission Enable
  always @ ( posedge clk or negedge reset_n )
    begin
      if ( ~ reset_n )
        begin
          uart_tx_en <= 1'b0;
        end
      else if ( ( bit_count == ( TOTAL_NO_BITS - 'd1 ) ) & uart_bit_transmitted_pl )
        begin
          uart_tx_en <= 1'b0;
        end
      else if ( prepare_tx_data_pl )
        begin
          uart_tx_en <= 1'b1;
        end
    end


  // Multipurpose counter
  always @ ( posedge clk or negedge reset_n )
    begin
      if ( ~reset_n )
        begin
          mp_counter <= 9'd0;
        end
      else if ( mp_counter == ( CLKS_PER_BIT - 9'd1 ) )
        begin
          mp_counter <= 9'd0;
        end
      else if ( uart_data_transmission )
        begin
          mp_counter <= mp_counter + 9'd1;
        end
      else
        begin
          mp_counter <= 9'd0;
        end
    end


  // UART data transmission start
  always @ ( posedge clk or negedge reset_n )
    begin
      if ( ~reset_n )
        begin
          uart_data_transmission <= 1'b0;
        end
      else if ( ( bit_count == ( TOTAL_NO_BITS - 'd1 ) ) & uart_bit_transmitted_pl )
        begin
          uart_data_transmission <= 1'b0;
        end
      else if ( prepare_tx_data_pl_f2 )
        begin
          uart_data_transmission <= 1'b1;
        end
    end


  // Bit is transmitted on the UART pin
  assign uart_bit_transmitted_pl = ( mp_counter == ( CLKS_PER_BIT - 'd1 ) );

  // Prepare the TX data
  always @ ( posedge clk or negedge reset_n )
    begin
      if ( ~reset_n )
        begin
          uart_tx_data  <= 'd0;
          uart_tx_o     <= 1'b1;
        end
      else if ( prepare_tx_data_pl_f1 )
        begin
          //   CRLF with Start stop bit      ASCII data with Start stop bit
          uart_tx_data  <= ( { CRLF_BYTE_WITH_START_STOP_BITS,  store_no_of_clock_count_ascii } );
        end
      else if ( uart_tx_en & ( bit_count != ( TOTAL_NO_BITS - 'd1 ) ) & ( prepare_tx_data_pl_f2 | uart_bit_transmitted_pl ) )
        begin
          uart_tx_data  <= ( { 1'b0, uart_tx_data[ ( TOTAL_NO_BITS - 1 ) : 1] } );
          uart_tx_o     <= uart_tx_data[0];
        end
      else if ( ~ uart_tx_en )
        begin
          uart_tx_o     <= 1'b1;
        end
    end

  // ASCII Value generation
  // Then Swap the value with the LSB ASCII value to MSB ASCII value
  // Due to UART print.
  // Also Added the Start and stop bit for all the bytes
  always @(posedge clk or negedge reset_n)
    begin
      if ( ~reset_n )
        begin
          store_no_of_clock_count_ascii <= 40'b0;
        end
      else if ( prepare_tx_data_pl )
        begin
          store_no_of_clock_count_ascii[39:30]  <= (store_no_of_clock_count[ 3: 0] < 8'd10) ? ( { 1'b1, 8'h30 + store_no_of_clock_count[ 3: 0], 1'b0} ) : ({ 1'b1, 8'h41 + ( store_no_of_clock_count[ 3: 0] - 8'd10 ), 1'b0} );
          store_no_of_clock_count_ascii[29:20]  <= (store_no_of_clock_count[ 7: 4] < 8'd10) ? ( { 1'b1, 8'h30 + store_no_of_clock_count[ 7: 4], 1'b0} ) : ({ 1'b1, 8'h41 + ( store_no_of_clock_count[ 7: 4] - 8'd10 ), 1'b0} );
          store_no_of_clock_count_ascii[19:10]  <= (store_no_of_clock_count[11: 8] < 8'd10) ? ( { 1'b1, 8'h30 + store_no_of_clock_count[11: 8], 1'b0} ) : ({ 1'b1, 8'h41 + ( store_no_of_clock_count[11: 8] - 8'd10 ), 1'b0} );
          store_no_of_clock_count_ascii[ 9: 0]  <= (store_no_of_clock_count[15:12] < 8'd10) ? ( { 1'b1, 8'h30 + store_no_of_clock_count[15:12], 1'b0} ) : ({ 1'b1, 8'h41 + ( store_no_of_clock_count[15:12] - 8'd10 ), 1'b0} );
        end
    end

  // Bit counter
  always @ ( posedge clk or negedge reset_n )
    begin
      if ( ~reset_n )
        begin
          bit_count <= 7'd0;
        end
      else if ( ( bit_count == ( TOTAL_NO_BITS - 'd1 ) ) & uart_bit_transmitted_pl )
        begin
          bit_count <= 7'd0;
        end
      else if ( uart_bit_transmitted_pl )
        begin
          bit_count <= bit_count + 7'd1;
        end
    end

endmodule
