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
<img width="768" height="345" alt="pin_out" src="https://github.com/user-attachments/assets/560d601c-1182-4d8e-a83b-27b00efe0733" />

 ## Dependenices
=> This design instantiates one submodule: Uart_Temp

## How to test
<img width="1849" height="977" alt="testbench" src="https://github.com/user-attachments/assets/3bd676e8-3008-45e5-8342-65de0f088b10" />


## External hardware
List external hardware used in your project (e.g. PMOD, LED display, etc), if any
