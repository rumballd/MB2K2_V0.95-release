// Copyright (c) 2015-2017, XMOS Ltd, All rights reserved

#include <xs1.h>
#include <platform.h>
#include <stdlib.h>
#include "debug_print.h"
#include "xassert.h"
#include "uart.h"

#define BUFFER_SIZE 64

static void uart_test(client uart_tx_buffered_if i_uart_tx,
                      client uart_config_if i_tx_config,
                      unsigned baud_rate)
{
  debug_printf("TEST CONFIG:{'baud rate':%d}\n",baud_rate);
  debug_printf("Performing buffered tx test.\n");

  for (int i = 0; i < 128; i++) {
    select {
      case i_uart_tx.ready_to_transmit():
        i_uart_tx.write(i);
        break;
    }
  }

  // Wait for the data to have been transmitted
  while(1) {
    if (i_uart_tx.get_available_buffer_size() == (BUFFER_SIZE-1)) {
      break;
    }
    delay_microseconds(1);
  }

  // Wait until the last byte has been transmitted
  timer tmr;
  int t;
  tmr :> t;
  tmr when timerafter(t+(1000000/baud_rate)*10000+50000) :> void;

  _Exit(0);
}

port p_rx = on tile[0] : XS1_PORT_1A;
port p_tx = on tile[0] : XS1_PORT_1B;

int main() {
  interface uart_tx_buffered_if i_tx;
  uart_config_if i_tx_config;
  output_gpio_if i_gpio_tx[1];
  par {

    on tile[0] : output_gpio(i_gpio_tx, 1, p_tx, null);
    on tile[0] : uart_tx_buffered(i_tx, i_tx_config, BUFFER_SIZE, BAUD,
                                  UART_PARITY_NONE, 8, 1, i_gpio_tx[0]);
    on tile[0] : uart_test(i_tx, i_tx_config, BAUD);
   }
   return 0;
 }
