// Copyright (c) 2016, XMOS Ltd, All rights reserved
#ifndef __usb_h__
#define __usb_h__
#include <stddef.h>
#include <xs1.h>
#include <stdint.h>
//#include <flash.h>
#include <gpio.h>

/*************** XUD - Lower level API ***********************/

#include "xud.h"

/**************** Standard USB defines ***********************/

#include "usb_defs.h"

/* USB Standard Descriptor types (Section 9.4, table 9-5) */
enum USB_DescriptorTypes_t
{
    USB_DESCTYPE_DEVICE                 = 0x01, /* Device descriptor */
    USB_DESCTYPE_CONFIGURATION          = 0x02, /* Configuration descriptor */
    USB_DESCTYPE_STRING                 = 0x03, /* String descriptor */
    USB_DESCTYPE_INTERFACE              = 0x04, /* Interface descriptor */
    USB_DESCTYPE_ENDPOINT               = 0x05, /* Endpoint descriptor */
    USB_DESCTYPE_DEVICE_QUALIFIER       = 0x06, /* Device qualifier descriptor */
    USB_DESCTYPE_OTHER_SPEED            = 0x07,
    USB_DESCTYPE_INTERFACE_POWER        = 0x08, /* Interface power descriptor */
    USB_DESCTYPE_OTG                    = 0x09,
    USB_DESCTYPE_DEBUG                  = 0x0A,
    USB_DESCTYPE_INTERFACE_ASSOCIATION  = 0x0B, /* Interface association descriptor */
};

#ifdef __STDC__

/* No current support for __attribute((packed)) in XC */

/* Generic USB Descriptor Header */
typedef struct
{
    unsigned char bLength;              /* Size of the descriptor (bytes) */
    unsigned char bDescriptorType;      /* Descriptor type, either a value. See \ref USB_DescriptorTypes_t or
                                         * a value given by the specific class */
} __attribute__((packed)) USB_Descriptor_Header_t;

/* USB Standard Device Descriptor (section 9.6.1, table 9-8) */
typedef struct
{
    unsigned char bLength;              /* Size of the descriptor (bytes) */
    unsigned char bDescriptorType;      /* Descriptor type, either a value in \ref USB_DescriptorTypes_t
                                         * or a value given by the specific class */
    unsigned short bcdUSB;              /* Supported USB version */
    unsigned char  bDeviceClass;        /* USB device class code */
    unsigned char  bDeviceSubClass;     /* USB device subclass code */
    unsigned char  bDeviceProtocol;     /* USB device protocol code */
    unsigned char  bMaxPacketSize0;     /* Maximum packet size for endpoint 0 (bytes) */
    unsigned short idVendor;            /* Vendor ID */
    unsigned short idProduct;           /* Product ID */
    unsigned short bcdDevice;           /* Device release number in binary-coded decimal */
    unsigned char  iManufacturer;       /* Index of string descriptor describing manufacturer */
    unsigned char  iProduct;            /* Index of string descriptor describing product */
    unsigned char  iSerialNumber;       /* Index of String descriptor describing the devices serial number */
    unsigned char  bNumConfigurations;  /* Total number of configurations supported by the device */
} __attribute__((packed)) USB_Descriptor_Device_t;

/* USB Interface Association Descriptor (See IAD Engineering Change Notice) */
typedef struct
{
    unsigned char bLength;              /* Size of the descriptor (bytes) */
    unsigned char bDescriptorType;      /* Descriptor type, either a value in \ref USB_DescriptorTypes_t
                                          or a value given by the specific class */
    unsigned char bFirstInterface;      /* Index of the first associated interface */
    unsigned char bInterfaceCount;      /* Total number of associated interfaces */
    unsigned char bFunctionClass;       /* Interface class ID */
    unsigned char bFunctionSubClass;    /* Interface subclass ID */
    unsigned char bFunctionProtocol;    /* Interface protocol ID */
    unsigned char iFunction;            /* Index of the string descriptor describing the
                                         * interface association */
} __attribute__((packed)) USB_Descriptor_Interface_Association_t;

/* USB Standard Interface Descriptor (section 9.6.1 table 9-12) */
typedef struct
{
    unsigned char bLength;             /* Size of the descriptor (bytes) */
    unsigned char bDescriptorType;     /* Type of the descriptor, either a value in \ref USB_DescriptorTypes_t
                                        * or a value given by the specific class */
    unsigned char bInterfaceNumber;    /* Index of the interface in the current config */
	unsigned char bAlternateSetting;   /* Alternate setting for this interface number. Multiple alternatives
                                        * are supported per interface (with different EP configs) */
    unsigned char bNumEndpoints;       /* Total endpoint count in this interface */
    unsigned char bInterfaceClass;     /* Interface class code */

    unsigned char bInterfaceSubClass;  /* Interface subclass code */
    unsigned char bInterfaceProtocol;  /* Interface protocol code */
    unsigned char iInterface;          /* Index of the string descriptor in the string table */
} __attribute__((packed)) USB_Descriptor_Interface_t;

/* USB Standard Configuration Descriptor (section 9.6.1 table 9-10) */
typedef struct
{
    unsigned char  bLength;             /* Size of the descriptor (bytes) */
    unsigned char  bDescriptorType;     /* Type of the descriptor, either a value in \ref USB_DescriptorTypes_t or a value
                                         * given by the specific class */
    unsigned short wTotalLength;        /* Size of the configuration descriptor header and all sub descriptors inside
                                         * the configuration */
    unsigned char  bNumInterfaces;      /* Total interface count in the configuration */
    unsigned char  bConfigurationValue; /* Value to use as an argument to the SetConfiguration() request to select this
                                         * configuration */
    unsigned char  iConfiguration;      /* Index of string descriptor describing this configuration */
    unsigned char  bmAttributes;        /* Configuration characteristics
                                         * D7: Reserved (set to one)
                                         * D6: Self-powered
                                         * D5: Remote Wakeup
                                         * D4...0: Reserved (reset to zero)
                                        */
    unsigned char  bMaxPower;           /* Maximum power consumption of the USB device from the bus in this specific
                                         * configuration when the device is fully operational. Expressed in 2 mA units
                                         * (i.e., 50 = 100 mA) */
} __attribute__((packed)) USB_Descriptor_Configuration_Header_t;

/* USB Standard Endpoint Descriptor (section 9.6.1 table 9-13) */
typedef struct
{
    unsigned char bLength;             /* Size of the descriptor (bytes) */
    unsigned char bDescriptorType;     /* Descriptor type, either a value. See \ref USB_DescriptorTypes_t or
                                        * a value given by the specific class */
    unsigned char  bEndpointAddress;   /* Address of the endpoint, includes a direction mask */
    unsigned char  bmAttributes;       /* Endpoint attributes, comprised of a mask of the endpoint type
                                        * See EP_TYPE_ ad EP_ADDR) */
    unsigned short wMaxPacketSize;     /* Maximum packet size (bytes) that the endpoint can receive */
    unsigned char  bInterval;          /* Polling interval in milliseconds for the endpoint.
                                        * Relevant to Isochronous and Interrupt endpoints only */
} __attribute__((packed)) USB_Descriptor_Endpoint_t;

/* USB String Descriptor (Section 9.6.7 table 9-15) */
typedef struct
{
    unsigned char bLength;              /* Size of the descriptor (bytes) */
    unsigned char bDescriptorType;      /* Descriptor type, either a value in \ref USB_DescriptorTypes_t
                                         * or a value given by the specific class */
    unsigned short bString[];           /* String data, (as unicode characters) - use array of chars instead of string.
                                         * In GCC prefix string with "L" */
} __attribute__((packed)) USB_Descriptor_String_t;

#endif

/**************** USB Standard Requests  *******************************/

/** Data structure describing a USB request type. */
typedef struct USB_BmRequestType_t
{
   unsigned char Recipient; /**< Where the request is directed to:
                             *
                             *       *  0b00000: Device
                             *       *  0b00001: Specific interface
                             *       *  0b00010: Specific endpoint
                             *       *  0b00011: Other element in device
                             *
                             */
    unsigned char Type;     /**< The type of the request:
                             *
                             *       *  0b00: Standard request
                             *       *  0b01: Class specific request
                             *       *  0b10: Request by vendor specific driver
                             *
                             */
    unsigned char Direction;  /**< The direction of the request:
                               *
                               *     *  0 (Host->Dev)
                               *     *  1 (Dev->Host)
                               */
} USB_BmRequestType_t;

/** Setup packet data structure */
typedef struct USB_SetupPacket_t
{
  USB_BmRequestType_t bmRequestType;    ///< Specifies direction of dataflow, type of rquest and recipient
  unsigned char bRequest;               ///< Specifies the request
  unsigned short wValue;                ///< Host can use this to pass info to the device in its own way
  unsigned short wIndex;                ///< Typically used to pass index/offset such as interface or EP no
  unsigned short wLength;               ///< Number of data bytes in the data stage (for Host -> Device this this is exact count, for Dev->Host is a max)
} USB_SetupPacket_t;

/**
 *  \brief Prints out passed ``USB_SetupPacket_t`` struct using debug IO
 */
void USB_PrintSetupPacket(USB_SetupPacket_t sp);

void USB_ComposeSetupBuffer(USB_SetupPacket_t sp, unsigned char buffer[]);

void USB_ParseSetupPacket(unsigned char b[], REFERENCE_PARAM(USB_SetupPacket_t, p));

#if __XC__ && (XUD_SERIES_SUPPORT==XUD_L_SERIES || __DOXYGEN__)
/** USB device driver (L-series)
 *
 *  This performs the low-level USB I/O operations. Note that this
 *  needs to run in a thread with at least 80 MIPS worst case execution
 *  speed.
 *
 * \param   c_epOut     An array of channel ends, one channel end per
 *                      output endpoint (USB OUT transaction); this includes
 *                      a channel to obtain requests on Endpoint 0.
 * \param   noEpOut     The number of output endpoints, should be at least 1 (for Endpoint 0).
 * \param   c_epIn      An array of channel ends, one channel end per input endpoint (USB IN transaction);
 *                      this includes a channel to respond to requests on Endpoint 0.
 * \param   noEpIn      The number of input endpoints, should be at least 1 (for Endpoint 0).
 * \param   c_sof       A channel to receive SOF tokens on. This channel must be connected to a process that
 *                      can receive a token once every 125 ms. If tokens are not read, the USB layer will lock up.
 *                      If no SOF tokens are required ``null`` should be used for this parameter.
 *
 * \param   p_usb_rst   This is a GPIO interface which should be current to
 *                      the external phy reset line. See the GPIO library
 *                      for details on the interface.es.
 * \param   desiredSpeed This parameter specifies what speed the device will attempt to run at
 *                      i.e. full-speed (ie 12Mbps) or high-speed (480Mbps) if supported
 *                      by the host. Pass ``XUD_SPEED_HS`` if high-speed is desired or ``XUD_SPEED_FS``
 *                         if not. Low speed USB is not supported by XUD.
 * \param   pwrConfig   Specifies whether the device is bus or self-powered. When self-powered the XUD
 *                      will monitor the VBUS line for host disconnections. This is required for compliance reasons.
 *                      Valid values are XUD_PWR_SELF and XUD_PWR_BUS.
 *
 */

void xud_l_series(chanend c_epOut[noEpOut], static const size_t noEpOut,
                  chanend c_epIn[noEpIn], static const size_t noEpIn,
                  chanend ?c_sof,
                  client output_gpio_if ?p_usb_rst,
                  XUD_BusSpeed_t desiredSpeed,
                  XUD_PwrConfig pwrConfig);
#endif

#if __XC__ && (XUD_SERIES_SUPPORT==XUD_U_SERIES || XUD_SERIES_SUPPORT==XUD_X200_SERIES || __DOXYGEN__)
/** USB device driver (U-series)
 *
 * This performs the low-level USB I/O operations. Note that this
 * needs to run in a thread with at least 80 MIPS worst case execution
 * speed.
 *
 * \param   c_epOut     An array of channel ends, one channel end per
 *                      output endpoint (USB OUT transaction); this includes
 *                      a channel to obtain requests on Endpoint 0.
 * \param   noEpOut     The number of output endpoints, should be at least 1 (for Endpoint 0).
 * \param   c_epIn      An array of channel ends, one channel end per input endpoint (USB IN transaction);
 *                      this includes a channel to respond to requests on Endpoint 0.
 * \param   noEpIn      The number of input endpoints, should be at least 1 (for Endpoint 0).
 * \param   c_sof       A channel to receive SOF tokens on. This channel must be connected to a process that
 *                      can receive a token once every 125 ms. If tokens are not read, the USB layer will lock up.
 *                      If no SOF tokens are required ``null`` should be used for this parameter.
 *
 * \param   desiredSpeed This parameter specifies what speed the device will attempt to run at
 *                      i.e. full-speed (ie 12Mbps) or high-speed (480Mbps) if supported
 *                      by the host. Pass ``XUD_SPEED_HS`` if high-speed is desired or ``XUD_SPEED_FS``
 *                         if not. Low speed USB is not supported by XUD.
 * \param   pwrConfig   Specifies whether the device is bus or self-powered. When self-powered the XUD
 *                      will monitor the VBUS line for host disconnections. This is required for compliance reasons.
 *                      Valid values are XUD_PWR_SELF and XUD_PWR_BUS.
 *
 */
void xud(chanend c_epOut[noEpOut], static const size_t noEpOut,
         chanend c_epIn[noEpIn], static const size_t noEpIn,
         chanend ?c_sof,
         XUD_BusSpeed_t desiredSpeed,
         XUD_PwrConfig pwrConfig);
#endif




/**
  * \brief    This function deals with common requests This includes Standard Device Requests listed
  *           in table 9-3 of the USB 2.0 Spec all devices must respond to these requests, in some
  *           cases a bare minimum implementation is provided and should be extended in the devices EP0 code
  *           It handles the following standard requests appropriately using values passed to it:
  *
  *   Get Device Descriptor (using devDesc_hs/devDesc_fs arguments)
  *
  *   Get Configuration Descriptor (using cfgDesc_hs/cfgDesc_fs arguments)
  *
  *   String requests (using strDesc argument)
  *
  *   Get Device_Qualifier Descriptor
  *
  *   Get Other-Speed Configuration Descriptor
  *
  *   Set/Clear Feature (Endpoint Halt)
  *
  *   Get/Set Interface
  *
  *   Set Configuration
  *
  *   If the request is not recognised the endpoint is marked STALLED
  *
  *
  * \param     ep_out   Endpoint from XUD (ep 0)
  * \param     ep_in    Endpoint from XUD (ep 0)
  * \param     devDesc_hs The Device descriptor to use, encoded according to the USB standard
  * \param     devDescLength_hs Length of device descriptor in bytes
  * \param     cfgDesc_hs Configuration descriptor
  * \param     cfgDescLength_hs Length of config descriptor in bytes
  * \param     devDesc_fs The Device descriptor to use, encoded according to the USB standard
  * \param     devDescLength_fs Length of device descriptor in bytes. If 0 the HS device descriptor is used.
  * \param     cfgDesc_fs Configuration descriptor
  * \param     cfgDescLength_fs Length of config descriptor in bytes. If 0 the HS config descriptor is used.
  * \param     strDescs
  * \param     strDescsLength
  * \param     sp ``USB_SetupPacket_t`` (passed by ref) in which the setup data is returned
  * \param     usbBusSpeed The current bus speed (XUD_SPEED_HS or XUD_SPEED_FS)
  *
  * \return   Returns XUD_RES_OKAY on success.
  */

XUD_Result_t USB_StandardRequests(XUD_ep ep_out, XUD_ep ep_in,
    NULLABLE_ARRAY_OF(unsigned char, devDesc_hs), int devDescLength_hs,
    NULLABLE_ARRAY_OF(unsigned char, cfgDesc_hs), int cfgDescLength_hs,
    NULLABLE_ARRAY_OF(unsigned char, devDesc_fs), int devDescLength_fs,
    NULLABLE_ARRAY_OF(unsigned char, cfgDesc_fs), int cfgDescLength_fs,
#ifdef __XC__
    char * unsafe strDescs[],
#else
    char * strDescs[],
#endif
    int strDescsLength, REFERENCE_PARAM(USB_SetupPacket_t, sp), XUD_BusSpeed_t usbBusSpeed);

/**
 *  \brief  Receives a Setup data packet and parses it into the passed USB_SetupPacket_t structure.
 *  \param  ep_out   OUT endpint from XUD
 *  \param  ep_in    IN endpoint to XUD
 *  \param  sp       SetupPacket structure to be filled in (passed by ref)
 *  \return          Returns XUD_RES_OKAY on success, XUD_RES_RST on bus reset
 */
XUD_Result_t USB_GetSetupPacket(XUD_ep ep_out, XUD_ep ep_in, REFERENCE_PARAM(USB_SetupPacket_t, sp));

#endif //__usb_h__
