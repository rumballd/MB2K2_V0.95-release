// Copyright (c) 2014-2016, XMOS Ltd, All rights reserved
#include <xs1.h>
#include <platform.h>
#include <print.h>
#include <uart.h>
#include <stddef.h>

// Port declarations
port p_uart_rx = on tile[0] : XS1_PORT_1A;
port p_uart_tx = on tile[0] : XS1_PORT_1B;

#define BAUD_RATE 115200
#define RX_BUFFER_SIZE 64

/* This function performs the main "application" that outputs and reads
   some bytes over UART */
void app(client uart_tx_if uart_tx, client uart_rx_if uart_rx)
{
  uint8_t byte;
  printstrln("Test started");
  byte = 0;
  for (size_t i = 0; i < 20; i++) {
      printstr("Echo 10 bytes... ");
      for(size_t j = 0; j < 10; j++) {
          uart_tx.write(byte);
          byte = byte + 1;
      }
      for(size_t j = 0; j < 10; j++) {
          printhex(uart_rx.wait_for_data_and_read());
      }
  }
  printstrln(". Done.");
}

void test() { while (1);}

/* "main" function that sets up two uarts and the application */
int main() {
  interface uart_rx_if i_rx;
  interface uart_tx_if i_tx;
  input_gpio_if i_gpio_rx;
  output_gpio_if i_gpio_tx[1];
  par {
    on tile[0]: test();
    on tile[0]: output_gpio(i_gpio_tx, 1, p_uart_tx, null);
    on tile[0]: uart_tx(i_tx, null,
                        BAUD_RATE, UART_PARITY_NONE, 8, 1,
                        i_gpio_tx[0]);
    on tile[0].core[0] : input_gpio_1bit_with_events(i_gpio_rx, p_uart_rx);
    on tile[0].core[0] : uart_rx(i_rx, null, RX_BUFFER_SIZE,
                                 BAUD_RATE, UART_PARITY_NONE, 8, 1,
                                 i_gpio_rx);
    on tile[0]: app(i_tx, i_rx);
  }
  return 0;
}
