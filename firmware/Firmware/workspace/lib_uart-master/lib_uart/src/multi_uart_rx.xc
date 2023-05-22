// Copyright (c) 2015-2016, XMOS Ltd, All rights reserved
#include <uart.h>
#include <xclib.h>
#include <xs1.h>
#include <xassert.h>

#ifndef MUART_RX_CHAN_COUNT
#define MUART_RX_CHAN_COUNT (8)
#endif

#define MULTI_UART_GO 0xFE

/**
 * Structure to hold configuration information and data for the UART channel RX side -
 * this should only be interacted with via the API and not accessed directly.
 */
typedef struct multi_uart_rx_info_t
{
    int bits_per_byte; /**< length of the UART character */
    int uart_word_len; /**< number of bits in UART word e.g. Start bit + 8 bit data + parity + 2 stop bits is a 12 bit UART word */
    int clocks_per_bit; /**< define baud rate in relation to max baud rate */
    int invert_output; /**< define if output is inverted (set to 1) */
    int use_sample; /**< sample in bit stream to use */

    int num_stop_bits;
    uart_parity_t parity;
} multi_uart_rx_info_t;


extern inline void multi_uart_data_ready(streaming chanend c_rx, size_t &index);

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


static
enum multi_uart_read_result_t
multi_uart_rx_validate_word(size_t index,
                            unsigned &data,
                            multi_uart_rx_info_t &info)
{

    switch (info.num_stop_bits) {
    case 1:
      if ((data & 0x1) != 0x1)
        return UART_RX_INVALID_DATA;
      data >>= 1;
      break;
    case 2:
      if ((data & 0x3) != 0x3)
        return UART_RX_INVALID_DATA;
      data >>= 2;
      break;
    }

    switch (info.parity)
    {
    case UART_PARITY_ODD:
    case UART_PARITY_EVEN:
      unsigned parity = data & 1;
      data >>= 1;
      data = (bitrev(data) >> (32 - info.bits_per_byte));
      if (parity != parity32(data, info.parity))
        return UART_RX_INVALID_DATA;
      break;
    case UART_PARITY_NONE:
      data = (bitrev(data) >> (32 - info.bits_per_byte));
      break;
    }

    return UART_RX_VALID_DATA;
}

static void calc_word_len(multi_uart_rx_info_t &info)
{
  info.uart_word_len = info.bits_per_byte + info.num_stop_bits;
  if (info.parity != UART_PARITY_NONE)
       info.uart_word_len += 1;
}

static unsafe void initialize_slot_info(unsigned clock_rate_hz,
                                        unsigned baud,
                                        enum uart_parity_t parity,
                                        unsigned bits_per_byte,
                                        unsigned stop_bits,
                                        multi_uart_rx_info_t * unsafe rx_slot_info)
{
  for (int i = 0; i < MUART_RX_CHAN_COUNT; i++) {
    rx_slot_info[i].clocks_per_bit = clock_rate_hz / baud;
    rx_slot_info[i].use_sample = rx_slot_info[i].clocks_per_bit / 2;
    rx_slot_info[i].parity = parity;
    rx_slot_info[i].num_stop_bits = stop_bits;
    rx_slot_info[i].bits_per_byte = bits_per_byte;
    calc_word_len(rx_slot_info[i]);
  }
}


[[distributable]]
void multi_uart_rx_buffer(server interface multi_uart_rx_if i,
                          unsigned clock_rate_hz,
                          unsigned baud,
                          enum uart_parity_t parity,
                          unsigned bits_per_byte,
                          unsigned stop_bits)
{
  unsigned * unsafe rx_slots;
  multi_uart_rx_info_t * unsafe rx_slot_info;
  unsafe streaming chanend c;
  while (1) {
    select {
    case i.init(streaming chanend c0):
      unsafe {
        c = c0;
        c :> rx_slots;
        c :> rx_slot_info;
        initialize_slot_info(clock_rate_hz,
                             baud, parity,
                             bits_per_byte,
                             stop_bits,
                             rx_slot_info);
        c <: 0;
      }
      break;
    case i.read(size_t index, uint8_t &data) -> enum multi_uart_read_result_t res:
      unsafe {
        unsigned x = rx_slots[index];
        res = multi_uart_rx_validate_word(index, x, rx_slot_info[index]);
        data = x;
      }
      break;
    case i.pause():
      unsafe {
        c <: 0;
      }
      break;
    case i.restart():
      unsafe {
        c <: 0;
      }
      break;
    case i.set_baud_rate(size_t index, unsigned baud_rate):
      unsafe {
        rx_slot_info[index].clocks_per_bit = clock_rate_hz / baud_rate;
        rx_slot_info[index].use_sample = rx_slot_info[index].clocks_per_bit/2;
      }
      break;
    case i.set_parity(size_t index, enum uart_parity_t parity):
      unsafe {
        rx_slot_info[index].parity = parity;
        calc_word_len(rx_slot_info[index]);
      }
      break;
    case i.set_stop_bits(size_t index, unsigned stop_bits):
      unsafe {
       rx_slot_info[index].num_stop_bits = stop_bits;
       calc_word_len(rx_slot_info[index]);
      }
      break;
    case i.set_bits_per_byte(size_t index, unsigned bpb):
      unsafe {
        rx_slot_info[index].bits_per_byte = bpb;
        calc_word_len(rx_slot_info[index]);
      }
      break;
    }
  }
}

typedef enum e_uart_rx_chan_state
{
    idle = 0x0,
    store_idle,
    data_bits = 0x1,
} e_uart_rx_chan_state;

extern "C" {
  void uart_rx_loop_8(in buffered port:32 pUart, e_uart_rx_chan_state state[],
                      int tick_count[], int bit_count[], int uart_word[],
                      streaming chanend cUART, unsigned rx_char_slots[],
                      unsigned fourBitConfig[],
                      multi_uart_rx_info_t rx_slot_info[],
                      unsigned startBitLookup[]);
}

void multi_uart_rx_pins(streaming chanend c,
                        in buffered port:32 p,
                        unsigned num_uarts)
{
  e_uart_rx_chan_state state[MUART_RX_CHAN_COUNT];

  int tickcount[MUART_RX_CHAN_COUNT];
  int bit_count[MUART_RX_CHAN_COUNT];
  int uart_word[MUART_RX_CHAN_COUNT];

  unsigned fourBitLookup0[16];
  unsigned fourBitLookup1[16];
  unsigned fourBitConfig[MUART_RX_CHAN_COUNT];

  unsigned startBitLookupEnabled[16];
  unsigned startBitLookupDisabled[16];
  unsigned startBitConfig[MUART_RX_CHAN_COUNT];

  multi_uart_rx_info_t rx_slot_info[MUART_RX_CHAN_COUNT];

  unsigned rx_slots[MUART_RX_CHAN_COUNT];

  /*
   * Four bit look up table that takes the CRC32 with poly 0xf of the masked off 32 bit word
   * from an 8 bit port and translates it into the 4 desired bits - huzzah!
   * bit 4-7 indicates whether there could be a start bit and how many are swallowed
   */
  fourBitLookup0[15] = 0x00;
  fourBitLookup0[7]  = 0x31;
  fourBitLookup0[13] = 0x02;
  fourBitLookup0[5]  = 0x23;
  fourBitLookup0[0]  = 0x04;
  fourBitLookup0[8]  = 0x05;
  fourBitLookup0[2]  = 0x06;
  fourBitLookup0[10] = 0x17;
  fourBitLookup0[11] = 0x08;
  fourBitLookup0[3]  = 0x09;
  fourBitLookup0[9]  = 0x0a;
  fourBitLookup0[1]  = 0x0b;
  fourBitLookup0[4]  = 0x0c;
  fourBitLookup0[12] = 0x0d;
  fourBitLookup0[6]  = 0x0e;
  fourBitLookup0[14] = 0x0f;

  fourBitLookup1[15] = 0x00;
  fourBitLookup1[7]  = 0x01;
  fourBitLookup1[13] = 0x02;
  fourBitLookup1[5]  = 0x03;
  fourBitLookup1[0]  = 0x04;
  fourBitLookup1[8]  = 0x05;
  fourBitLookup1[2]  = 0x06;
  fourBitLookup1[10] = 0x07;
  fourBitLookup1[11] = 0x18;
  fourBitLookup1[3]  = 0x09;
  fourBitLookup1[9]  = 0x0a;
  fourBitLookup1[1]  = 0x0b;
  fourBitLookup1[4]  = 0x2c;
  fourBitLookup1[12] = 0x0d;
  fourBitLookup1[6]  = 0x3e;
  fourBitLookup1[14] = 0x0f;

  for (int i = 0; i < 16; i++)
  {
    startBitLookupEnabled[i] = 0xffffffff;
    startBitLookupDisabled[i] = 0xffffffff;
  }

  startBitLookupEnabled[0b0000] = 4;
  startBitLookupEnabled[0b0001] = 3;
  startBitLookupEnabled[0b0011] = 2;
  startBitLookupEnabled[0b0111] = 1;

  unsafe {
    c <: (void * unsafe) rx_slots;
    c <: (void * unsafe) rx_slot_info;
  }
  while (1) {
    c :> int;
    /* initialisation loop */
    for (int i = 0; i < MUART_RX_CHAN_COUNT; i++) {
      state[i] = idle;
      uart_word[i] = 0;
      bit_count[i] = 0;
      tickcount[i] = rx_slot_info[i].use_sample;
      unsafe {
        if (i < num_uarts) {
          startBitConfig[i] =
            (unsigned) (unsigned * unsafe) startBitLookupEnabled;
        } else {
          startBitConfig[i] =
            (unsigned) (unsigned * unsafe) startBitLookupDisabled;
        }

        fourBitConfig[i]  = (unsigned) (unsigned * unsafe) fourBitLookup0;
      }
    }

    /* run ASM function - will exit on reconfiguration request over the channel */
    uart_rx_loop_8(p, state, tickcount, bit_count, uart_word,
                   c, rx_slots, fourBitConfig, rx_slot_info, startBitConfig);
  }
}
