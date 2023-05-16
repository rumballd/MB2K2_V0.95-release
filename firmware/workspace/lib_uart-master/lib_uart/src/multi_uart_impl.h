// Copyright (c) 2014-2016, XMOS Ltd, All rights reserved
#ifndef __MULTI_UART_IMPL_H__
#define __MULTI_UART_IMPL_H__

[[distributable]]
void multi_uart_rx_buffer(server interface multi_uart_rx_if i,
                          unsigned clock_rate_hz,
                          unsigned baud,
                          enum uart_parity_t parity,
                          unsigned bits_per_byte,
                          unsigned stop_bits);

void multi_uart_rx_pins(streaming chanend c,
                        in buffered port:32 p,
                        unsigned num_uarts);

[[distributable]]
void multi_uart_tx_buffer(server interface multi_uart_tx_if i_tx,
                          unsigned clock_rate_hz,
                          unsigned baud,
                          enum uart_parity_t parity,
                          unsigned bits_per_byte,
                          unsigned stop_bits);

void multi_uart_tx_pins(chanend c, out buffered port:8 p, size_t clock_rate);

#define multi_uart_rx(c, i, p, n, clock_rate, baud, parity, bits, stop_bits)    \
  {par { \
      [[distribute]] multi_uart_rx_buffer(i, clock_rate, baud, parity, bits, stop_bits);           \
      multi_uart_rx_pins(c, p, n); \
    } \
  }

#define multi_uart_tx(c, i, p, n, clock_rate, baud, parity, bits, stop_bits)    \
  {par { \
      [[distribute]] multi_uart_tx_buffer(i, clock_rate, baud, parity, bits, stop_bits);           \
      multi_uart_tx_pins(c, p, clock_rate); \
    } \
  }

#pragma select handler
inline void multi_uart_data_ready(streaming chanend c_rx, size_t &index) {
    char x;
    c_rx :> x;
    index = x;
}

#endif // __MULTI_UART_IMPL_H__
