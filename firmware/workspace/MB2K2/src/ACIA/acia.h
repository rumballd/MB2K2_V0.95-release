// Copyright (c) 2016, XMOS Ltd, All rights reserved

#ifndef ACIA_H_
#define ACIA_H_

#ifdef USB_SERIAL
extern void acia(client interface usb_cdc_interface cdc0, client interface usb_cdc_interface cdc1, chanend c_acia);
#endif

#ifdef FTDI_SERIAL
extern void acia(client uart_tx_if i_tx0, client uart_rx_if i_rx0, // (WD2123)
                 client uart_tx_if i_tx1, client uart_rx_if i_rx1,
                 chanend c_acia);
#endif

#endif /* ACIA_H_ */
