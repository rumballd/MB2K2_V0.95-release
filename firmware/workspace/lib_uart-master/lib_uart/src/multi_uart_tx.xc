// Copyright (c) 2015-2016, XMOS Ltd, All rights reserved
#include <uart.h>
#include <print.h>
#include <xassert.h>
#include <xs1.h>
#include <xclib.h>

#define MUART_TX_MAX_BAUD (115200)

#ifndef MUART_TX_CHAN_COUNT
#define MUART_TX_CHAN_COUNT (8)
#endif

#ifndef MUART_TX_BUF_SIZE
#define MUART_TX_BUF_SIZE (16)
#endif

/**
 * Structure to hold configuration information and data for the
 * UART TX channels.
 */
typedef struct multi_uart_tx_info_t {
    /** Configuration constants */
    unsigned bits_per_byte; /**< length of the UART char */
    unsigned uart_word_len; /**< number of bits in UART word e.g. Start bit + 8 bit data + parity + 2 stop bits is 12 bit UART word */
    unsigned clocks_per_bit; /**< define baud rate in relation to max baud rate */

    /** Mode definition */
    unsigned num_stop_bits;
    uart_parity_t parity;

    /** Buffering variables */
    size_t wr_ptr; /**< Write pointer */
    size_t rd_ptr; /**< Read pointer */
    uint32_t buf[MUART_TX_BUF_SIZE]; /**< Buffer array */

} multi_uart_tx_info_t;


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

unsigned int uart_tx_assemble_word(multi_uart_tx_info_t &info,
                                   unsigned int uart_char )
{
  unsigned int full_word = 0;
  int pos = 0;
  /* format data into the word (msb -> lsb) STOP|PARITY|DATA|START */

  pos += 1;

  /* uart word - mask, reverse char and put into full word */
  unsigned mask = (1 << info.bits_per_byte) - 1;
  uart_char = uart_char & mask;
  full_word |=  uart_char << pos;
  pos += info.bits_per_byte;

  /* parity */
  if (info.parity != UART_PARITY_NONE)
  {
    int parity = parity32(uart_char, info.parity);
    full_word |= (parity << pos);
    pos += 1;
  }

  unsigned stop_bits = (1 << info.num_stop_bits) - 1;

  full_word |= stop_bits << pos;
  pos += info.num_stop_bits;

  /* do calc XOR'd output */
  full_word = ((full_word << 1) | 0x1) ^ full_word;

  return full_word;
}


[[distributable]]
void multi_uart_tx_buffer(server interface multi_uart_tx_if i_tx,
                          unsigned clock_rate_hz,
                          unsigned baud,
                          enum uart_parity_t parity,
                          unsigned bits_per_byte,
                          unsigned stop_bits)
{
  multi_uart_tx_info_t tx_slot_info[MUART_TX_CHAN_COUNT];
  unsafe chanend c;

  if (clock_rate_hz >= MUART_TX_MAX_BAUD) {
    // Update to the effective tick rate of the transmitter
    clock_rate_hz = MUART_TX_MAX_BAUD;
  }

  /* MUART_TX_BUF_SIZE must be a power of 2 */
  assert((MUART_TX_BUF_SIZE >> clz(bitrev(MUART_TX_BUF_SIZE))) == 1);
  assert((bits_per_byte > 0) && (bits_per_byte <= 8) && "Invalid number of bits per byte");

  unsigned initial_clocks_per_bit = clock_rate_hz / baud;

  for (size_t i = 0; i < MUART_TX_CHAN_COUNT; i++) {
    tx_slot_info[i].clocks_per_bit = initial_clocks_per_bit;
    tx_slot_info[i].num_stop_bits = stop_bits;
    tx_slot_info[i].parity = parity;
    tx_slot_info[i].bits_per_byte = bits_per_byte;
    tx_slot_info[i].uart_word_len = 1 + bits_per_byte + stop_bits;
    if (tx_slot_info[i].parity != UART_PARITY_NONE) {
      tx_slot_info[i].uart_word_len += 1;
    }
    tx_slot_info[i].rd_ptr = 0;
    tx_slot_info[i].wr_ptr = 0;
  }

  while (1) {
    select {
      case i_tx.init(chanend c0):
        unsafe {
          c = (unsafe chanend) c0;
          c <: (multi_uart_tx_info_t * unsafe) tx_slot_info;
        }
        break;
      case i_tx.is_slot_free(size_t index) -> int result:
        unsigned w = (tx_slot_info[index].wr_ptr + 1) % MUART_TX_BUF_SIZE;
        result = (w != tx_slot_info[index].rd_ptr);
        break;
      case i_tx.write(size_t index, uint8_t byte):
        unsigned w = (tx_slot_info[index].wr_ptr + 1) % MUART_TX_BUF_SIZE;
        if (w == tx_slot_info[index].rd_ptr)
          break;
        unsigned uart_word = uart_tx_assemble_word(tx_slot_info[index], byte);
        tx_slot_info[index].buf[tx_slot_info[index].wr_ptr] = uart_word;
        tx_slot_info[index].wr_ptr = w;
        break;
      case i_tx.pause():
        unsafe {
          c <: 0;
        }
        break;
      case i_tx.restart():
        unsafe {
          c <: 0;
        }
        break;
      case i_tx.set_baud_rate(size_t index, unsigned baud_rate):
        unsafe {
          tx_slot_info[index].clocks_per_bit = clock_rate_hz / baud_rate;
        }
        break;
      case i_tx.set_parity(size_t index, enum uart_parity_t parity):
        unsafe {
          tx_slot_info[index].parity = parity;
        }
        break;
      case i_tx.set_stop_bits(size_t index, unsigned stop_bits):
        unsafe {
          tx_slot_info[index].num_stop_bits = stop_bits;
        }
        break;
      case i_tx.set_bits_per_byte(size_t index, unsigned bits_per_byte):
        assert((bits_per_byte > 0) && (bits_per_byte <= 8) && "Invalid number of bits per byte");
        unsafe {
          tx_slot_info[index].bits_per_byte = bits_per_byte;
        }
        break;
    }
  }
}

#pragma unsafe arrays
void multi_uart_tx_pins(chanend c,
                        out buffered port:8 p,
                        unsigned clock_rate_hz)
{
  unsigned port_val;
  unsigned ts;
  const unsigned idle_val = 0xFFFFFFFF;

  unsigned current_word[MUART_TX_CHAN_COUNT];
  unsigned current_word_pos[MUART_TX_CHAN_COUNT];
  unsigned tick_count[MUART_TX_CHAN_COUNT];
  unsigned clocks_per_bit[MUART_TX_CHAN_COUNT];

  volatile multi_uart_tx_info_t * unsafe tx_slot_info;
  unsigned ts_inc = 1;

  if (clock_rate_hz >= MUART_TX_MAX_BAUD) {
    // Update to the effective tick rate of the transmitter
    ts_inc = clock_rate_hz / MUART_TX_MAX_BAUD;
  }
  else {
    ts_inc = 1;
  }


  /* wait until release (post config) */
  unsafe {
    c :> tx_slot_info;
  }

  /* initialise data structures */
  for (int i = 0; i < MUART_TX_CHAN_COUNT; i++)
  {
    current_word[i] = 0;
    current_word_pos[i] = 0; // disable channel
    tick_count[i] = 0;
    unsafe {
      clocks_per_bit[i] = tx_slot_info[i].clocks_per_bit;
    }
  }

  port_val = idle_val;
  /* initialise port */
  p <: port_val @ ts;
  // Wait for 20 port ticks for the while(1) to be set up. TODO: This could be
  // optimised and the number of ticks could be calculated from the BAUD rate.
  ts += 20 + ts_inc;

  while (1)
  {
    /* process the next bit on the ports */
#pragma xta endpoint "tx_bit_ep0"
    p @ ts <: port_val;
    ts += ts_inc;
    /* calculate next port_val */
#pragma loop unroll
    for (int i = 0; i < MUART_TX_CHAN_COUNT; i++)
    {
#pragma xta label "update_loop"
      tick_count[i]--;
      /* active and counter tells us we need to send a bit */
      if (tick_count[i] == 0 && current_word_pos[i])
      {
        port_val ^= (current_word[i] & 1) << i;
        current_word[i] >>= 1;
        current_word_pos[i] -= 1;
        tick_count[i] = clocks_per_bit[i];
      }

      unsafe {
        if ((current_word_pos[i] == 0) &&
            (tx_slot_info[i].rd_ptr != tx_slot_info[i].wr_ptr)) // rd == wr => empty
        {
          int rd_ptr = tx_slot_info[i].rd_ptr;
          current_word[i] = tx_slot_info[i].buf[rd_ptr];
          rd_ptr = (rd_ptr + 1) % MUART_TX_BUF_SIZE;
          tx_slot_info[i].rd_ptr = rd_ptr;

          current_word_pos[i] = tx_slot_info[i].uart_word_len;
          tick_count[i] = clocks_per_bit[i];
        }
      }
    }

    /* check for request to pause for reconfigure */
    unsafe {
      select
      {
#pragma xta endpoint "tx_bit_ep1"
      case c :> int _: // anything here will pause the TX thread

      /* set port to IDLE */
      port_val = idle_val;
      p <: port_val @ ts;

      /* allow otherside to hold us while we wait */
      c :> int _;

      /* initialise data structures */
      for (int i = 0; i < MUART_TX_CHAN_COUNT; i++)
      {
        current_word[i] = 0;
        current_word_pos[i] = 0; // disable channel
        tick_count[i] = 0;
        tx_slot_info[i].wr_ptr = 0;
        tx_slot_info[i].rd_ptr = 0;
        clocks_per_bit[i] = tx_slot_info[i].clocks_per_bit;
      }

      /* initialise port */
      p <: port_val @ ts;
      ts += 20;
      break;
    default:
      break;
      }
    }
  }
}
