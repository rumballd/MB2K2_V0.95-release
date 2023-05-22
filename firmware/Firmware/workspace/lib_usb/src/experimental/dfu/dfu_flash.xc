// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <usb.h>
#include <flash.h>
#include <string.h>
#include <dfu.h>
/* Experimental features.
   The features in this file are **experimental**,
   not supported and not known to work if enabled. Any guarantees of
   the robustness of the component made by XMOS do not hold if these features
   are used.
*/

#ifdef USB_ENABLE_DFU_FLASH

[[distributable]]
void dfu_flash(server usb_dfu_callback_if dfu,
               in buffered port:8 p_spi_miso,
               out port p_spi_ss,
               out port p_spi_clk,
               out buffered port:8 p_spi_mosi,
               clock clk_spi,
               const fl_DeviceSpec spec[n],
               size_t n,
               size_t maxsize,
               static const size_t pagesize)
{
  unsigned fakeports[5];
  fl_SPIPorts * unsafe ports;
  char buffer[pagesize];
  fl_BootImageInfo b;
  size_t cur_buffer_fill = 0;
  // This function takes individual ports and the following code
  // wraps these ports into a struct.
  unsafe {
    fakeports[0] = *((unsigned * unsafe) &p_spi_miso);
    fakeports[1] = *((unsigned * unsafe) &p_spi_ss);
    fakeports[2] = *((unsigned * unsafe) &p_spi_clk);
    fakeports[3] = *((unsigned * unsafe) &p_spi_mosi);
    fakeports[4] = *((unsigned * unsafe) &clk_spi);
    ports = (fl_SPIPorts * unsafe) &fakeports;
  }

  while (1) {
    select {
    case dfu.start_image_write():
      unsafe {
        fl_connectToDevice(*ports, spec, n);
      }
      fl_getFactoryImage(b);
      fl_getNextBootImage(b);
      while (fl_startImageReplace(b, maxsize));
      cur_buffer_fill = 0;
      break;

    case dfu.write_block(unsigned char * data, size_t len):
      while (len != 0) {
        size_t space_left = pagesize - cur_buffer_fill;
        size_t copy_len = len > space_left ? space_left : len;
        memcpy(&buffer[cur_buffer_fill], data, copy_len);
        cur_buffer_fill += copy_len;
        len -= copy_len;
        if (cur_buffer_fill == pagesize) {
          fl_writeImagePage(buffer);
          cur_buffer_fill = 0;
        }
      }
      break;

    case dfu.end_image_write():
      if (cur_buffer_fill != 0) {
        memset(&buffer[cur_buffer_fill], pagesize - cur_buffer_fill, 0);
        fl_writeImagePage(buffer);
      }
      fl_endWriteImage();
      break;

    case dfu.start_image_read():
      break;

    case dfu.read_block(unsigned char * data) -> size_t len:
      break;

    case dfu.revert_to_factory_image():
      break;

    case dfu.select_image(unsigned id):
      break;

    }
  }
}

#endif