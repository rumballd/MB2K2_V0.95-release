// Copyright (c) 2015-2016, XMOS Ltd, All rights reserved
#include <xs1.h>
#include <platform.h>
#include <stdlib.h>
#include <uart.h>

#include "debug_print.h"

// Ports for TRIANGLE slice & startKIT slice
in buffered port:32 p_uart_rx = XS1_PORT_8B;
port p_uart_clk = XS1_PORT_1L;
port sim_notif = XS1_PORT_1A;

clock clk_uart = XS1_CLKBLK_4;

void test(streaming chanend c_rx, client multi_uart_rx_if i_rx)
{
  debug_printf("Performing multi_uart rx test.\n");

  i_rx.init(c_rx);

  sim_notif <: 1;

  size_t slot;
  uint8_t data;

  i_rx.pause();
  i_rx.set_baud_rate(2, BAUD/2);
  i_rx.restart();
  for(int i = 0; i < 8;)
  {
    select {
      case multi_uart_data_ready(c_rx, slot):
        if (i_rx.read(slot, data) == UART_RX_VALID_DATA)
        {
          debug_printf("0x%x from UART %d\n", data, slot);
          i++;
        }
        else
        {
           debug_printf("Failed to read from slot %d\n", slot);
        }
        break;
    }
  }

  _Exit(0);
}

int main(void)
{
  streaming chan c_rx;

  interface multi_uart_rx_if i_rx;

  configure_clock_src(clk_uart, p_uart_clk);
  configure_in_port(p_uart_rx, clk_uart);

  start_clock(clk_uart);

  par {
    multi_uart_rx(c_rx, i_rx, p_uart_rx, 3, 1843200, BAUD, UART_PARITY_NONE, 8, 1);
    test(c_rx, i_rx);
  }
  return 0;
}
