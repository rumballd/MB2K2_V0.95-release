// Copyright (c) 2015-2016, XMOS Ltd, All rights reserved
#include <xs1.h>
#include <platform.h>
#include <print.h>
#include <uart.h>
#include <stddef.h>

// Port declarations
in port p_uart_rx = on tile[0] : XS1_PORT_1A;
out port p_uart_tx = on tile[0] : XS1_PORT_1B;

/* This function performs the main "application" that outputs and reads
   some bytes over UART */
void app(streaming chanend c_tx, streaming chanend c_rx)
{
  uint8_t byte;
  printstrln("Test started");
  byte = 0;
  for (size_t i = 0; i < 20; i++) {
      printstr("Echo 10 bytes... ");
      for(size_t j = 0; j < 10; j++) {
        uart_tx_streaming_write_byte(c_tx, byte);
        byte = byte + 1;
      }
      for(size_t j = 0; j < 10; j++) {
        uart_rx_streaming_read_byte(c_rx, byte);
        printhex(byte);
      }
  }
  printstrln(". Done.");
}


#define TICKS_PER_BIT 20

/* "main" function that sets up two uarts and the application */
int main() {
  streaming chan c_rx;
  streaming chan c_tx;
  par {
    on tile[0]: uart_tx_streaming(p_uart_tx, c_tx, TICKS_PER_BIT);
    on tile[0]: uart_rx_streaming(p_uart_rx, c_rx, TICKS_PER_BIT);
    on tile[0]: app(c_tx, c_rx);
  }
  return 0;
}
