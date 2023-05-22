// Copyright (c) 2014-2016, XMOS Ltd, All rights reserved

#include <xs1.h>
#include <uart.h>

void uart_tx_fast_init(out port p, const clock clkblk){
    //set to clocked port, with initial value 1 (idle for UART)
    configure_out_port_no_ready(p, clkblk, 1);
}

void uart_tx_streaming_write_byte(streaming chanend c, uint8_t byte)
{
  c <: byte;
}

void uart_tx_streaming(out port p, streaming chanend c, int clocks) {
    int t;
    unsigned char b;
    while (1) {
        c :> b;
        p <: 0 @ t; //send start bit and timestamp (grab port timer value)
        t += clocks;
#pragma loop unroll(8)
        for(int i = 0; i < 8; i++) {
            p @ t <: >> b; //timed output with post right shift
            t += clocks;
        }
        p @ t <: 1; //send stop bit
        t += clocks;
        p @ t <: 1; //wait until end of stop bit
    }
}
