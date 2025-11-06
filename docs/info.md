 ## Project_Tittle
 => uart_temperature sensor 

## Authors 
1.hiral Patadiya
2.Riya soni
3.Divayang Rana

## Short Discription
=> This project implements a convert a pwm digital serial signal to a paralle value and trasmits it over uart(Tx) at the configured baud rate.

## How it works
The module samples a 1-Bit pwm input and converts the serial pwm waveform into a parallel represntation. once the sample window completes , the uart transmitter serializes the parallel value and send it through the Tx pin using the configured baud rate. The top-level follows TinyTapeout I/O conventions(clk, rst_n, ena, ui_in, uo_out). UART(Tx) is available on uo_out[0].

## pinout summary
+--------------+------------+-----------------+------------------------------------+
| Pin          | Direction  | Name / Function | Description                        |
+--------------+------------+-----------------+------------------------------------+
| ui_in[0]     | Input      | pwm_in          | PWM input from temperature sensor  |
| ui_out[0]    | Output     | UART_TX         | UART transmit output               |
| ui_in[7:1]   | Input      | -               | Unused                             |
| ui_out[7:1]  | Output     | -               | Unused                             |
| uio_in[7:0]  | InOut      | -               | Not Used                           |
| uio_out[7:0] | Output     | -               | Not Used                           |
| uio_oe[7:0]  | Output     | -               | Not Used                           |
+--------------+------------+-----------------+------------------------------------+


 ## Dependenices
=> This design instantiates one submodule: Uart_Temp


## How to test

## External hardware
List external hardware used in your project (e.g. PMOD, LED display, etc), if any
