//-----------------------------------------------------------------------------
// @   Copyright (c) 2025, System Level Solutions (India) Pvt. Ltd.       @
// @                     All rights reserved.                             @
//
//-----------------------------------------------------------------------------
//-F I L E D E T A I L S-------------------------------------------------------
// Description  : This module is used to convert the PWM digital serial signal
//                in the parallel output and then transmit that value via the
//                UART tx pin using the 115200 baud rate.
//
//-----------------------------------------------------------------------------

`timescale 1ns/100ps

module uart_temp
  (
   input wire clk,
   input wire reset_n,
   input wire pwm_in_data_i,

   output reg uart_tx_o

   );

  // Unit delay for simulation purpose only.
  localparam           = 1;

  // no_of_clock_count width
  localparam  COUNTER_WIDTH = 32;

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
  localparam  CRLF_BYTE = 16'h0D0A;

  // 1 start bit + 32 bit data + 16 bit crlf + 1 stop bit
  localparam  TOTAL_NO_BITS = 1 + 16 + COUNTER_WIDTH + 1;

  // State localparams
  localparam  IDLE      = 'h1;
  localparam  COUNT     = 'h2;
  localparam  CAPTURE   = 'h4;

  reg [ ( COUNTER_WIDTH - 1 ) :0] no_of_clock_count;
  reg [ ( COUNTER_WIDTH - 1 ) :0] store_no_of_clock_count;
  reg [ ( TOTAL_NO_BITS - 1 ) :0] uart_tx_data;
  reg [ 8:0]                      mp_counter;
  reg [ 5:0]                      bit_count;
  reg                             prepare_tx_data_pl;
  reg                             prepare_tx_data_pl_f1;
  reg                             uart_tx_en;
  reg                             pwm_in_data_f1;
  reg                             capture_signal_data;
  reg                             data_captured_pl;
  wire                            pwm_in_data_ne;
  wire                            uart_bit_transmitted_pl;
  wire                            pwm_in_data_pe;



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
        end
      else
        begin
          prepare_tx_data_pl_f1 <= prepare_tx_data_pl;
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
      else if ( uart_tx_en )
        begin
          mp_counter <= mp_counter + 9'd1;
        end
      else
        begin
          mp_counter <= 9'd0;
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
      else if ( prepare_tx_data_pl )
        begin
                                // Stop bit   CRLF             Data            Start bit
          uart_tx_data  <= ( {  1'b1,   CRLF_BYTE,  store_no_of_clock_count,   1'b0 } );
        end
      else if ( uart_tx_en & ( bit_count != ( TOTAL_NO_BITS - 'd1 ) ) & ( prepare_tx_data_pl_f1 | uart_bit_transmitted_pl ) )
        begin
          uart_tx_data  <= ( { 1'b0, uart_tx_data[ ( TOTAL_NO_BITS - 1 ) : 1] } );
          uart_tx_o     <= uart_tx_data[0];
        end
      else if ( ~ uart_tx_en )
        begin
          uart_tx_o     <= 1'b1;
        end
    end

  // Bit counter
  always @ ( posedge clk or negedge reset_n )
    begin
      if ( ~reset_n )
        begin
          bit_count <= 'd0;
        end
      else if ( ( bit_count == ( TOTAL_NO_BITS - 'd1 ) ) & uart_bit_transmitted_pl )
        begin
          bit_count <= 'd0;
        end
      else if ( uart_bit_transmitted_pl )
        begin
          bit_count <= bit_count + 'd1;
        end
    end

endmodule
