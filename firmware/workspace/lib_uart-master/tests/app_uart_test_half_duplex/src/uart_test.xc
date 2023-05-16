// Copyright (c) 2015-2016, XMOS Ltd, All rights reserved

#include <xs1.h>
#include <platform.h>
#include <stdlib.h>
#include <stdio.h>
#include "debug_print.h"
#include "xassert.h"
#include "uart.h"

#define BUFFER_SIZE 64
port p_uart = on tile[0] : XS1_PORT_1A;

static void uart_test(client uart_rx_if i_uart_rx, 
                      client uart_tx_buffered_if i_uart_tx,
                      client uart_control_if i_control,
                      unsigned baud_rate)
{
  debug_printf("TEST CONFIG:{'baud rate':%d}\n", baud_rate);
  debug_printf("Performing combined test.\n");

  if (i_uart_tx.write(0x7f) != 0) printstrln("Write failed.");
  if (i_uart_tx.write(0x00) != 0) printstrln("Write failed.");
  if (i_uart_tx.write(0x2f) != 0) printstrln("Write failed.");
  if (i_uart_tx.write(0xff) != 0) printstrln("Write failed.");
 
  timer tmr;
  int t;
  tmr :> t;
  tmr when timerafter(t+(1000000/baud_rate)*10000+50000) :> void;
  _Exit(0);
} 

int main() {
  interface uart_rx_if i_rx;
  interface uart_control_if i_control;
  interface uart_tx_buffered_if i_tx;

  par {
    on tile[0] : uart_half_duplex(i_tx, i_rx, i_control, NULL, BUFFER_SIZE, BUFFER_SIZE, BAUD, PARITY, 8, 1, p_uart);
    on tile[0] : uart_test(i_rx, i_tx, i_control, BAUD);
  }

  return 0;
}
