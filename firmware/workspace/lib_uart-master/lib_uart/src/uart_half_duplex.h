// Copyright (c) 2015-2016, XMOS Ltd, All rights reserved
#ifndef __uart_half_duplex_h__
#define __uart_half_duplex_h__

enum uart_tx_state {
  WAITING_FOR_DATA,
  OUTPUTTING_DATA_BIT,
  OUTPUTTING_PARITY_BIT,
  OUTPUTTING_STOP_BIT,
  TX_INACTIVE
};
enum uart_rx_state {
  WAITING_FOR_INPUT,
  WAITING_FOR_HIGH,
  TESTING_START_BIT,
  INPUTTING_DATA_BIT,
  INPUTTING_PARITY_BIT,
  INPUTTING_STOP_BIT,
  RX_INACTIVE
};

#endif // __uart_half_duplex_h__
