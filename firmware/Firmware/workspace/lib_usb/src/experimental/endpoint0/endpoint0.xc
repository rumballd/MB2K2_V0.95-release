// Copyright (c) 2016, XMOS Ltd, All rights reserved
/* Experimental features.
   The features in this file are **experimental**,
   not supported and not known to work if enabled. Any guarantees of
   the robustness of the component made by XMOS do not hold if these features
   are used.
*/
#include <xs1.h>
#include "usb.h"
#include "string.h"
#include <stdio.h>
#define DEBUG_UNIT USB_EP0
#include <debug_print.h>
#include <dfu.h>
#include <timer.h>

void do_device_reboot(void);

#ifndef MAX_INTS
/* Maximum number of interfaces supported */
#define MAX_INTS    16
#endif

#ifndef MAX_EPS
/* Maximum number of EP's supported */
#define MAX_EPS     XUD_MAX_NUM_EP
#endif

unsigned char g_currentConfig = 0;
unsigned char g_interfaceAlt[MAX_INTS]; /* Global endpoint status arrays */

unsigned short g_epStatusOut[MAX_EPS];
unsigned short g_epStatusIn[MAX_EPS];

static const char dfuStr[] = "DFU";

unsigned char dfuInterfaceDesc[] =
    /* Standard DFU class Interface descriptor */
    {0x09,  /* 0 bLength : Size of this descriptor, in bytes. */
    0x04,   /* 1 bDescriptorType : INTERFACE descriptor.  */
    0,      /* 2 bInterfaceNumber : Index of this interface.
                 SET DYNAMICALLY */
    0x00,   /* 3 bAlternateSetting : Index of this setting.  */
    0x00,   /* 4 bNumEndpoints : 0 endpoints.  */
    0xFE,   /* 5 bInterfaceClass : DFU.  */
    0x01,   /* 6 bInterfaceSubclass  */
    0x01,   /* 7 bInterfaceProtocol : Unused.  */
    4,      /* 8 iInterface */

    /* DFU 1.1 Run-Time DFU Functional Descriptor */
    0x09,                           /* 0    Size */
    0x21,                           /* 1    bDescriptorType : DFU FUNCTIONAL */
    0x07,                           /* 2    bmAttributes */
    0xFA,                           /* 3    wDetachTimeOut */
    0x00,                           /* 4    wDetachTimeOut */
    0x40,                           /* 5    wTransferSize */
    0x00,                           /* 6    wTransferSize */
    0x10,                           /* 7    bcdDFUVersion */
    0x01                            /* 7    bcdDFUVersion */
  };

/* Used when setting/clearing EP halt */
int SetEndpointHalt(unsigned epNum, unsigned halt)
{
    /* Inspect for IN bit */
    if(epNum & 0x80)
    {
        /* Range check */
        if((epNum&0x7F) < MAX_EPS)
        {
            g_epStatusIn[epNum & 0x7F] = halt;
            if(halt)
                XUD_SetStallByAddr(epNum);
            else
                XUD_ClearStallByAddr(epNum);
            return 0;
        }
    }
    else
    {
        if(epNum < MAX_EPS)
        {
            g_epStatusOut[epNum] = halt;
            if(halt)
                XUD_SetStallByAddr(epNum);
            else
                XUD_ClearStallByAddr(epNum);

            return 0;
        }
    }

    return 1;
}


void USB_ParseSetupPacket(unsigned char b[], USB_SetupPacket_t &p)
{
    // Byte 0: bmRequestType.
    p.bmRequestType.Recipient = b[0] & 0x1f;
    p.bmRequestType.Type      = (b[0] & 0x60) >> 5;
    p.bmRequestType.Direction = b[0] >> 7;

    // Byte 1:  bRequest
    p.bRequest = b[1];

    // Bytes [2:3] wValue
    p.wValue = (b[3] << 8) | (b[2]);

    // Bytes [4:5] wIndex
    p.wIndex = (b[5] << 8) | (b[4]);

    // Bytes [6:7] wLength
    p.wLength = (b[7] << 8) | (b[6]);
}

void USB_ComposeSetupBuffer(USB_SetupPacket_t sp, unsigned char buffer[])
{
    buffer[0] = sp.bmRequestType.Recipient
                  | (sp.bmRequestType.Type << 5)
                  | (sp.bmRequestType.Direction << 7);

    buffer[1] = sp.bRequest;

    buffer[2] = sp.wValue & 0xff;
    buffer[3] = (sp.wValue & 0xff00)>>8;

    buffer[4] = sp.wIndex & 0xff;
    buffer[5] = (sp.wIndex & 0xff00)>>8;

    buffer[6] = sp.wLength & 0xff;
    buffer[7] = (sp.wLength & 0xff00)>>8;
}

void USB_DebugSetupPacket(USB_SetupPacket_t sp)
{
  debug_printf("Setup Data\n");
  debug_printf("bmRequestType.Recipient: %x\n", sp.bmRequestType.Recipient);
  debug_printf("bmRequestType.Type: %x\n", sp.bmRequestType.Type);
  debug_printf("bmRequestType.Direction: %x\n", sp.bmRequestType.Direction);
  debug_printf("bRequest: %x\n", sp.bRequest);
  debug_printf("bmRequestType.wValue: %x\n", sp.wValue);
  debug_printf("bmRequestType.wIndex: %x\n", sp.wIndex);
  debug_printf("bmRequestType.wLength: %x\n", sp.wLength);
}


XUD_Result_t USB_GetSetupPacket(XUD_ep ep_out, XUD_ep ep_in, USB_SetupPacket_t &sp)
{
    unsigned char sbuffer[120];
    unsigned length;

    XUD_Result_t result;

    if((result = XUD_GetSetupBuffer(ep_out, sbuffer, length)) != XUD_RES_OKAY)
    {
        return result;
    }

    /* Parse data buffer end populate SetupPacket struct */
    USB_ParseSetupPacket(sbuffer, sp);

    /* Return 0 for success */
    return result;
}

/* This config descriptor is used for both HS and FS.
 *
 */

/* Device Descriptor */
static unsigned char devDesc[] =
{
    0x12,                  /* 0  bLength */
    USB_DESCTYPE_DEVICE,   /* 1  bdescriptorType */
    0x00,                  /* 2  bcdUSB */
    0x02,                  /* 3  bcdUSB */
    0x00,                  /* 4  bDeviceClass */
    0x00,                  /* 5  bDeviceSubClass */
    0x00,                  /* 6  bDeviceProtocol */
    0x40,                  /* 7  bMaxPacketSize */
    0x0,                   /* 8  idVendor - Set dynamically */
    0x0,                   /* 9  idVendor - Set dynamically*/
    0x0,                   /* 10 idProduct - Set dynamically*/
    0x0,                   /* 11 idProduct - Set dynamically */
    0x0,                   /* 12 bcdDevice - Set dynamically */
    0x0,                   /* 13 bcdDevice - Set dynamically */
    0x01,                  /* 14 iManufacturer */
    0x02,                  /* 15 iProduct */
    0x00,                  /* 16 iSerialNumber */
    0x01                   /* 17 bNumConfigurations */
};

static unsigned char cfgDescHdr[] = {
    0x09,                 /* 0  bLength */
    USB_DESCTYPE_CONFIGURATION,  /* 1  bDescriptortype */
    0x00, 0x00,           /* 2  wTotalLength - calculated dynamically */
    0x00,                 /* 4  bNumInterfaces  - calculated dynamically */
    0x01,                 /* 5  bConfigurationValue */
    0x03,                 /* 6  iConfiguration */
    0x80,                 /* 7  bmAttributes */
    250,                  /* 8  bMaxPower */
};

static XUD_Result_t sendConfigDescriptor(
    XUD_BusSpeed_t speed,
    client usb_ep0_callback_if i_ep0[numClients], size_t numClients,
    size_t numInterfaces[numClients],
    XUD_ep ep0_out, XUD_ep ep0_in,
    unsigned requested,
    client interface usb_dfu_callback_if ?i_dfu,
    int in_dfu_mode)
{
  XUD_PartialGetRequestState_t st;
  XUD_Result_t result;

  XUD_InitPartialGetRequest(st, requested);
  result = XUD_DoPartialGetRequest(st, ep0_out, ep0_in,
                                   cfgDescHdr, sizeof(cfgDescHdr));
  if (result != XUD_RES_OKAY)
    return result;
  for (size_t i = 0; i < numClients; i++) {
    for (size_t j = 0; j < numInterfaces[i]; j++) {
      size_t num;
      const ep0_descriptor * unsafe descs;
      unsafe {
        i_ep0[i].get_interface_descriptor(speed, j, descs, num);

        for (size_t i = 0; i < num; i++) {
          XUD_DoPartialGetRequest(st, ep0_out, ep0_in, (unsigned char *) descs[i].desc, descs[i].len);
        }
      }
      if (result != XUD_RES_OKAY)
        return result;
    }
  }
  if (!isnull(i_dfu)) {
    XUD_DoPartialGetRequest(st, ep0_out, ep0_in,
                            dfuInterfaceDesc, sizeof(dfuInterfaceDesc));
  }

  result = XUD_CompletePartialGetRequest(st, ep0_out, ep0_in);
  return result;
}

static const char langStr[] = "\x09\x04";
static const char configName[] = "Config";

extern volatile XUD_PwrConfig * unsafe p_UsbPwrConfig;

  /* Buffer for Setup data */
static unsigned char buffer[120];

static size_t dfuInterfaceNum = 0;

static XUD_BusSpeed_t usbBusSpeed;

static unsigned currentConfig = 0;

static int afterReset = 0;
static int in_dfu_mode = 0;

[[combinable]]
void usb_endpoint0(chanend chan_ep0_out, chanend chan_ep0_in,
                   enum ep0_support_type support_type,
                   const char *vendorName,
                   unsigned vendorId,
                   const char *productName,
                   unsigned productId,
                   unsigned productId_fs,
                   unsigned majorVersion,
                   unsigned minorVersion,
                   unsigned subMinorVersion,
                   client usb_dfu_callback_if ?i_dfu,
                   client usb_ep0_callback_if i_ep0[numClients],
                   static const size_t numClients)
{
  size_t strTableOffsets[numClients];
  size_t numInterfaces_fs[numClients], numInterfaces_hs[numClients];

  XUD_ep ep0_out = XUD_InitEp(chan_ep0_out, XUD_EPTYPE_CTL | XUD_STATUS_ENABLE);
  XUD_ep ep0_in  = XUD_InitEp(chan_ep0_in, XUD_EPTYPE_CTL | XUD_STATUS_ENABLE);

  unsafe {
    // Spin lock until the XUD task sets the power mode
    while (*p_UsbPwrConfig == -1);

    if (*p_UsbPwrConfig == XUD_PWR_SELF) {
      cfgDescHdr[7] = 192; // SELF POWERED
    } else {
      cfgDescHdr[7] = 128; // BUS POWERED
    }
  }

  devDesc[8] = vendorId & 0xff;
  devDesc[9] = vendorId >> 8;
  devDesc[12] = majorVersion & 0xff;
  devDesc[13] = (minorVersion << 8) + subMinorVersion;

  /* Gather information from all the connected configuration tasks to
   * get the string table offsets and interface descriptor sizes.
   */
  size_t totalInterfaces_hs = 0, totalInterfaces_fs = 0;
  size_t cfgDescLen_hs = sizeof(cfgDescHdr);
  size_t cfgDescLen_fs = sizeof(cfgDescHdr);
  size_t strTableSize = isnull(i_dfu) ? 4 : 5;
  for (size_t i = 0; i < numClients; i++) {
    size_t numStrings;
    strTableOffsets[i] = strTableSize;
    i_ep0[i].register_interfaces(strTableSize,
                                 totalInterfaces_hs,
                                 totalInterfaces_fs,
                                 numInterfaces_hs[i],
                                 numInterfaces_fs[i],
                                 numStrings);
    totalInterfaces_fs += numInterfaces_fs[i];
    totalInterfaces_hs += numInterfaces_hs[i];
    strTableSize += numStrings;
    for (size_t j = 0; j < numInterfaces_fs[i]; j++) {
      size_t num;
      const ep0_descriptor * unsafe descs;
      unsafe {
        i_ep0[i].get_interface_descriptor(XUD_SPEED_FS, j, descs, num);
        for (size_t i = 0; i < num; i++)
          cfgDescLen_fs += descs[i].len;
      }
    }
    for (size_t j = 0; j < numInterfaces_hs[i]; j++) {
      size_t num;
      const ep0_descriptor * unsafe descs;
      unsafe {
        i_ep0[i].get_interface_descriptor(XUD_SPEED_HS, j, descs, num);
        for (size_t i = 0; i < num; i++)
          cfgDescLen_hs += descs[i].len;
      }
    }
  }
  if (!isnull(i_dfu)) {
    cfgDescLen_hs += sizeof(dfuInterfaceDesc);
    dfuInterfaceNum = totalInterfaces_hs;
    totalInterfaces_hs++;
  }

  size_t cur_totalInterfaces_hs = totalInterfaces_hs;
  size_t cur_cfgDescLen_hs = cfgDescLen_hs;
  XUD_Result_t result;
  unsigned length;
  XUD_SetReady_Out(ep0_out, buffer);
  while (1)
  {
    select {
    case XUD_GetSetupData_Select(chan_ep0_out, ep0_out, length, result):
      USB_SetupPacket_t sp;
      if (result == XUD_RES_OKAY) {
        USB_ParseSetupPacket(buffer, sp);
      }
      unsigned bmRequestType = buffer[0];//(sp.bmRequestType.Direction<<7) | (sp.bmRequestType.Type<<5) | (sp.bmRequestType.Recipient);

      if (afterReset) {
        in_dfu_mode = dfu_reset_state();

        for (size_t i = 0; i < numClients; i++)
          i_ep0[i].connected(usbBusSpeed, in_dfu_mode);

        afterReset = 0;
        if (!isnull(i_dfu) && in_dfu_mode) {
          dfuInterfaceDesc[2] = 0;
          cur_totalInterfaces_hs = 1;
          cur_cfgDescLen_hs = sizeof(cfgDescHdr) + sizeof(dfuInterfaceDesc);
        }
        else {
          dfuInterfaceDesc[2] = dfuInterfaceNum;
          cur_totalInterfaces_hs = totalInterfaces_hs;
          cur_cfgDescLen_hs = cfgDescLen_hs;
        }
      }

      if (result == XUD_RES_RST) {
        usbBusSpeed = XUD_ResetEndpoint(ep0_out, ep0_in);
        afterReset = 1;
        XUD_SetReady_Out(ep0_out, buffer);
        break;
      }
      result = XUD_RES_ERR;

      /* See if any of the specific endpoint0 clients handles the request */
      for (size_t i = 0; i < numClients; i++) {
        i_ep0[i].handle_request(ep0_out, ep0_in, sp, result);
        if (result != XUD_RES_ERR)
          break;
      }

      /* USB bus reset detected, reset EP and get new bus speed */
      if (result == XUD_RES_RST) {
        usbBusSpeed = XUD_ResetEndpoint(ep0_out, ep0_in);
        afterReset = 1;
        XUD_SetReady_Out(ep0_out, buffer);
        break;
      }

      if (result != XUD_RES_ERR) {
        XUD_SetReady_Out(ep0_out, buffer);
        break;
      }

      /* Stick bmRequest type back together for an easier parse... */

      switch(bmRequestType)
        {
        case USB_BMREQ_H2D_CLASS_INT:
        case USB_BMREQ_D2H_CLASS_INT:
          unsigned interfaceNum = sp.wIndex & 0xff;
          int reset_device = 0;
          if (interfaceNum == dfuInterfaceNum && !isnull(i_dfu)) {
            result = handle_DFU_device_requests(ep0_out, ep0_in, sp, i_dfu,
                                                reset_device);
          }
          if (reset_device) {
            for (size_t i = 0; i < numClients; i++)
              i_ep0[i].pre_dfu_reboot();
            do_device_reboot();
          }

          break;

          /* Standard Device Requests - To Device */
        case USB_BMREQ_H2D_STANDARD_DEV:

          /* Inspect for actual request */
          switch(sp.bRequest)
            {
              /* Standard Device Request: ClearFeature (USB Spec 9.4.1) */
            case USB_CLEAR_FEATURE:

              /* Device Features than could potenially be cleared are as follows (See Figure 9-4)
               * Self Powered: Cannot be changed by SetFeature() or ClearFeature()
               * Remote Wakeup: Indicates if the device is currently enabled to request remote wakeup.
               by default not implemented
              */
              break;

              /* Standard Device Request: Set Address (USB spec 9.6.4) */
              /* This is a unique request since the operation is not completed until after the status stage */
            case USB_SET_ADDRESS:
              if((sp.wValue < 128) && (sp.wIndex == 0) && (sp.wLength == 0))
                {
                  /* Status stage: Send a zero length packet */
                  if((result = XUD_DoSetRequestStatus(ep0_in)) != XUD_RES_OKAY)
                    break;


                  /* Note: Really we should wait until ACK is received for status stage before changing address
                   * We will just wait some time... */
                  delay_ticks(50000);

                  /* Set the device address in XUD */
                  result = XUD_SetDevAddr(sp.wValue);
                }
              break;

              /* Standard Device Request: SetConfiguration (USB Spec 9.4.7) */
            case USB_SET_CONFIGURATION:
              if((sp.wLength == 0) && (sp.wIndex == 0))
                {
                  /* We can ignore sp.Direction if sp.wLength is 0. See USB Spec 9.3.1 */

                  /* USB 2.0 Spec 9.1.1.5 states that configuring a device should cause all
                   * the status and configuration values associated with the endpoints in the
                   * affected interfaces to be set to their default values.  This includes setting
                   * the data toggle of any endpoint using data toggles to the value DATA0 */

                  /* Note: currently assume all EP's related to config (apart from 0) */
                  for(unsigned i = 1; i < XUD_MAX_NUM_EP_IN; i++)
                    {
                      XUD_ResetEpStateByAddr(i | 0x80 );
                    }

                  for(unsigned i = 1; i < XUD_MAX_NUM_EP_OUT; i++)
                    {
                      XUD_ResetEpStateByAddr(i);
                    }

                  /* Update global configuration value
                   * Note alot of devices maye wish to implement features here since this
                   * request indicates the device being placed into its "Configured" state
                   * i.e. the host has accepted the device */
                  currentConfig = sp.wValue;

                  /* No data stage for this request, just do status stage */
                  result = XUD_DoSetRequestStatus(ep0_in);
                }
              break;

              /* Standard Device Request: SetDescriptor (USB Spec 9.4.8) */
            case USB_SET_DESCRIPTOR:

              /* Optional request for updating or adding new descriptors */
              /* Not implemented by default */

              break;

              /* Standard Device Request: SetFeature (USB Spec 9.4.9) */
            case USB_SET_FEATURE:

              if((sp.wValue == USB_TEST_MODE) && (sp.wLength == 0))
                {
                  /* Inspect for Test Selector (high byte of wIndex, lower byte must be zero) */
                  switch(sp.wIndex)
                    {
                    case USB_WINDEX_TEST_J:
                    case USB_WINDEX_TEST_K:
                    case USB_WINDEX_TEST_SE0_NAK:
                    case USB_WINDEX_TEST_PACKET:
                    case USB_WINDEX_TEST_FORCE_ENABLE:
                      {
                        XUD_Result_t result;
                        if((result = XUD_DoSetRequestStatus(ep0_in)) != XUD_RES_OKAY)
                          break;

                        XUD_SetTestMode(ep0_out, sp.wIndex);
                      }
                      break;
                    }
                }
              break;
            }
          break;

          /* Standard Device Requests - To Host */
        case USB_BMREQ_D2H_STANDARD_DEV:
          switch(sp.bRequest)
            {
              /* Standard Device Request: GetStatus (USB Spec 9.4.5)*/
            case USB_GET_STATUS:

              /* Remote wakeup not supported */
              buffer[1] = 0;

              /* Pull self/bus powered bit from the config descriptor */
              if (cfgDescHdr[7] & 0x40)
                buffer[0] = 0x1;
              else
                buffer[0] = 0;

              result = XUD_DoGetRequest(ep0_out, ep0_in, buffer, 2, sp.wLength);
              break;
              /* Standard Device Request: GetConfiguration (USB Spec 9.4.2) */
            case USB_GET_CONFIGURATION:

              /* Return the current configuration of the device */
              if((sp.wValue == 0) && (sp.wIndex == 0) && (sp.wLength == 1))
                {
                  buffer[0] = currentConfig;
                  result = XUD_DoGetRequest(ep0_out, ep0_in, buffer, 1, sp.wLength);
                }
              break;

              /* Standard Device Request: GetDescriptor (USB Spec 9.4.3)*/
            case USB_GET_DESCRIPTOR:

              /* Inspect for which Type of descriptor is required (high byte of wValue) */
              switch((sp.wValue & 0xff00) >> 8)
                {
                  /* Device descriptor */
                case USB_DESCTYPE_DEVICE:

                  /* Currently only 1 device descriptor supported */
                  if ((sp.wValue & 0xff) == 0)
                    {
                      if ((usbBusSpeed == XUD_SPEED_FS) && support_type != USB_SUPPORT_HS_ONLY)
                        {
                          /* Return full-speed device descriptor */
                          devDesc[10] = productId_fs & 0xff;
                          devDesc[11] = productId_fs >> 8;
                          result = XUD_DoGetRequest(ep0_out, ep0_in, devDesc, sizeof(devDesc), sp.wLength);
                        }
                      else if (support_type != USB_SUPPORT_FS_ONLY)
                        {
                          devDesc[10] = productId & 0xff;
                          devDesc[11] = productId >> 8;
                          /* Return high-speed device descriptor, if no FS desc, send the HS desc */
                          /* Do get request (send descriptor then 0 length status stage) */
                          result = XUD_DoGetRequest(ep0_out, ep0_in, devDesc, sizeof(devDesc), sp.wLength);
                        }
                    }
                  break;

                  /* Configuration Descriptor */
                case USB_DESCTYPE_CONFIGURATION:

                  /* Currently only 1 configuration descriptor supported */
                  /* TODO We currently return the same for all configs */
                  //if((sp.wValue & 0xff) == 0)

                  if ((usbBusSpeed == XUD_SPEED_FS) && support_type != USB_SUPPORT_HS_ONLY)
                    {
                      cfgDescHdr[1] = USB_DESCTYPE_CONFIGURATION;
                      cfgDescHdr[4] = totalInterfaces_fs;
                      cfgDescHdr[2] = cfgDescLen_fs & 0xff;
                      cfgDescHdr[3] = cfgDescLen_fs >> 8;
                      result = sendConfigDescriptor(XUD_SPEED_FS,
                                                    i_ep0, numClients,
                                                    numInterfaces_fs,
                                                    ep0_out, ep0_in,
                                                    sp.wLength,
                                                    null,0);
                    }
                  else  if (support_type != USB_SUPPORT_FS_ONLY)
                    {
                      cfgDescHdr[1] = USB_DESCTYPE_CONFIGURATION;
                      cfgDescHdr[4] = cur_totalInterfaces_hs;
                      cfgDescHdr[2] = cur_cfgDescLen_hs & 0xff;
                      cfgDescHdr[3] = cur_cfgDescLen_hs >> 8;
                      result = sendConfigDescriptor(XUD_SPEED_HS,
                                                    i_ep0, numClients,
                                                    numInterfaces_hs,
                                                    ep0_out, ep0_in,
                                                    sp.wLength,
                                                    i_dfu, in_dfu_mode);
                    }
                  break;

                  /* Device qualifier descriptor */
                case USB_DESCTYPE_DEVICE_QUALIFIER:
                  if((sp.wValue & 0xff) == 0)
                    {
                      /* Build a device qualifer descriptor from the device descriptor */
                      unsigned char devQualDesc[10];

                      if((usbBusSpeed == XUD_SPEED_HS) && (support_type != USB_SUPPORT_FS_ONLY))
                        {
                          /* Create devQual from FS Device Descriptor*/
                          devQualDesc[0] = 10;                            /* 0  bLength */
                          devQualDesc[1] = USB_DESCTYPE_DEVICE_QUALIFIER; /* 1  bDescriptorType */
                          devQualDesc[2] = devDesc[2];
                          devQualDesc[3] = devDesc[3];
                          devQualDesc[4] = devDesc[4];
                          devQualDesc[5] = devDesc[5];
                          devQualDesc[6] = devDesc[6];
                          devQualDesc[7] = devDesc[7];
                          devQualDesc[8] = devDesc[17];                /* 8  bNumConfigurations */
                          devQualDesc[9] = 0;

                          /* Do get request (send descriptor then 0 length status stage) */
                          result = XUD_DoGetRequest(ep0_out, ep0_in, devQualDesc, 10, sp.wLength);
                        }
                      else if (support_type != USB_SUPPORT_HS_ONLY)
                        {
                          /* Running in FS so create devQual from HS Device Descriptor */
                          devQualDesc[0] = 10;                            /* 0  bLength */
                          devQualDesc[1] = USB_DESCTYPE_DEVICE_QUALIFIER; /* 1  bDescriptorType */
                          devQualDesc[2] = devDesc[2];
                          devQualDesc[3] = devDesc[3];
                          devQualDesc[4] = devDesc[4];
                          devQualDesc[5] = devDesc[5];
                          devQualDesc[6] = devDesc[6];
                          devQualDesc[7] = devDesc[7];
                          devQualDesc[8] = devDesc[17];                /* 8  bNumConfigurations */
                          devQualDesc[9] = 0;

                          /* Do get request (send descriptor then 0 length status stage) */
                          result = XUD_DoGetRequest(ep0_out, ep0_in, devQualDesc, 10, sp.wLength);
                        }

                      /* Not handled if devDescLength_hs == 0 and running in full-speed.
                       * This should result in a STALL as per USB spec */
                    }
                  break;

                  /* Other Speed Configuration Descriptor */
                case USB_DESCTYPE_OTHER_SPEED:

                  /* Accepts any configuration number */
                  //if((sp.wValue & 0xff) == 0)
                  {
                    if ((usbBusSpeed == XUD_SPEED_HS) && (support_type != USB_SUPPORT_HS_ONLY))
                      {
                        cfgDescHdr[1] = USB_DESCTYPE_OTHER_SPEED;
                        cfgDescHdr[4] = totalInterfaces_fs;
                        cfgDescHdr[2] = cfgDescLen_fs & 0xff;
                        cfgDescHdr[3] = cfgDescLen_fs >> 8;
                        result = sendConfigDescriptor(XUD_SPEED_FS,
                                                      i_ep0, numClients,
                                                      numInterfaces_fs,
                                                      ep0_out, ep0_in,
                                                      sp.wLength,
                                                      null, 0);
                      }
                    else if (support_type != USB_SUPPORT_FS_ONLY)
                      {
                        cfgDescHdr[1] = USB_DESCTYPE_OTHER_SPEED;
                        cfgDescHdr[4] = cur_totalInterfaces_hs;
                        cfgDescHdr[2] = cur_cfgDescLen_hs & 0xff;
                        cfgDescHdr[3] = cur_cfgDescLen_hs >> 8;
                        result = sendConfigDescriptor(XUD_SPEED_HS,
                                                      i_ep0, numClients,
                                                      numInterfaces_hs,
                                                      ep0_out, ep0_in,
                                                      sp.wLength,
                                                      i_dfu, in_dfu_mode);
                      }

                    /* Not handled if cfgDescLength_hs == 0 and running in full-speed.
                     * This should result in a STALL as per USB spec */
                  }
                  break;

                  /* String Descriptor */
                case USB_DESCTYPE_STRING:
                  size_t datalength;

                  /* Set descriptor type */
                  buffer[1] = USB_DESCTYPE_STRING;

                  /* Send the string that was requested (low byte of wValue) */
                  /* First, generate valid descriptor from string */
                  unsigned stringID = sp.wValue & 0xff;

                  /* String table bounds check */
                  if (stringID >= strTableSize)
                    break;

                  if (stringID == 0) {
                    /* String 0 (LangIDs) is a special case*/
                    datalength = strlen(langStr);
                    buffer[0] = datalength + 2;
                    if( sp.wLength < datalength + 2 )
                      {
                        datalength = sp.wLength - 2;
                      }
                    for(int i = 0; i < datalength; i += 1 )
                      {
                        buffer[i+2] = langStr[i];
                      }
                  }
                  else unsafe {
                      const char * unsafe str;
                      switch (stringID) {
                      case 1:
                        str = vendorName;
                        break;
                      case 2:
                        str = productName;
                        break;
                      case 3:
                        str = configName;
                        break;
#pragma fallthrough
                      case 4:
                        if (!isnull(i_dfu)) {
                          str = dfuStr;
                          break;
                        }
                        else {
                          // fallthrough
                        }
                      default:
                        /* String is from one of the other interfaces */
                        size_t i = 0;
                        while (i != numClients - 1 && strTableOffsets[i+1] <= stringID)
                          i++;
                        i_ep0[i].get_string(stringID - strTableOffsets[i], str);
                        break;
                      }


                      datalength = strlen((const char *) str);
                      /* Datalength *= 2 due to unicode */
                      datalength <<= 1;

                      /* Set data length in descriptor (+2 due to 2 byte datalength)*/
                      buffer[0] = datalength + 2;

                      if(sp.wLength < datalength + 2)
                        {
                          datalength = sp.wLength - 2;
                        }
                      /* Add zero bytes for unicode.. */
                      for(int i = 0; i < datalength; i+=2)
                        {
                          buffer[i+2] = str[i>>1];
                          buffer[i+3] = 0;
                        }
                    }

                  /* Send back string */
                  result = XUD_DoGetRequest(ep0_out, ep0_in, buffer, datalength + 2, sp.wLength);
                  break;
                }
              break;
            } //switch(sp.bRequest)
          break;

          /* Direction: Host-to-device
           * Type: Standard
           * Recipient: Interface
           */
        case USB_BMREQ_H2D_STANDARD_INT:

          switch(sp.bRequest)
            {
              /* Standard Interface Request: SetInterface (USB Spec 9.4.10) */
            case USB_SET_INTERFACE:
              /* Note it is likely that a lot of devices will over-ride this request in their endpoint 0 code
               * For example, in an audio device this request would show the intent of the host to start streaming
               */
              if(sp.wLength == 0)
                {
                  int numInterfaces = 0;
                  if ((usbBusSpeed == XUD_SPEED_FS))
                    {
                      numInterfaces = totalInterfaces_fs;
                    }
                  else
                    {
                      numInterfaces = totalInterfaces_hs;
                    }

                  /* Record interface change */
                  if((sp.wIndex < numInterfaces) && (sp.wIndex < MAX_INTS))
                    {
                      /* Note here we assume the host has given us a valid Alternate setting
                       *  It is hard for use to have a generic check for this here (without parsing the descriptors)
                       * If more robust checking is required this should be done in the endpoint 0 implementation
                       */
                      g_interfaceAlt[sp.wIndex] = sp.wValue;
                    }

                  /* No data stage for this request, just do data stage */
                  result = XUD_DoSetRequestStatus(ep0_in);
                }
              break;
            }
          break;

          /* Direction: Device-to-host
           * Type: Standard
           * Recipient: Interface
           */
        case USB_BMREQ_D2H_STANDARD_INT:

          switch(sp.bRequest)
            {
            case USB_GET_INTERFACE:

              if((sp.wValue == 0) && (sp.wLength == 1))
                {
                  int numInterfaces = 0;

                  if ((usbBusSpeed == XUD_SPEED_FS)) {
                    numInterfaces = totalInterfaces_fs;
                  } else {
                    numInterfaces = totalInterfaces_hs;
                  }

                  if((sp.wIndex < numInterfaces) && (sp.wIndex < MAX_INTS)) {
                    buffer[0] = g_interfaceAlt[sp.wIndex];

                    result = XUD_DoGetRequest(ep0_out, ep0_in,  buffer, 1, sp.wLength);
                  }
                }
              break;
            }
          break;

          /* Direction: Host-to-device
           * Type: Standard
           * Recipient: Endpoint
           */
        case USB_BMREQ_H2D_STANDARD_EP:

          switch(sp.bRequest) {
            /* Standard Endpoint Request: SetFeature (USB Spec 9.4.9) */
          case USB_SET_FEATURE:

            if(sp.wLength == 0) {
              /* The only Endpoint feature selector is HALT (bit 0) see figure 9-6 */
              if(sp.wValue == USB_ENDPOINT_HALT) {
                /* Returns 0 on non-error */
                if(!SetEndpointHalt(sp.wIndex, 1)) {
                  result = XUD_DoSetRequestStatus(ep0_in);
                }
              }
            }
            break;

            /* Standard Endpoint Request: ClearFeature (USB Spec 9.4.1) */
          case USB_CLEAR_FEATURE:

            if(sp.wLength == 0) {
              /* The only feature selector for Endpoint is ENDPOINT_HALT */
              if(sp.wValue == USB_ENDPOINT_HALT) {
                /* Returns 0 on non-error */
                if(!SetEndpointHalt(sp.wIndex, 0)) {
                  result = XUD_DoSetRequestStatus(ep0_in);
                }
              }
            }
            break;
          }
          break;

          /* Direction: Host-to-device
           * Type: Standard
           * Recipient: Endpoint
           */
        case USB_BMREQ_D2H_STANDARD_EP:

          switch(sp.bRequest) {
            /* Standard Endpoint Request: GetStatus (USB Spec 9.4.5) */
          case USB_GET_STATUS:

            /* Note: The only status for an EP is Halt (bit 0) */
            /* Note: Without parsing the descriptors we don't know how many endpoints the device has... */
            if ((sp.wValue == 0) && (sp.wLength == 2)) {
              buffer[0] = 0;
              buffer[1] = 0;

              if( sp.wIndex & 0x80 ) {
                /* IN Endpoint */
                if((sp.wIndex&0x7f) < MAX_EPS) {
                  buffer[0] = ( g_epStatusIn[ sp.wIndex & 0x7F ] & 0xff );
                  buffer[1] = ( g_epStatusIn[ sp.wIndex & 0x7F ] >> 8 );
                  result = XUD_DoGetRequest(ep0_out, ep0_in, buffer,  2, sp.wLength);
                }
              }
              else
                {
                  /* OUT Endpoint */
                  if(sp.wIndex < MAX_EPS) {
                    buffer[0] = ( g_epStatusOut[ sp.wIndex ] & 0xff );
                    buffer[1] = ( g_epStatusOut[ sp.wIndex ] >> 8 );
                    result = XUD_DoGetRequest(ep0_out, ep0_in, buffer,  2, sp.wLength);
                  }
                }
            }
            break;
          }
          break;
        }

      /* If we get this far we did not handle request - Protocol Stall Secion 8.4.5 of USB 2.0 spec
       * Detailed in Section 8.5.3. Protocol stall is unique to control pipes.
       * Protocol stall differs from functional stall in meaning and duration.
       * A protocol STALL is returned during the Data or Status stage of a control
       * transfer, and the STALL condition terminates at the beginning of the
       * next control transfer (Setup). The remainder of this section refers to
       * the general case of a functional stall */
      if (result == XUD_RES_ERR) {
        debug_printf("Unhandled request.\n");
        USB_DebugSetupPacket(sp);
        XUD_SetStall(ep0_out);
        XUD_SetStall(ep0_in);
      }

      /* USB bus reset detected, reset EP and get new bus speed */
      if(result == XUD_RES_RST) {
        usbBusSpeed = XUD_ResetEndpoint(ep0_out, ep0_in);
        afterReset = 1;
      }
      XUD_SetReady_Out(ep0_out, buffer);
      break;
    }
  }
}

#if 0
void usb_endpoint0(chanend chan_ep0_out, chanend chan_ep0_in,
                   enum ep0_support_type support_type,
                   const char *vendorName,
                   unsigned vendorId,
                   const char *productName,
                   unsigned productId,
                   unsigned productId_fs,
                   unsigned majorVersion,
                   unsigned minorVersion,
                   unsigned subMinorVersion,
                   client usb_dfu_callback_if ?i_dfu,
                   client usb_ep0_callback_if i_ep0[numClients],
                   static const size_t numClients)
{
  size_t strTableOffsets[numClients];
  size_t numInterfaces_fs[numClients], numInterfaces_hs[numClients];
  usb_endpoint0_aux(chan_ep0_out, chan_ep0_in,
                    support_type,
                    vendorName,
                    vendorId,
                    productName,
                    productId,
                    productId_fs,
                    majorVersion,
                    minorVersion,
                    subMinorVersion,
                    i_dfu,
                    i_ep0,
                    numClients,
                    strTableOffsets,
                    numInterfaces_fs,
                    numInterfaces_hs);
}
#endif
