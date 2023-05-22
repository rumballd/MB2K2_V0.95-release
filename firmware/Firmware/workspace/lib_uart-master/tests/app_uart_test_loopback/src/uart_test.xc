// Copyright (c) 2015-2017, XMOS Ltd, All rights reserved

#include <xs1.h>
#include <platform.h>
#include <stdlib.h>
#include <stdio.h>
#include "xassert.h"
#include "uart.h"

port p_rx       = on tile[0] : XS1_PORT_1A;
port p_rx_ready = on tile[0] : XS1_PORT_1B;
port p_tx       = on tile[0] : XS1_PORT_1C;

#define BUFFER_SIZE 64
int main() {
  interface uart_tx_buffered_if i_tx;
  interface uart_rx_if i_rx;
  input_gpio_if i_gpio_rx;
  output_gpio_if i_gpio_tx[1];
  par {
    on tile[0] : input_gpio_1bit_with_events(i_gpio_rx, p_rx);
    on tile[0] : output_gpio(i_gpio_tx, 1, p_tx, null);
    on tile[0] : uart_rx(i_rx, null, BUFFER_SIZE, BAUD, UART_PARITY_NONE, 8, 1, i_gpio_rx);
    on tile[0] : uart_tx_buffered(i_tx, null, BUFFER_SIZE, BAUD,
                                  UART_PARITY_NONE, 8, 1, i_gpio_tx[0]);

    on tile[0]: {
      printf("TEST CONFIG:{'baud rate':%d}\n", BAUD);
      printf("Performing rx test.\n");
      p_rx_ready <: 1;

      for (int i = 0; i < 4; i++) {
        unsigned char ch = i_rx.wait_for_data_and_read();
        i_tx.write(ch);
      }
      // Wait for the byte to be sent (data + start + stop)
      delay_ticks(2*10*100000000/BAUD);
      _Exit(0);
    }
  }
  return 0;
}
