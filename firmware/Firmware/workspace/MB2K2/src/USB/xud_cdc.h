// Copyright (c) 2016, XMOS Ltd, All rights reserved

#ifndef XUD_CDC_H_
#define XUD_CDC_H_

#include <xccompat.h>
#include "xud.h"

#define DEBUG 0

// USB interface and channel declaration.
//Channel ends must match the interfaces in the USB Configuration Descriptor
#define CDC_NOTIFICATION_INTERFACE1  0
#define CDC_NOTIFICATION_EP_NUM1     1

#define CDC_DATA_INTERFACE1          1
#define CDC_DATA_RX_EP_NUM1          1
#define CDC_DATA_TX_EP_NUM1          2

#define CDC_NOTIFICATION_INTERFACE2  2
#define CDC_NOTIFICATION_EP_NUM2     3

#define CDC_DATA_INTERFACE2          3
#define CDC_DATA_RX_EP_NUM2          2
#define CDC_DATA_TX_EP_NUM2          4


interface usb_cdc_interface {



    [[guarded]] void put_char(char byte);

    [[clears_notification]] [[guarded]] char get_char(void);

    [[guarded]] int write(unsigned char data[], REFERENCE_PARAM(unsigned, length));

    [[clears_notification]] [[guarded]] int read(unsigned char data[], REFERENCE_PARAM(unsigned, count));

    [[notification]] slave void data_ready( void );

    int available_bytes(void);

    void flush_buffer(void);
};

/* Endpoint 0 handling both std USB requests and CDC class specific requests */
void Endpoint0(chanend chan_ep0_out, chanend chan_ep0_in);

/* Function to handle all endpoints of the CDC class excluding control endpoint0 */
void CdcEndpointsHandler(chanend c_epint_in, chanend c_epbulk_out, chanend c_epbulk_in,
                         SERVER_INTERFACE(usb_cdc_interface, cdc));

#endif /* XUD_CDC_H_ */
