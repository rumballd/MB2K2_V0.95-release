// Copyright (c) 2016, XMOS Ltd, All rights reserved
/*
 * \brief     User defines and functions for XMOS USB Device library
 */

#ifndef __xud_h__
#define __xud_h__

#include <xs1.h>
#include <platform.h>
#include <print.h>
#include <xccompat.h>

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

#ifdef __xud_conf_h_exists__
#include "xud_conf.h"
#endif

#include "xud_defines.h"

#if !defined(USB_TILE)
  #define USB_TILE tile[0]
#endif

#if defined(PORT_USB_CLK)

  /* Ports declared in the .xn file. Automatically detect device series */
  #if defined(PORT_USB_RX_READY)
    #if !defined(XUD_SERIES_SUPPORT)
      #define XUD_SERIES_SUPPORT XUD_U_SERIES
    #endif

#if (XUD_SERIES_SUPPORT != XUD_U_SERIES) && (XUD_SERIES_SUPPORT != XUD_X200_SERIES)
      #error (XUD_SERIES_SUPPORT != XUD_U_SERIES) with PORT_USB_RX_READY defined
    #endif

  #else
    #if !defined(XUD_SERIES_SUPPORT)
      #define XUD_SERIES_SUPPORT XUD_L_SERIES
    #endif

#if (XUD_SERIES_SUPPORT != XUD_L_SERIES) && (XUD_SERIES_SUPPORT != XUD_G_SERIES) && (XUD_SERIES_SUPPORT != XUD_X200_SERIES)
      #error (XUD_SERIES_SUPPORT != XUD_L_SERIES) when PORT_USB_RX_READY not defined
    #endif

  #endif

#else // PORT_USB_CLK

  #if !defined(XUD_SERIES_SUPPORT)
    // Default to U-Series if no series is defined
    #define XUD_SERIES_SUPPORT XUD_U_SERIES
  #endif

  /* Ports have not been defined in the .xn file */

  #if (XUD_SERIES_SUPPORT == XUD_U_SERIES)
    #define PORT_USB_CLK         on USB_TILE: XS1_PORT_1J
    #define PORT_USB_TXD         on USB_TILE: XS1_PORT_8A
    #define PORT_USB_RXD         on USB_TILE: XS1_PORT_8C
    #define PORT_USB_TX_READYOUT on USB_TILE: XS1_PORT_1K
    #define PORT_USB_TX_READYIN  on USB_TILE: XS1_PORT_1H
    #define PORT_USB_RX_READY    on USB_TILE: XS1_PORT_1M
    #define PORT_USB_FLAG0       on USB_TILE: XS1_PORT_1N
    #define PORT_USB_FLAG1       on USB_TILE: XS1_PORT_1O
    #define PORT_USB_FLAG2       on USB_TILE: XS1_PORT_1P
  #elif (XUD_SERIES_SUPPORT == XUD_X200_SERIES)
    #define PORT_USB_CLK         on USB_TILE: XS1_PORT_1C
    #define PORT_USB_TXD         on USB_TILE: XS1_PORT_8A
    #define PORT_USB_RXD         on USB_TILE: XS1_PORT_8B
    #define PORT_USB_TX_READYOUT on USB_TILE: XS1_PORT_1K
    #define PORT_USB_TX_READYIN  on USB_TILE: XS1_PORT_1H
    #define PORT_USB_RX_READY    on USB_TILE: XS1_PORT_1I
    #define PORT_USB_FLAG0       on USB_TILE: XS1_PORT_1E
    #define PORT_USB_FLAG1       on USB_TILE: XS1_PORT_1F
    #define PORT_USB_FLAG2       on USB_TILE: XS1_PORT_1G
  #else
    #define PORT_USB_CLK         on USB_TILE: XS1_PORT_1H
    #define PORT_USB_REG_WRITE   on USB_TILE: XS1_PORT_8C
    #define PORT_USB_REG_READ    on USB_TILE: XS1_PORT_8D
    #define PORT_USB_TXD         on USB_TILE: XS1_PORT_8A
    #define PORT_USB_RXD         on USB_TILE: XS1_PORT_8B
    #define PORT_USB_STP_SUS     on USB_TILE: XS1_PORT_1E
    #define PORT_USB_FLAG0       on USB_TILE: XS1_PORT_1N
    #define PORT_USB_FLAG1       on USB_TILE: XS1_PORT_1O
    #define PORT_USB_FLAG2       on USB_TILE: XS1_PORT_1P
  #endif
#endif // PORT_USB_CLK

/**
 * \var        typedef     XUD_EpTransferType
 * \brief      Typedef for endpoint data transfer types.  Note: it is important that ISO is 0
 */
typedef enum XUD_EpTransferType
{
    XUD_EPTYPE_ISO = 0,          /**< Isoc */
    XUD_EPTYPE_INT,              /**< Interrupt */
    XUD_EPTYPE_BUL,              /**< Bulk */
    XUD_EPTYPE_CTL,              /**< Control */
    XUD_EPTYPE_DIS,              /**< Disabled */
} XUD_EpTransferType;

/**
 * \var        typedef XUD_EpType
 * \brief      Typedef for endpoint type
 */
typedef unsigned int XUD_EpType;

/**
 * \var        typedef XUD_ep
 * \brief      Opaque type representing endpoint identifiers
 */
typedef unsigned int XUD_ep;

/* Value to be or'ed in with EpTransferType to enable bus state notifications */
#define XUD_STATUS_ENABLE           0x80000000

typedef enum XUD_BusSpeed
{
    XUD_SPEED_FS = 1,
    XUD_SPEED_HS = 2
} XUD_BusSpeed_t;

typedef enum XUD_PwrConfig
{
    XUD_PWR_BUS,
    XUD_PWR_SELF
} XUD_PwrConfig;

/** Type containing the result of a endpoint function call. */
typedef enum XUD_Result_t
{
    XUD_RES_RST = -1, ///< A USB reset has occurred.
    XUD_RES_OKAY = 0, ///< Operation completed successfully.
    XUD_RES_ERR,      ///< An error has occurred.
} XUD_Result_t;

/**
 * \brief   This function must be called by a thread that deals with an OUT endpoint.
 *          When the host sends data, the low-level driver will fill the buffer. It
 *          pauses until data is available.
 * \param   ep_out      The OUT endpoint identifier (created by ``XUD_InitEP``).
 * \param   buffer      The buffer in which to store data received from the host.
 *                      The buffer is assumed to be word aligned.
 * \param   length      The number of bytes written to the buffer
 * \return  XUD_RES_OKAY on success
 **/
XUD_Result_t XUD_GetBuffer(XUD_ep ep_out, unsigned char buffer[], REFERENCE_PARAM(unsigned, length));


/**
 * \brief   Request setup data from usb buffer for a specific endpoint, pauses until data is available.
 * \param   ep_out      The OUT endpoint identifier (created by ``XUD_InitEP``).
 * \param   buffer      A char buffer passed by ref into which data is returned.
 * \param   length      Length of the buffer received (expect 8 bytes)
 * \return  XUD_RES_OKAY on success
 **/
XUD_Result_t XUD_GetSetupBuffer(XUD_ep ep_out, unsigned char buffer[], REFERENCE_PARAM(unsigned, length));


/**
 * \brief  This function must be called by a thread that deals with an IN endpoint.
 *         When the host asks for data, the low-level driver will transmit the buffer
 *         to the host.
 * \param   ep_in       The endpoint identifier (created by ``XUD_InitEp``).
 * \param   buffer      The buffer of data to transmit to the host.
 * \param   datalength  The number of bytes in the buffer.
 * \return  XUD_RES_OKAY on success
 */
XUD_Result_t XUD_SetBuffer(XUD_ep ep_in, unsigned char buffer[], unsigned datalength);


/**
 * \brief   Similar to XUD_SetBuffer but breaks up data transfers into smaller packets.
 *          This function must be called by a thread that deals with an IN endpoint.
 *          When the host asks for data, the low-level driver will transmit the buffer
 *          to the host.
 * \param   ep_in       The IN endpoint identifier (created by ``XUD_InitEp``).
 * \param   buffer      The buffer of data to transmit to the host.
 * \param   datalength  The number of bytes in the buffer.
 * \param   epMax       The maximum packet size in bytes.
 * \return  XUD_RES_OKAY on success
 */
XUD_Result_t XUD_SetBuffer_EpMax(XUD_ep ep_in, unsigned char buffer[], unsigned datalength, unsigned epMax);


/**
 * \brief  Performs a combined ``XUD_SetBuffer`` and ``XUD_GetBuffer``.
 *         It transmits the buffer of the given length over the ``ep_in`` endpoint to
 *         answer an IN request, and then waits for a 0 length Status OUT transaction on ``ep_out``.
 *         This function is normally called to handle Get control requests to Endpoint 0.
 *
 * \param   ep_out      The endpoint identifier that handles Endpoint 0 OUT data in the XUD manager.
 * \param   ep_in       The endpoint identifier that handles Endpoint 0 IN data in the XUD manager.
 * \param   buffer      The data to send in response to the IN transaction. Note that this data
 *                      is chopped up in fragments of at most 64 bytes.
 * \param   length      Length of data to be sent.
 * \param   requested   The length that the host requested, (Typically pass the value ``wLength``).
 * \return  XUD_RES_OKAY on success
 **/
XUD_Result_t XUD_DoGetRequest(XUD_ep ep_out, XUD_ep ep_in,  unsigned char buffer[], unsigned length, unsigned requested);


#ifdef __XC__

/* A structure used to split a GetRequest over several calls */
typedef struct XUD_PartialGetRequestState {
   unsigned requested;
   unsigned fill;
   char buffer[64];
} XUD_PartialGetRequestState_t ;

/**
 * \brief  Initiates a sequence that will perform a combined ``XUD_SetBuffer`` and ``XUD_GetBuffer``.
 *         It transmits the buffer of the given length over the ``ep_in`` endpoint to
 *         answer an IN request, and then waits for a 0 length Status OUT transaction on ``ep_out``.
 *         This function is normally called to handle Get control requests to Endpoint 0.
 *         The array being data can be split into several calls via
 *         XUD_doPartialGetRequest() and XUD_CompletePartialGetRequest().
 *
 * \param   st          A structure to hold the state of the transaction with the XUD
 * \param   requested   The length that the host requested, (Typically pass the value ``wLength``).
 **/
void XUD_InitPartialGetRequest(XUD_PartialGetRequestState_t &st, unsigned requested);


/**
 * \brief  Performs part of a combined ``XUD_SetBuffer`` and ``XUD_GetBuffer``.
 *         It transmits the buffer of the given length over the ``ep_in`` endpoint to
 *         answer an IN request, and then waits for a 0 length Status OUT transaction on ``ep_out``.
 *         This function is normally called to handle Get control requests to Endpoint 0. This
 *         function can be called repeatedly after XUD_InitPartialGetRequest() and
 *         before XUD_CompletePartialGetRequest().
 *
 * \param   st          A structure to hold the state of the transaction with the XUD
 * \param   ep_out      The endpoint identifier that handles Endpoint 0 OUT data in the XUD manager.
 * \param   ep_in       The endpoint identifier that handles Endpoint 0 IN data in the XUD manager.
 * \param   buffer      The data to send in response to the IN transaction. Note that this data
 *                      is chopped up in fragments of at most 64 bytes.
 * \param   length      Length of data to be sent.
 * \return  XUD_RES_OKAY on success
 **/
XUD_Result_t XUD_DoPartialGetRequest(XUD_PartialGetRequestState_t &st,
    XUD_ep ep_out, XUD_ep ep_in,
    unsigned char buffer[length],
    unsigned length);


/**
 * \brief  Completes a combined ``XUD_SetBuffer`` and ``XUD_GetBuffer``.
 *         It transmits the buffer of the given length over the ``ep_in`` endpoint to
 *         answer an IN request, and then waits for a 0 length Status OUT transaction on ``ep_out``.
 *         This function is normally called to handle Get control requests to Endpoint 0. This
 *         function should called repeatedly after XUD_InitPartialGetRequest() and
 *         XUD_doPartialGetRequest.
 *
 * \param   st          A structure to hold the state of the transaction with the XUD
 * \param   ep_out      The endpoint identifier that handles Endpoint 0 OUT data in the XUD manager.
 * \param   ep_in       The endpoint identifier that handles Endpoint 0 IN data in the XUD manager.
 * \return  XUD_RES_OKAY on success
 **/
XUD_Result_t XUD_CompletePartialGetRequest(XUD_PartialGetRequestState_t &st,
                                           XUD_ep ep_out, XUD_ep ep_in);

#endif

/**
 * \brief   This function sends an empty packet back on the next IN request with
 *          PID1. It is normally used by Endpoint 0 to acknowledge success of a control transfer.
 * \param   ep_in       The Endpoint 0 IN identifier to the XUD manager.
 * \return  XUD_RES_OKAY on success
 **/
XUD_Result_t XUD_DoSetRequestStatus(XUD_ep ep_in);


/**
 * \brief   Sets the device's address. This function must be called by Endpoint 0
 *          once a ``setDeviceAddress`` request is made by the host.
 * \param   addr New device address.
 * \warning Must be run on USB core
 */
XUD_Result_t XUD_SetDevAddr(unsigned addr);


/**
 * \brief   This function will complete a reset on an endpoint. Can take
 *          one or two ``XUD_ep`` as parameters (the second parameter can be set to ``null``).
 *          The return value should be inspected to find the new bus-speed.
 *          In Endpoint 0 typically two endpoints are reset (IN and OUT).
 *          In other endpoints ``null`` can be passed as the second parameter.
 * \param   one      IN or OUT endpoint identifier to perform the reset on.
 * \param   two      Optional second IN or OUT endpoint structure to perform a reset on.
 * \return  Either ``XUD_SPEED_HS`` - the host has accepted that this device can execute
 *          at high speed, or ``XUD_SPEED_FS`` - the device is runnig at full speed.
 */
XUD_BusSpeed_t XUD_ResetEndpoint(XUD_ep one, NULLABLE_REFERENCE_PARAM(XUD_ep, two));


/**
 * \brief      Initialises an XUD_ep
 * \param      c_ep     Endpoint channel to be connected to the XUD library.
 * \param      epType   Indicates the type of the endpoint.
 *                      Legal types include:
 *                     ``XUD_EPTYPE_CTL`` (Endpoint 0),
 *                     ``XUD_EPTYPE_BUL`` (Bulk endpoint),
 *                     ``XUD_EPTYPE_ISO`` (Isochronous endpoint),
 *                     ``XUD_EPTYPE_INT`` (Interrupt endpoint),
 *                     ``XUD_EPTYPE_DIS`` (Endpoint not used).
 * \return     Endpoint identifier
 */
XUD_ep XUD_InitEp(chanend c_ep, XUD_EpType epType);


/**
 * \brief      Mark an endpoint as STALL based on its EP address.  Cleared automatically if a SETUP received on the endpoint.
 *             Note: the IN bit of the endpoint address is used.
 * \param      epNum    Endpoint number.
 * \warning    Must be run on same tile as XUD core
 */
void XUD_SetStallByAddr(int epNum);


/**
 * \brief      Mark an endpoint as NOT STALLed based on its EP address.
 *             Note: the IN bit of the endpoint address is used.
 * \param      epNum    Endpoint number.
 * \warning    Must be run on same tile as XUD core
 */
void XUD_ClearStallByAddr(int epNum);

/**
 * \brief   Mark an endpoint as STALLed.  It is cleared automatically if a SETUP received on the endpoint.
 * \param   ep XUD_ep type.
 * \warning Must be run on same tile as XUD core
 */
void XUD_SetStall(XUD_ep ep);


/**
 * \brief   Mark an endpoint as NOT STALLed
 * \param   ep XUD_ep type.
 * \warning Must be run on same tile as XUD core
 */
void XUD_ClearStall(XUD_ep ep);

/* USB 2.0 Spec 9.1.1.5 states that configuring a device should cause all
 * the status and configuration values associated with the endpoints in the
 * affected interfaces to be set to their default values.  This includes setting
 * the data toggle of any endpoint using data toggles to the value DATA0 */
/**
 * \brief      Reset an Endpoints state including data PID toggle
 *             Note: the IN bit of the endpoint address is used.
 * \param      epNum    Endpoint number (including IN bit)
 * \warning    Must be run on same tile as XUD core
 */
void XUD_ResetEpStateByAddr(unsigned epNum);

/**
 * \brief   Enable a specific USB test mode in XUD
 * \param   ep          XUD_ep type (must be endpoint 0 in or out)
 * \param   testMode    The desired test-mode
 * \warning Must be run on same tile as XUD core
 */
void XUD_SetTestMode(XUD_ep ep, unsigned testMode);


/**********************************************************************************************
 * Below are prototypes for main assembly functions for data transfer to/from USB I/O thread
 * All other Get/Set functions defined here use these.  These are implemented in XUD_EpFuncs.S
 * Wrapper functions are provided for conveniance (implemented in XUD_EpFunctions.xc).
 */

/**
 * \brief      Gets a data buffer from XUD
 * \param      ep_out      The OUT endpoint identifier.
 * \param      buffer      The buffer to store received data into.
 * \param      length      Length of the buffer received
 * \return     XUD_RES_OKAY on success
 */
XUD_Result_t XUD_GetData(XUD_ep ep_out, unsigned char buffer[], REFERENCE_PARAM(unsigned, length));

/**
 * \brief      Gets a setup data from XUD
 * \param      ep_out      OUT endpoint identifier.
 * \param      buffer      Buffer to store received data into.
 * \param      length      Length of the buffer received (expect 8)
 * \return     XUD_RES_OKAY on success
 * TODO:       Use generic GetData for this
 */
XUD_Result_t XUD_GetSetupData(XUD_ep ep_out, unsigned char buffer[], REFERENCE_PARAM(unsigned, length));

/**
 * \brief     Gives a data buffer to XUD from transmission to the host
 * \param     ep_in        The IN endpoint identifier.
 * \param     buffer       The packet buffer to send data from.
 * \param     datalength   The length of the packet to send (in bytes).
 * \param     startIndex   The start index of the packet in the buffer (typically 0).
 * \param     pidToggle    No longer used, value ignored
 * \return    XUD_RES_OKAY on success
 */
XUD_Result_t XUD_SetData(XUD_ep ep_in, unsigned char buffer[], unsigned datalength, unsigned startIndex, unsigned pidToggle);

/***********************************************************************************************/

/*
 * Advanced functions for supporting multple Endpoints in a single core
 */

/**
 * \brief      Marks an OUT endpoint as ready to receive data
 * \param      ep          The OUT endpoint identifier (created by ``XUD_InitEp``).
 * \param      buffer      The buffer in which to store data received from the host.
 *                         The buffer is assumed to be word aligned.
 * \return     XUD_RES_OKAY on success
 */
inline int XUD_SetReady_Out(XUD_ep ep, unsigned char buffer[])
{
    int chan_array_ptr;
    int reset;

    /* Firstly check if we have missed a USB reset - endpoint may would not want receive after a reset */
    asm ("ldw %0, %1[9]":"=r"(reset):"r"(ep));
    if(reset)
    {
        return -1;
    }

    asm ("ldw %0, %1[0]":"=r"(chan_array_ptr):"r"(ep));
    asm ("stw %0, %1[3]"::"r"(buffer),"r"(ep));            // Store buffer
    asm ("stw %0, %1[0]"::"r"(ep),"r"(chan_array_ptr));

    return 0;
}

/**
 * \brief      Marks an OUT endpoint as ready to receive data
 * \param      ep          The OUT endpoint identifier (created by ``XUD_InitEp``).
 * \param      addr        The address of the buffer in which to store data received from the host.
 *                         The buffer is assumed to be word aligned.
 * \return     XUD_RES_OKAY on success
 */
inline int XUD_SetReady_OutPtr(XUD_ep ep, unsigned addr)
{
    int chan_array_ptr;
    int reset;

    /* Firstly check if we have missed a USB reset - endpoint may would not want receive after a reset */
    asm ("ldw %0, %1[9]":"=r"(reset):"r"(ep));
    if(reset)
    {
        return XUD_RES_RST;
    }
    asm ("ldw %0, %1[0]":"=r"(chan_array_ptr):"r"(ep));
    asm ("stw %0, %1[3]"::"r"(addr),"r"(ep));            // Store buffer
    asm ("stw %0, %1[0]"::"r"(ep),"r"(chan_array_ptr));

    return XUD_RES_OKAY;
}

#if defined(__XC__) || defined(__DOXYGEN__)
/**
 * \brief      Marks an IN endpoint as ready to transmit data
 * \param      ep          The IN endpoint identifier (created by ``XUD_InitEp``).
 * \param      addr        The address of the buffer to transmit to the host.
 *                         The buffer is assumed be word aligned.
 * \param      len         The length of the data to transmit.
 * \return     XUD_RES_OKAY on success
 */
inline XUD_Result_t XUD_SetReady_InPtr(XUD_ep ep, unsigned addr, int len)
{
    int chan_array_ptr;
    int tmp, tmp2;
    int wordlength;
    int taillength;

    int reset;

    /* Firstly check if we have missed a USB reset - endpoint may not want to send out old data after a reset */
    asm ("ldw %0, %1[9]":"=r"(reset):"r"(ep));
    if(reset)
    {
        return XUD_RES_RST;
    }

    /* Knock off the tail bits */
    wordlength = len >>2;
    wordlength <<=2;

    taillength = zext((len << 5),7);

    asm ("ldw %0, %1[0]":"=r"(chan_array_ptr):"r"(ep));

    // Get end off buffer address
    asm ("add %0, %1, %2":"=r"(tmp):"r"(addr),"r"(wordlength));

    asm ("neg %0, %1":"=r"(tmp2):"r"(len>>2));            // Produce negative offset from end off buffer

    // Store neg index
    asm ("stw %0, %1[6]"::"r"(tmp2),"r"(ep));            // Store index

    // Store buffer pointer
    asm ("stw %0, %1[3]"::"r"(tmp),"r"(ep));

    // Store tail len
    asm ("stw %0, %1[7]"::"r"(taillength),"r"(ep));

    asm ("stw %0, %1[0]"::"r"(ep),"r"(chan_array_ptr));      // Mark ready

    return XUD_RES_OKAY;
}

/**
 * \brief   Marks an IN endpoint as ready to transmit data
 * \param   ep          The IN endpoint identifier (created by ``XUD_InitEp``).
 * \param   buffer      The buffer to transmit to the host.
 *                      The buffer is assumed be word aligned.
 * \param   len         The length of the data to transmit.
 * \return  XUD_RES_OKAY on success
 */
inline XUD_Result_t XUD_SetReady_In(XUD_ep ep, unsigned char buffer[], int len)
{
    unsigned addr;

    asm("mov %0, %1":"=r"(addr):"r"(buffer));

    return XUD_SetReady_InPtr(ep, addr, len);
}

/**
 * \brief   Select handler function for receiving OUT endpoint data in a select.
 * \param   c        The chanend related to the endpoint
 * \param   ep       The OUT endpoint identifier (created by ``XUD_InitEp``).
 * \param   length   Passed by reference. The number of bytes written to the buffer,
 * \param   result   XUD_Result_t passed by reference. XUD_RES_OKAY on success
 */
#pragma select handler
void XUD_GetData_Select(chanend c, XUD_ep ep, REFERENCE_PARAM(unsigned, length), REFERENCE_PARAM(XUD_Result_t, result));

/**
 * \brief   Select handler function for transmitting IN endpoint data in a select.
 * \param   c        The chanend related to the endpoint
 * \param   ep       The IN endpoint identifier (created by ``XUD_InitEp``).
 * \param   result   Passed by reference. XUD_RES_OKAY on success

 */
#pragma select handler
void XUD_SetData_Select(chanend c, XUD_ep ep, REFERENCE_PARAM(XUD_Result_t, result));



/**
 * \brief   Select handler function for receiving setup data in a select.
 * \param   c        The chanend related to the endpoint
 * \param   ep       The OUT endpoint identifier (created by ``XUD_InitEp``).
 * \param   length   Passed by reference. The number of bytes written to the buffer,
 * \param   result   XUD_Result_t passed by reference. XUD_RES_OKAY on success
 */
#pragma select handler
void XUD_GetSetupData_Select(chanend c, XUD_ep ep, REFERENCE_PARAM(unsigned, length), REFERENCE_PARAM(XUD_Result_t, result));

/**
 * \brief   Select handler function to receive a SOF from XUD
 */
#pragma select handler
inline void XUD_Receive_Sof(chanend c) 
{
    (void) inuint(c);
}

#endif

/* Control token defines - used to inform EPs of bus-state types */
#define USB_RESET_TOKEN             8        /* Control token value that signals RESET */

#endif // __xud_h__
