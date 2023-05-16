// Copyright (c) 2014-2016, XMOS Ltd, All rights reserved

#include "uart.h"
#include "xassert.h"
#include <xs1.h>
#include <stdio.h>
#include <print.h>
#include <xscope.h>
#include <gpio.h>
#include <debug_print.h>
#include <xclib.h>

#ifndef UART_RX_DISABLE_DYNAMIC_CONFIG
#define UART_RX_DISABLE_DYNAMIC_CONFIG 0
#endif

enum uart_rx_state {
  WAITING_FOR_INPUT,
  WAITING_FOR_HIGH,
  TESTING_START_BIT,
  INPUTTING_DATA_BIT,
  INPUTTING_PARITY_BIT,
  INPUTTING_STOP_BIT,
};

static inline int parity32(unsigned x, enum uart_parity_t parity)
{
  // To compute even / odd parity the checksum should be initialised
  // to 0 / 1 respectively. The values of the uart_parity_t have been
  // chosen so the parity can be used to initialise the checksum
  // directly.
  assert(UART_PARITY_EVEN == 0);
  assert(UART_PARITY_ODD == 1);
  crc32(x, parity, 1);
  return (x & 1);
}

static inline int add_to_buffer(uint8_t buffer[n], unsigned n,
                                size_t &rdptr, size_t &wrptr,
                                uint8_t data)
{
  int new_wrptr = wrptr + 1;

  if (new_wrptr >= n)
    new_wrptr = 0;

  if (new_wrptr == rdptr) {
    // buffer full
    return 0;
  }

  // Output tracing information of the values entering the buffer
  xscope_char(UART_RX_VALUE, data);

  buffer[wrptr] = data;
  wrptr = new_wrptr;
  return 1;
}

[[combinable]]
void uart_rx(server interface uart_rx_if c,
             server interface uart_config_if ?config,
             const static unsigned n,
             unsigned baud,
             enum uart_parity_t parity,
             unsigned bits_per_byte,
             unsigned stop_bits,
             client input_gpio_if p_rxd)
{
  uint8_t buffer[n];
  unsigned data_bit_count;
  timer tmr;
  enum uart_rx_state state = WAITING_FOR_HIGH;
  int t;
  unsigned bit_time = (XS1_TIMER_HZ / baud);
  int stop_bit_count;
  unsigned data;
  size_t rdptr = 0, wrptr = 0;
  p_rxd.event_when_pins_eq(1);

  assert(!UART_RX_DISABLE_DYNAMIC_CONFIG || isnull(config));
  assert((bits_per_byte > 0) && (bits_per_byte <= 8) && "Invalid number of bits per byte");

  while (1) {
    select {
    // The following cases implement the uart state machine
    case p_rxd.event():
      tmr :> t;
      (void) p_rxd.input();
      switch (state) {
      case WAITING_FOR_HIGH:
        p_rxd.event_when_pins_eq(0);
        state = WAITING_FOR_INPUT;
        break;
      case WAITING_FOR_INPUT:
        t += bit_time/2;
        state = TESTING_START_BIT;
      break;
      }
      break;
    case (state != WAITING_FOR_INPUT && state != WAITING_FOR_HIGH) =>
      tmr when timerafter(t) :> void:
      switch (state) {
      case TESTING_START_BIT:
        // We should now be half way through the start bit
        // Test it is not a glitch
        int level_test = p_rxd.input();
        if (level_test == 0) {
          data_bit_count = 0;
          t += bit_time;
          data = 0;
          state = INPUTTING_DATA_BIT;
        }
        else {
          p_rxd.event_when_pins_eq(1);
          state = WAITING_FOR_HIGH;
        }
        break;
      case INPUTTING_DATA_BIT:
        int bit = p_rxd.input();
        data = data << 1 | bit;
        data_bit_count++;
        t += bit_time;
        if (data_bit_count == bits_per_byte) {
          data = bitrev(data) >> (CHAR_BIT * sizeof(unsigned) - bits_per_byte);
          if (parity != UART_PARITY_NONE) {
            state = INPUTTING_PARITY_BIT;
          } else {
            if (add_to_buffer(buffer, n, rdptr, wrptr, data))
              c.data_ready();
            if (stop_bits != 0) {
              stop_bit_count = stop_bits;
              state = INPUTTING_STOP_BIT;
            }
            else {
              state = WAITING_FOR_INPUT;
              p_rxd.event_when_pins_eq(0);
            }
          }
        }
        break;
      case INPUTTING_PARITY_BIT:
        int bit = p_rxd.input();
        if (bit == parity32(data, parity)) {
          if (add_to_buffer(buffer, n, rdptr, wrptr, data))
            c.data_ready();
          if (stop_bits != 0) {
            stop_bit_count = stop_bits;
            state = INPUTTING_STOP_BIT;
          }
          else {
            p_rxd.event_when_pins_eq(0);
            state = WAITING_FOR_INPUT;
          }
        }
        else {
          p_rxd.event_when_pins_eq(1);
          state = WAITING_FOR_HIGH;
        }
        t += bit_time;
        break;
      case INPUTTING_STOP_BIT:
        int level_test = p_rxd.input();
        if (level_test == 0) {
          p_rxd.event_when_pins_eq(1);
          state = WAITING_FOR_HIGH;
        }
        stop_bit_count--;
        t += bit_time;
        if (stop_bit_count == 0) {
          p_rxd.event_when_pins_eq(0);
          state = WAITING_FOR_INPUT;
        }
        break;
      }
      break;

    case c.read() -> uint8_t data:
      if (rdptr == wrptr)
        break;
      data = buffer[rdptr];
      rdptr++;
      if (rdptr == n)
        rdptr = 0;
      if (rdptr != wrptr)
        c.data_ready();
      break;
    case c.has_data() -> int res:
      res = (rdptr != wrptr);
      break;
#if !UART_RX_DISABLE_DYNAMIC_CONFIG
    // Handle client interaction with the component
    case !isnull(config) => config.set_baud_rate(unsigned baud_rate):
      bit_time = XS1_TIMER_HZ / baud_rate;
      p_rxd.event_when_pins_eq(1);
      state = WAITING_FOR_HIGH;
      break;
    case !isnull(config) => config.set_parity(enum uart_parity_t new_parity):
      parity = new_parity;
      p_rxd.event_when_pins_eq(1);
      state = WAITING_FOR_HIGH;
      break;
    case !isnull(config) => config.set_stop_bits(unsigned new_stop_bits):
      stop_bits = new_stop_bits;
      p_rxd.event_when_pins_eq(1);
      state = WAITING_FOR_HIGH;
      break;
    case !isnull(config) => config.set_bits_per_byte(unsigned bpb):
      assert((bpb > 0) && (bpb <= 8) && "Invalid number of bits per byte");
      bits_per_byte = bpb;
      p_rxd.event_when_pins_eq(1);
      state = WAITING_FOR_HIGH;
      break;
#endif
    }
  }
}

extends client interface uart_rx_if : {
  extern inline uint8_t wait_for_data_and_read(client uart_rx_if i);
}
