// Copyright (c) 2016, XMOS Ltd, All rights reserved
#ifndef __usb_dfu_h__
#define __usb_dfu_h__
#include "usb_endpoint0.h"
/* Experimental features.
   The features in this file are **experimental**,
   not supported and not known to work if enabled. Any guarantees of
   the robustness of the component made by XMOS do not hold if these features
   are used.
*/
XUD_Result_t handle_DFU_device_requests(XUD_ep ep0_out, XUD_ep ep0_in,
                                        USB_SetupPacket_t sp,
                                        client usb_dfu_callback_if i_dfu,
                                        int &reset_device);

/* Returns whether device should be in DFU mode */
int dfu_reset_state(void);

#endif
