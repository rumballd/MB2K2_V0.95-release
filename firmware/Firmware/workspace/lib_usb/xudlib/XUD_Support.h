// Copyright (c) 2016, XMOS Ltd, All rights reserved
/** @file      XUD_Support.h
  * @brief     Various  support functions used in XUD
  * @author    Ross Owen, XMOS Limited
 */

#ifndef _XUD_SUPPORT_H_
#define _XUD_SUPPORT_H_ 1

#ifndef XUD_U_SERIES
#define XUD_U_SERIES 1
#endif

#ifndef XUD_L_SERIES
#define XUD_L_SERIES 2
#endif

#ifndef XUD_G_SERIES
#define XUD_G_SERIES 3
#endif

#ifndef XUD_X200_SERIES
#define XUD_X200_SERIES 4
#endif

#if XUD_SERIES_SUPPORT==1
#ifndef ARCH_S
#define ARCH_S 1
#endif
#ifndef ARCH_L
#define ARCH_L 1
#endif
#endif

#if XUD_SERIES_SUPPORT==2
#ifndef ARCH_L
#define ARCH_L 1
#endif
#endif

#if XUD_SERIES_SUPPORT==3
#ifndef ARCH_G
#define ARCH_G 1
#endif
#endif

#if XUD_SERIES_SUPPORT==4
#ifndef ARCH_L
#define ARCH_L 1
#endif
#ifndef ARCH_X200
#define ARCH_X200 1
#endif
#endif

#ifdef __XC__

/* Typedefs for resources */
typedef unsigned XUD_lock;
typedef unsigned XUD_chan;

// Delay execution (Uses timer)
void XUD_Sup_Delay(unsigned x);

inline unsigned XUD_Sup_GetResourceId(chanend c)
{
    unsigned id;
    asm ("mov %0, %1" : "=r"(id) : "r"(c));
    return id;
}

// Channel comms - In
inline unsigned char XUD_Sup_inct(XUD_chan c)
{
    unsigned char x;
    asm volatile("inct %0, res[%1]" : "=r"(x) : "r"(c));
    return x;
}

inline unsigned char XUD_Sup_int(XUD_chan c)
{
    unsigned char x;
    asm volatile("int %0, res[%1]" : "=r"(x) : "r"(c));
    return x;
}

inline unsigned char XUD_Sup_testct(XUD_chan c)
{
    unsigned char x;
    asm volatile("testct %0, res[%1]" : "=r"(x) : "r"(c));
    return x;
}

// Channel comms - Out
inline void XUD_Sup_outuint(XUD_chan c, unsigned x)
{
    asm volatile("out res[%0], %1" : /* no outputs */ : "r"(c), "r"(x));
}

inline void XUD_Sup_outuchar(XUD_chan c, unsigned char x)
{
    asm volatile("outt res[%0], %1" : /* no outputs */ : "r"(c), "r"(x));
}

inline void XUD_Sup_outct(XUD_chan c, unsigned char x)
{
    asm volatile("outct res[%0], %1" : /* no outputs */ : "r"(c), "r"(x));
}


#endif

#endif
