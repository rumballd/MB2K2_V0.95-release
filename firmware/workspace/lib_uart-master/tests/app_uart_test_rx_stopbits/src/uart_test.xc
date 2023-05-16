// Copyright (c) 2015-2016, XMOS Ltd, All rights reserved

#include <xs1.h>
#include <platform.h>
#include <stdlib.h>
#include <stdio.h>
#include "debug_print.h"
#include "xassert.h"
#include "uart.h"

#define BITTIME(x) (100000000 / (x))

#define ARRAY_SIZE(a) (sizeof(a) / sizeof(a[0]))

#define CHECK_EVENTS 1
#define CHECK_BUFFERING 1
#define CHECK_RUNTIME_PARAMETER_CHANGE 1
#define CHECK_PARITY_ERRORS 1

port p_rx = on tile[0] : XS1_PORT_1A;
port p_tx = on tile[0] : XS1_PORT_1B;

static void uart_test(client uart_rx_if i_uart_rx,
                      unsigned baud_rate)
{
  debug_printf("TEST CONFIG:{'baud rate':%d}\n",baud_rate);
  debug_printf("Performing rx test.\n");
    p_tx <: 1;
    
    for(int i = 0; i < 4; i++)
        printf("0x%02x\n", i_uart_rx.wait_for_data_and_read());
    
    _Exit(0);
}

#define BUFFER_SIZE 64
int main() {

  interface uart_rx_if i_rx;
  input_gpio_if i_gpio_rx;
  par {
    on tile[0].core[0] : input_gpio_1bit_with_events(i_gpio_rx, p_rx);
    on tile[0].core[0] : uart_rx(i_rx, null, BUFFER_SIZE, BAUD, UART_PARITY_NONE, 8, STOPBITS, i_gpio_rx);
    on tile[0]: uart_test(i_rx, BAUD);
  }

  return 0;
}
