 ## Project_Tittle
 => Uart_Temperature sensor 

## Authors 
1.hiral Patadiya
2.Riya soni
3.Divayang Rana

## Short Discription
=> This project implements a convert a pwm digital serial signal to a paralle value and trasmits it over uart(Tx) at the configured baud rate.

## How it works
The module samples a 1-Bit pwm input and converts the serial pwm waveform into a parallel represntation. once the sample window completes , the uart transmitter serializes the parallel value and send it through the Tx pin using the configured baud rate. The top-level follows TinyTapeout I/O conventions(clk, rst_n, ena, ui_in, uo_out). UART(Tx) is available on uo_out[0].

## pinout summary
<img width="719" height="346" alt="pin_digaram" src="https://github.com/user-attachments/assets/718b2a88-1ff3-4f23-bbe4-f9f9757ed5a6" />


 ## Dependenices
=> This design instantiates one submodule: Uart_Temp

## How to test
<img width="1838" height="977" alt="testbench" src="https://github.com/user-attachments/assets/911a49fd-5079-4230-b323-6e3544f49f81" />


## External hardware
List external hardware used in your project (e.g. PMOD, LED display, etc), if any
