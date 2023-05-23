// Copyright (c) 2014-2016, XMOS Ltd, All rights reserved

#include "uart.h"
#include <xs1.h>
#include <stdio.h>
#include <stdlib.h>
#include <print.h>
#include <xscope.h>
#include "xassert.h"
#include "debug_print.h"

#ifndef UART_TX_DISABLE_DYNAMIC_CONFIG
#define UART_TX_DISABLE_DYNAMIC_CONFIG 0
#endif

enum uart_tx_state {
  WAITING_FOR_DATA,
  OUTPUTTING_START_BIT,
  OUTPUTTING_DATA_BIT,
  OUTPUTTING_PARITY_BIT,
  OUTPUTTING_STOP_BIT,
  STOP_BIT_SENT,
};


static inline int parity32(unsigned x, uart_parity_t parity)
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

static inline int buffer_full(int rdptr, int wrptr, int buf_length)
{
  wrptr++;
  if (wrptr == buf_length)
    wrptr = 0;
  return (wrptr == rdptr);
}

static inline void init_transmit(size_t &rdptr, size_t &wrptr,
                                 enum uart_tx_state &state, int &t,
                                 int &clock_sync_required)
{
  if ((state != WAITING_FOR_DATA && state != STOP_BIT_SENT) || rdptr == wrptr){
    // Already busy transmitting a bit
    return;
  }

  if (state == WAITING_FOR_DATA) {
    // Starting to transmit from the idle - ensure the time is valid so that
    // the select case will trigger
    timer tmr;
    tmr :> t;

    // Indicate to the OUTPUTTING_START_BIT state that the time needs to be
    // re-synchronised
    clock_sync_required = 1;
  }

  state = OUTPUTTING_START_BIT;
}

[[combinable]]
void uart_tx_buffered(server interface uart_tx_buffered_if i,
                      server interface uart_config_if ?config,
                      const static unsigned buf_length,
                      unsigned baud,
                      uart_parity_t parity,
                      unsigned bits_per_byte,
                      unsigned stop_bits,
                      client output_gpio_if p_txd)
{
  uint8_t buffer[buf_length];
  int bit_time = XS1_TIMER_HZ / baud;
  enum uart_tx_state state = WAITING_FOR_DATA;
  uint8_t byte;
  timer tmr;
  size_t rdptr = 0, wrptr = 0;
  unsigned bit_count, stop_bit_count;
  int clock_sync_required = 0;
  int parity_val;

  assert(!UART_TX_DISABLE_DYNAMIC_CONFIG || isnull(config));
  assert((bits_per_byte > 0) && (bits_per_byte <= 8) && "Invalid number of bits per byte");

  int t;
  p_txd.output(1);

  // Inform the client that there is space
  i.ready_to_transmit();

  while (1) {
    select {
    case (state != WAITING_FOR_DATA) => tmr when timerafter(t) :> void:
      switch (state) {
      case OUTPUTTING_START_BIT:
        p_txd.output(0);

        if (clock_sync_required) {
          // Re-align clock with the start of frame
          tmr :> t;
          clock_sync_required = 0;
        }
        t += bit_time;
        state = OUTPUTTING_DATA_BIT;

        byte = buffer[rdptr];
        rdptr++;
        if (rdptr == buf_length) {
          rdptr = 0;
        }

        // Trace the outgoing data
        xscope_char(UART_TX_VALUE, byte);

        bit_count = 0;

        // Inform the client that there is space
        i.ready_to_transmit();

        break;
      case OUTPUTTING_DATA_BIT:
        p_txd.output((byte >> bit_count));
        t += bit_time;
        bit_count++;
        if (bit_count == bits_per_byte) {
          if (parity != UART_PARITY_NONE) {
            state = OUTPUTTING_PARITY_BIT;
            parity_val = parity32(byte, parity);
          } else if (stop_bits) {
            stop_bit_count = stop_bits;
            state = OUTPUTTING_STOP_BIT;
          } else {
            state = STOP_BIT_SENT;
          }
        }
        break;
      case OUTPUTTING_PARITY_BIT:
        p_txd.output(parity_val);
        t += bit_time;
        if (stop_bits) {
          stop_bit_count = stop_bits;
          state = OUTPUTTING_STOP_BIT;
        } else {
         state = STOP_BIT_SENT;
        }
        break;
      case OUTPUTTING_STOP_BIT:
        p_txd.output(1);
        t += bit_time;
        stop_bit_count--;
        if (stop_bit_count == 0) {
          state = STOP_BIT_SENT;
          init_transmit(rdptr, wrptr, state, t, clock_sync_required);
        }
        break;
      case STOP_BIT_SENT:
        state = WAITING_FOR_DATA;
        break;
      }
    break;
    // Handle client interaction with the component
    case i.write(uint8_t data) -> int buffer_was_full:
      if (buffer_full(rdptr, wrptr, buf_length)) {
        buffer_was_full = 1;
        return;
      }
      buffer_was_full = 0;
      buffer[wrptr] = data;
      wrptr++;
      if (wrptr == buf_length) {
        wrptr = 0;
      }

      init_transmit(rdptr, wrptr, state, t, clock_sync_required);
      break;

    case i.get_available_buffer_size(void) -> size_t available:
      int size = rdptr - wrptr;
      if (size <= 0)
        size += buf_length - 1;
      available = size;
      break;

#if !UART_TX_DISABLE_DYNAMIC_CONFIG
    case !isnull(config) => config.set_baud_rate(unsigned baud_rate):
      bit_time = XS1_TIMER_HZ / baud_rate;
      state = WAITING_FOR_DATA;
      init_transmit(rdptr, wrptr, state, t, clock_sync_required);
      break;
    case !isnull(config) => config.set_parity(uart_parity_t new_parity):
      parity = new_parity;
      state = WAITING_FOR_DATA;
      init_transmit(rdptr, wrptr, state, t, clock_sync_required);
      break;
    case !isnull(config) => config.set_stop_bits(unsigned new_stop_bits):
      stop_bits = new_stop_bits;
      state = WAITING_FOR_DATA;
      init_transmit(rdptr, wrptr, state, t, clock_sync_required);
      break;
    case !isnull(config) => config.set_bits_per_byte(unsigned bpb):
      assert((bpb > 0) && (bpb <= 8) && "Invalid number of bits per byte");
      bits_per_byte = bpb;
      state = WAITING_FOR_DATA;
      init_transmit(rdptr, wrptr, state, t, clock_sync_required);
      break;
#endif
    }
  }
}
