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

module tb;

  reg    clk;
  reg    reset_n;
  reg    pwm_in_data_i;
  wire   uart_tx_o;
  reg [10:0] no_of_clks;
  reg [31:0] i;
  reg [31:0] j;

  tt_um_uart_temp_sens
    tuptutw
      (
       .clk           (clk          ),
       .reset_n       (reset_n      ),
       .pwm_in_data_i (pwm_in_data_i),
       .uart_tx_o     (uart_tx_o    )
       );

  // 50 MHz clock frequency
  // Clock period = 20ns
  initial
    begin
      clk = 1'b0;
      forever #10 clk = ~ clk;
    end

  // Initial start of simulation
  initial
    begin
      reset_n = '0;
      no_of_clks = '0;
      i = '0;
      j = '0;
      pwm_in_data_i = '0;
      repeat (5) @(posedge clk);
      reset_n = '1;

      @(posedge clk) pwm_in_data_i = '1;

      repeat (5) @(posedge clk);

      for ( i = 0; i < 1000 ; i = i + 1 )
        begin

          no_of_clks = $random;

          for ( j = 0; j < no_of_clks ; j = j + 1 )
            begin
              pwm_in_data_i = '0;
              @(posedge clk);
            end

          @(posedge clk) pwm_in_data_i = '1;
          repeat (25) @(posedge clk);
          //@(posedge clk) pwm_in_data_i = '0;

        end

      #100000;
      $stop;

    end


endmodule
