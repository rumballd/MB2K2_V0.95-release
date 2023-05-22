// Copyright (c) 2016, XMOS Ltd, All rights reserved

#ifndef _XUD_PWRSIG_H_
#define _XUD_PWRSIG_H_
#include <gpio.h>

void XUD_PhyReset(client output_gpio_if p_rst, int resetTime);

int XUD_Init();

int XUD_Suspend(XUD_PwrConfig pwrConfig);
#endif
