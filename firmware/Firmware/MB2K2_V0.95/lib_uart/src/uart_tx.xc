// Copyright (c) 2014-2016, XMOS Ltd, All rights reserved

#include "uart.h"
#include <xs1.h>
#include <stdio.h>
#include <stdlib.h>
#include <xscope.h>
#include "xassert.h"

#ifndef UART_TX_DISABLE_DYNAMIC_CONFIG
#define UART_TX_DISABLE_DYNAMIC_CONFIG 0
#endif

static inline int parity32(unsigned x, enum uart_parity_t parity)
{
  // To compute even / odd parity the checksum should be initialised
  // to 0 / 1 respectively. The values of the art_tx_parity have been
  // chosen so the parity can be used to initialise the checksum
  // directly.
  assert(UART_PARITY_EVEN == 0);
  assert(UART_PARITY_ODD == 1);
  crc32(x, parity, 1);
  return (x & 1);
}

[[distributable]]
void uart_tx(server interface uart_tx_if i,
             server interface uart_config_if ?config,
             unsigned baud,
             uart_parity_t parity,
             unsigned bits_per_byte,
             unsigned stop_bits,
             client output_gpio_if p_txd)
{
  int bit_time = XS1_TIMER_HZ / baud;
  timer tmr;

  assert(!UART_TX_DISABLE_DYNAMIC_CONFIG || isnull(config));
  assert((bits_per_byte > 0) && (bits_per_byte <= 8) && "Invalid number of bits per byte");

  p_txd.output(1);
  while (1) {
    select {
    case i.write(uint8_t data):
      // Trace the outgoing data
      xscope_char(UART_TX_VALUE, data);
      int t;
      // Output start bit
      p_txd.output(0);
      tmr :> t;
      t += bit_time;
      unsigned byte = data;
      // Output data bits
      for (int j = 0; j < bits_per_byte; j++) {
        tmr when timerafter(t) :> void;
        p_txd.output(byte & 1);
        byte >>= 1;
        t += bit_time;
      }
      // Output parity
      if (parity != UART_PARITY_NONE) {
        tmr when timerafter(t) :> void;
        p_txd.output(parity32(data, parity));
        t += bit_time;
      }
      // Output stop bits
      tmr when timerafter(t) :> void;
      p_txd.output(1);
      t += bit_time * stop_bits;
      tmr when timerafter(t) :> void;
      break;
#if !UART_TX_DISABLE_DYNAMIC_CONFIG
    case !isnull(config) => config.set_baud_rate(unsigned baud_rate):
      bit_time = XS1_TIMER_HZ / baud_rate;
      break;
    case !isnull(config) => config.set_parity(enum uart_parity_t new_parity):
      parity = new_parity;
      break;
    case !isnull(config) => config.set_stop_bits(unsigned new_stop_bits):
      stop_bits = new_stop_bits;
      break;
    case !isnull(config) => config.set_bits_per_byte(unsigned bpb):
      assert((bpb > 0) && (bpb <= 8) && "Invalid number of bits per byte");
      bits_per_byte = bpb;
      break;
#endif
    }
  }
}
