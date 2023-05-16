// Copyright (c) 2015-2016, XMOS Ltd, All rights reserved

#include <xs1.h>
#include <platform.h>
#include <stdlib.h>
#include "debug_print.h"
#include "xassert.h"
#include "uart.h"

#define BITTIME(x) (100000000 / (x))

#define ARRAY_SIZE(a) (sizeof(a) / sizeof(a[0]))

#define CHECK_EVENTS 1
#define CHECK_BUFFERING 1
#define CHECK_RUNTIME_PARAMETER_CHANGE 1
#define CHECK_PARITY_ERRORS 1

static void uart_test(client uart_tx_if i_uart_tx,
                      client uart_config_if i_tx_config,
                      unsigned baud_rate)
{
  debug_printf("TEST CONFIG:{'baud rate':%d}\n",baud_rate);
  debug_printf("Performing tx test.\n");
    i_uart_tx.write(0x19);
    i_uart_tx.write(0x12);
    i_uart_tx.write(0x1A);
    i_uart_tx.write(0x0F);
    _Exit(0);

}

port p_rx = on tile[0] : XS1_PORT_1A;
port p_tx = on tile[0] : XS1_PORT_1B;


#define BUFFER_SIZE 64
int main() {
  uart_tx_if i_tx;
  uart_config_if i_tx_config;
  output_gpio_if i_gpio_tx[1];
  par {

    on tile[0] : output_gpio(i_gpio_tx, 1, p_tx, null);
    on tile[0] : uart_tx(i_tx, i_tx_config, BAUD, PARITY, BPB, 1, i_gpio_tx[0]);
    on tile[0] : {
        uart_test(i_tx, i_tx_config, BAUD);
     }
   }
   return 0;
 }
