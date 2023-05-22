// Copyright (c) 2016, XMOS Ltd, All rights reserved
/** @file      XUD_EPFunctions.xc
  * @brief     Implementation of user API fuctions.  See xud.h for documentation.
  * @author    Ross Owen, XMOS Limited
  **/

#include <xs1.h>
#include "xud.h"
#include "string.h"

static inline int min(int x, int y)
{
    if (x < y)
        return x;
    return y;
}

XUD_Result_t XUD_GetBuffer(XUD_ep c, unsigned char buffer[], unsigned &length)
{
    return XUD_GetData(c, buffer, length);
}

XUD_Result_t XUD_GetSetupBuffer(XUD_ep ep_out, unsigned char buffer[], unsigned &length)
{
    return XUD_GetSetupData(ep_out, buffer, length);
}

XUD_Result_t XUD_SetBuffer(XUD_ep c, unsigned char buffer[], unsigned datalength)
{
    /* No PID reset, 0 start index */
    return XUD_SetData(c, buffer, datalength, 0, 0);
}

XUD_Result_t XUD_SetBuffer_EpMax(XUD_ep ep_in, unsigned char buffer[], unsigned datalength, unsigned epMax)
{
    int i = 0;
    XUD_Result_t result;

    /* Note: We could encompass this in the SetData function */
    if (datalength <= epMax)
    {
        /* Datalength is less than the maximum per transaction of the EP, so just send */
        result = XUD_SetData(ep_in, buffer, datalength, 0, 0);
        return result;
    }
    else
    {
        /* Send first packet out and reset PID */
        if((result = XUD_SetData(ep_in, buffer, epMax, 0, 0)) != XUD_RES_OKAY)
        {
            return result;
        }
        i+= epMax;
        datalength-=epMax;

        while (1)
	    {
            if (datalength > epMax)
	        {
                /* PID Automatically toggled */
                if ((result = XUD_SetData(ep_in, buffer, epMax, i, 0)) != XUD_RES_OKAY)
                    return result;

                datalength-=epMax;
                i += epMax;
	        }
	        else
	        {
                /* PID automatically toggled */
                if ((result = XUD_SetData(ep_in, buffer, datalength, i, 0)) != XUD_RES_OKAY)
                    return result;

	            break; //out of while loop
	        }
	    }
    }

    return XUD_RES_OKAY;
}

/* TODO Should take ep max length as a param - currently hardcoded as 64 (#11384) */
XUD_Result_t XUD_DoGetRequest(XUD_ep ep_out, XUD_ep ep_in, unsigned char buffer[], unsigned length, unsigned requested)
{
    unsigned char tmpBuffer[1024];
    unsigned rxlength;
    unsigned sendLength = min(length, requested);
    XUD_Result_t result;

    if ((result = XUD_SetBuffer_EpMax(ep_in, buffer, sendLength, 64)) != XUD_RES_OKAY)
    {
        return result;
    }

    /* USB 2.0 8.5.3.2: Send < 0 length packet when data-length % 64 is 0
     * Note, we also don't want to try and send 2 zero-length packets i.e. if sendLength = 0 */
    if ((requested > length) && ((length % 64) == 0))
    {
        XUD_SetBuffer(ep_in, tmpBuffer, 0);
    }

    /* Status stage - this should return -1 for reset or 0 for 0 length status stage packet */
    return XUD_GetData(ep_out, tmpBuffer, rxlength);
}

void XUD_InitPartialGetRequest(XUD_PartialGetRequestState_t &st, unsigned requested)
{
  st.requested = requested;
  st.fill = 0;
}

XUD_Result_t XUD_DoPartialGetRequest(XUD_PartialGetRequestState_t &st,
    XUD_ep ep_out, XUD_ep ep_in,
    unsigned char buffer[length],
    unsigned length)
{
  unsigned char * buf = buffer;
  XUD_Result_t result;
  length = min(st.requested, length);
  st.requested -= length;
  if (length + st.fill < 64) {
    memcpy(&st.buffer[st.fill], buffer, length);
    st.fill += length;
    return XUD_RES_OKAY;
  }

  memcpy(&st.buffer[st.fill], buf, 64 - st.fill);
  length -= (64 - st.fill);
  buf += (64 - st.fill);

  result = XUD_SetBuffer_EpMax(ep_in, st.buffer, 64, 64);
  if (result != XUD_RES_OKAY)
    return result;
  unsigned roundedLength = (length - length % 64);
  if (roundedLength > 0) {
    if ((int) buf % 4 == 0) {
      result = XUD_SetBuffer_EpMax(ep_in, buf, roundedLength, 64);
      length -= roundedLength;
      buf += roundedLength;
    }
    else {
      // Buffer is not 32-bit aligned so we have to copy
      // into the aligned buffer in 64 byte chunks.
      while (length >= 64) {
        memcpy(st.buffer, buf, 64);
        result = XUD_SetBuffer_EpMax(ep_in, st.buffer, roundedLength, 64);
        if (result != XUD_RES_OKAY)
          return result;
        length -= 64;
        buf += 64;
      }
    }
  }

  st.fill = length;
  if (length > 0)
     memcpy(&st.buffer[0], buf, length);

  return result;
}

XUD_Result_t XUD_CompletePartialGetRequest(XUD_PartialGetRequestState_t &st,
                                           XUD_ep ep_out, XUD_ep ep_in)
{
  unsigned char tmpBuffer[1024];
  unsigned rxlength;
  XUD_SetBuffer_EpMax(ep_in, st.buffer, st.fill, 64);
  return XUD_GetData(ep_out, tmpBuffer, rxlength);
}

XUD_Result_t XUD_DoSetRequestStatus(XUD_ep ep_in)
{
    unsigned char tmp[8];

    /* Send 0 length packet */
    return XUD_SetData(ep_in, tmp, 0, 0, 0);
}

void XUD_SetStall(XUD_ep ep)
{
    /* Get EP address from XUD_ep structure */
    unsigned int epAddress;

    asm ("ldw %0, %1[8]":"=r"(epAddress):"r"(ep));

    XUD_SetStallByAddr(epAddress);
}

void XUD_ClearStall(XUD_ep ep)
{
    /* Get EP address from XUD_ep structure */
    unsigned int epAddress;

    asm ("ldw %0, %1[8]":"=r"(epAddress):"r"(ep));

    XUD_ClearStallByAddr(epAddress);
}

XUD_BusSpeed_t XUD_ResetEndpoint(XUD_ep one, XUD_ep &?two)
{
    int busStateCt;
    int busSpeed;

    unsigned c1, c2, tmp;

    /* Input rst control token */
    asm volatile("ldw %0, %1[2]":"=r"(c1):"r"(one));             // Load our chanend
    asm volatile ("inct %0, res[%1]": "=r"(busStateCt):"r"(c1)); // busStateCt = inct(one);

    if (!isnull(two))
    {
        asm volatile("ldw %0, %1[2]":"=r"(c2):"r"(two));
        asm volatile ("inct %0, res[%1]": "=r"(busStateCt):"r"(c2));
    }

    /* Clear ready flag (tidies small race where EP marked ready just after XUD clears ready due to reset */
    asm volatile("ldw %0, %1[0]":"=r"(tmp):"r"(one));           // Load address of ep in XUD rdy table
    asm volatile ("stw %0, %1[0]"::"r"(0), "r"(tmp));

    /* Clear resetting flag */
    asm volatile ("stw %0, %1[9]"::"r"(0), "r"(one));

    if(!isnull(two))
    {
        asm volatile("ldw %0, %1[0]":"=r"(tmp):"r"(two));       // Load address of ep in XUD rdy table
        asm volatile ("stw %0, %1[0]"::"r"(0), "r"(tmp));

         /* Reset reseting flag */
        asm volatile ("stw %0, %1[9]"::"r"(0), "r"(two));
    }

    /* Expect a word with speed */
    asm volatile ("in %0, res[%1]": "=r"(busSpeed):"r"(c1));

    if (!isnull(two))
    {
        asm volatile ("in %0, res[%1]": "=r"(busSpeed):"r"(c2));
    }
    return (XUD_BusSpeed_t) busSpeed;
}

XUD_ep XUD_InitEp(chanend c, XUD_EpType epType)
{
    XUD_ep ep = inuint(c);
    outuint(c, epType);
    return ep;
}

/**
 * Special case of set buffer for control EP's where you care if you receive a new SETUP instead of sending
 * the passed IN data.
 *
 * NOTE: This function is currently in use
 *
 * TODO we dont want to pass in channels here really.. get that out of the XUD_EP struct..
 */
int XUD_SetControlBuffer(chanend c_out, chanend c_in, XUD_ep ep_out, XUD_ep ep_in, unsigned char buffer_out[], unsigned char buffer_in[], unsigned datalength)
{
    unsigned length;
    XUD_Result_t result;

    /* Set ready on both the In and Out Eps */
    XUD_SetReady_Out(ep_out, buffer_out);
    XUD_SetReady_In(ep_in, buffer_in, datalength);

    select
    {
        case XUD_GetData_Select(c_out, ep_out, length, result):

                if (result == -1)
                {
                    /* If tmp - then we got a reset */
                    return result;
                }
                else
                {
                    /* Got data instead of sending */
                    return 2;
                }
            break;


        case XUD_SetData_Select(c_in, ep_in, result):

            /* We sent the data we wanted to send...
             * Return 0 for no error */
            return 0;
            break;
    }
    return 0;
}

