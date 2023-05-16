// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <usb.h>
#include <xud.h>
#include <xassert.h>
#include <usb_endpoint0.h>
/* Experimental features.
   The features in this file are **experimental**,
   not supported and not known to work if enabled. Any guarantees of
   the robustness of the component made by XMOS do not hold if these features
   are used.
*/

// Default Command requests (from Spec)
#define DFU_DETACH 0
#define DFU_DNLOAD 1
#define DFU_UPLOAD 2
#define DFU_GETSTATUS 3
#define DFU_CLRSTATUS 4
#define DFU_GETSTATE 5
#define DFU_ABORT 6

// XMOS Alternate Setting Command Requests
#define XMOS_DFU_RESETDEVICE   0xf0
#define XMOS_DFU_REVERTFACTORY 0xf1
#define XMOS_DFU_RESETINTODFU  0xf2
#define XMOS_DFU_RESETFROMDFU  0xf3
#define XMOS_DFU_SELECTIMAGE   0xf4
#define XMOS_DFU_SAVESTATE     0xf5
#define XMOS_DFU_RESTORESTATE  0xf6

// DFU States
#define STATE_APP_IDLE                  0x00
#define STATE_APP_DETACH                0x01
#define STATE_DFU_IDLE                  0x02
#define STATE_DFU_DOWNLOAD_SYNC         0x03
#define STATE_DFU_DOWNLOAD_BUSY         0x04
#define STATE_DFU_DOWNLOAD_IDLE         0x05
#define STATE_DFU_MANIFEST_SYNC         0x06
#define STATE_DFU_MANIFEST              0x07
#define STATE_DFU_MANIFEST_WAIT_RESET   0x08
#define STATE_DFU_UPLOAD_IDLE           0x09
#define STATE_DFU_ERROR                 0x0a

// DFU error conditions
#define DFU_OK              0x00 // No error condition is present.
#define DFU_errTARGET       0x01 // File is not targeted for use by this device.
#define DFU_errFILE         0x02 // File is for this device but fails some vendor-specific verification test.
#define DFU_errWRITE        0x03 // Device is unable to write memory.
#define DFU_errERASE        0x04 // Memory erase function failed.
#define DFU_errCHECK_ERASED 0x05 // Memory erase check failed.
#define DFU_errPROG         0x06 // Program memory function failed.
#define DFU_errVERIFY       0x07 // Programmed memory failed verification.
#define DFU_errADDRESS      0x08 // Cannot program memory due to received address that is out of range.
#define DFU_errNOTDONE      0x09 // Received DFU_DNLOAD with wLength = 0, but device does not think it has all of the data yet.
#define DFU_errFIRMWARE     0x0A // Devices firmware is corrupt. It cannot return to run-time (non-DFU) operations
#define DFU_errVENDOR       0x0B // iString indicates a vendor-specific error.
#define DFU_errUSBR         0x0C // Device detected unexpected USB reset signaling.
#define DFU_errPOR          0x0D // Device detected unexpected power on reset.
#define DFU_errUNKNOWN      0x0E // Something went wrong, but the device does not know what it was
#define DFU_errSTALLEDPKT   0x0F // Device stalled an unexpected request.


extern int DFU_reset_override;

static int DFU_state;
static unsigned DFU_timeout;

int dfu_requires_timeout_check(void) {
  return (DFU_state == STATE_APP_DETACH);
}

unsigned dfu_get_timeout(void) {
  return DFU_timeout;
}

int dfu_reset_state(void)
{
  if (DFU_reset_override == 0x11042011) {
    DFU_state = STATE_DFU_IDLE;
    return 1;
  }

  switch(DFU_state) {
  case STATE_APP_DETACH:
    timer tmr;
    unsigned now;
    tmr :> now;
    if ((signed) now - (signed) DFU_timeout > 0) {
      // Reset happened after timeout, so we do *not* go
      // into DFU mode
      DFU_state = STATE_APP_IDLE;
      return 0;
    } else {
      DFU_state = STATE_DFU_IDLE;
      return 1;
    }
    break;

  case STATE_DFU_IDLE:
  case STATE_APP_IDLE:
  case STATE_DFU_DOWNLOAD_SYNC:
  case STATE_DFU_DOWNLOAD_BUSY:
  case STATE_DFU_DOWNLOAD_IDLE:
  case STATE_DFU_MANIFEST_SYNC:
  case STATE_DFU_MANIFEST:
  case STATE_DFU_MANIFEST_WAIT_RESET:
  case STATE_DFU_UPLOAD_IDLE:
  case STATE_DFU_ERROR:
    DFU_state = STATE_APP_IDLE;
    return 0;

  default:
    DFU_state = STATE_DFU_ERROR;
    break;
  }

  return 0;
}

XUD_Result_t handle_DFU_device_requests(XUD_ep ep0_out, XUD_ep ep0_in,
                               USB_SetupPacket_t sp,
                               client usb_dfu_callback_if i_dfu,
                               int &reset_device)
{
  unsigned int data_buffer_len = 0;
  unsigned int data_buffer[17];

  if(sp.bmRequestType.Direction == USB_BM_REQTYPE_DIRECTION_H2D) {
    // Host to device
    if (sp.wLength) {
      XUD_Result_t result;
      result = XUD_GetBuffer(ep0_out, (char *) data_buffer, data_buffer_len);
      if (result != XUD_RES_OKAY)
        return result;
    }
  }

  switch (sp.bRequest) {
  case DFU_DETACH:
    if (DFU_state != STATE_APP_IDLE) {
      DFU_state = STATE_DFU_ERROR;
      return XUD_DoSetRequestStatus(ep0_in);
    }
    unsigned timeout = sp.wValue; // timeout in milliseconds
    timer tmr;
    unsigned now;
    tmr :> now;
    DFU_state = STATE_APP_DETACH;
    DFU_timeout = now + (timeout * XS1_TIMER_MHZ/1000);
    return XUD_DoSetRequestStatus(ep0_in);

  case DFU_DNLOAD:
    unsigned request_len = sp.wLength;
    unsigned block_num = sp.wValue;

    if (DFU_state == STATE_DFU_IDLE) {
      // Entering a firmware upgrage
      if (request_len == 0) {
        DFU_state = STATE_DFU_ERROR;
      }
      else {
        i_dfu.start_image_write();
        i_dfu.write_block((char *) data_buffer, data_buffer_len);
        DFU_state = STATE_DFU_DOWNLOAD_SYNC;
      }
    } else if (DFU_state == STATE_DFU_DOWNLOAD_IDLE) {
      if (request_len == 0) {
        // Finish a firmware upgrade
        i_dfu.end_image_write();
        DFU_state = STATE_DFU_MANIFEST_SYNC;
      }  else {
        i_dfu.write_block((char *) data_buffer, data_buffer_len);
        DFU_state = STATE_DFU_DOWNLOAD_SYNC;
      }
    } else {
      DFU_state = STATE_DFU_ERROR;
    }
    return XUD_DoSetRequestStatus(ep0_in);

  case DFU_UPLOAD:
    unsigned request_len = sp.wLength;
    unsigned block_num = sp.wValue;

    if (DFU_state != STATE_DFU_UPLOAD_IDLE &&
        DFU_state != STATE_DFU_IDLE) {
      DFU_state = STATE_DFU_ERROR;
      return XUD_DoSetRequestStatus(ep0_in);
    }

    if (DFU_state == STATE_DFU_IDLE) {
      // Entering a firmware read
      i_dfu.start_image_read();
    }

    size_t len = i_dfu.read_block((char *) data_buffer);
    DFU_state = STATE_DFU_UPLOAD_IDLE;
    return XUD_DoGetRequest(ep0_out, ep0_in, (char *) data_buffer,
                            len, len);

  case DFU_GETSTATUS:
    uint8_t * buf = (uint8_t *) data_buffer;
    // Polling for status can move the DFU state on
    switch (DFU_state) {
    case STATE_DFU_MANIFEST:
    case STATE_DFU_MANIFEST_WAIT_RESET:
      DFU_state = STATE_DFU_ERROR;
      break;
    case STATE_DFU_DOWNLOAD_BUSY:
      // If download completes -> DFU_DOWNLOAD_SYNC
      // Currently all transactions are synchronous so no busy state
      break;
    case STATE_DFU_DOWNLOAD_SYNC:
      DFU_state = STATE_DFU_DOWNLOAD_IDLE;
      break;
    case STATE_DFU_MANIFEST_SYNC:
      // Check if complete here
      DFU_state = STATE_DFU_IDLE;
      break;
    default:
      break;
    }
    buf[0] = DFU_OK;              // bStatus
    buf[1] = 0;
    buf[2] = 0;
    buf[3] = 0; // bwPollTimeout
    buf[4] = DFU_state;           // bState
    buf[5] = 0;                   // iString
    return XUD_DoGetRequest(ep0_out, ep0_in, (char *) data_buffer, 6, 6);

  case DFU_CLRSTATUS:
    if (DFU_state == STATE_DFU_ERROR) {
      DFU_state = STATE_DFU_IDLE;
    }
    else {
      DFU_state = STATE_DFU_ERROR;
    }
    return XUD_DoSetRequestStatus(ep0_in);

  case DFU_GETSTATE:
    uint8_t * buf = (uint8_t *) data_buffer;
    buf[0] = DFU_state;
    return XUD_DoGetRequest(ep0_out, ep0_in, (char *) data_buffer, 1, 1);

  case DFU_ABORT:
    DFU_state = STATE_DFU_IDLE;
    return XUD_DoSetRequestStatus(ep0_in);

    /* XMOS Custom DFU requests */
  case XMOS_DFU_RESETDEVICE:
    reset_device = 1;
    return XUD_DoSetRequestStatus(ep0_in);

  case XMOS_DFU_REVERTFACTORY:
    i_dfu.revert_to_factory_image();
    return XUD_DoSetRequestStatus(ep0_in);

  case XMOS_DFU_RESETINTODFU:
    reset_device = 1;
    DFU_reset_override = 0x11042011;
    return XUD_DoSetRequestStatus(ep0_in);

  case XMOS_DFU_RESETFROMDFU:
    reset_device = 1;
    DFU_reset_override = 0;
    return XUD_DoSetRequestStatus(ep0_in);

  case XMOS_DFU_SELECTIMAGE:
    i_dfu.select_image(sp.wValue);
    return XUD_DoSetRequestStatus(ep0_in);

  case XMOS_DFU_SAVESTATE:
    /* Save passed state to flash */
    return XUD_DoSetRequestStatus(ep0_in);

  case XMOS_DFU_RESTORESTATE:
    /* Restore saved state from flash */
    return XUD_DoSetRequestStatus(ep0_in);

  default:
    break;
  }

  return XUD_RES_ERR;
}
