/*
 * gdc.h
 *
 *  Created on: Feb 24, 2020
 *      Author: david
 */


#ifndef GDC_H_
#define GDC_H_

// function prototypes
void gdc(chanend c_disp, chanend c_gdc, chanend c_bell);
void gdcDisplay(chanend c_disp);

enum // command decode
{
    CMD_RESET,
    CMD_SYNC,
    CMD_VSYNC,
    CMD_CCHAR,
    CMD_START,
    CMD_BCTRL,
    CMD_ZOOM,
    CMD_CURS,
    CMD_PRAM,
    CMD_PITCH,
    CMD_WDAT,
    CMD_MASK,
    CMD_FIGS,
    CMD_FIGD,
    CMD_GCHRD,
    CMD_RDAT,
    CMD_CURD,
    CMD_LPRD,
    CMD_DMAR,
    CMD_DMAW,
    CMD_TERM
};

#define NULL         0x00
#define BELL         0x07
#define BACKSPACE    0x08
#define CURSOR_R     0x09
#define LINEFEED     0x0A
#define CURSOR_U     0x0B
#define CLEARSCREEN  0x0C
#define RETURN       0x0D
#define MOVE_CURSOR  0x0E
#define HOME         0x0F
#define SCREEN_ON    0x10
#define SCREEN_OFF   0x11
#define CURSOR_ON    0x12
#define CURSOR_OFF   0x13
#define CURSOR_TYPE1 0x14
#define CURSOR_TYPE2 0x15
#define INVERT_ON    0x16
#define INVERT_OFF   0x17
#define CLEARTO_EOL  0x18
#define CLEARTO_EOS  0x19
#define CLEAR_LINE   0x1A

#define COMMAND_RESET  0x00
#define COMMAND_SYNC   0x0E
#define COMMAND_VSYNC  0x6E
#define COMMAND_CCHAR  0x4B
#define COMMAND_START  0x6B
#define COMMAND_BCTRL  0x0C
#define COMMAND_ZOOM   0x46
#define COMMAND_CURS   0x49
#define COMMAND_PRAM   0x70
#define COMMAND_PITCH  0x47
#define COMMAND_WDAT   0x20
#define COMMAND_MASK   0x4A
#define COMMAND_FIGS   0x4C
#define COMMAND_FIGD   0x6C
#define COMMAND_GCHRD  0x68
#define COMMAND_RDAT   0xA0
#define COMMAND_CURD   0xE0
#define COMMAND_DMAR   0xA4
#define COMMAND_DMAW   0x24
#define COMMAND_TERM   0xD0

// Drawing modes
#define REPLACE     0
#define COMPLEMENT  1
#define RESET       2
#define SET         3

// status register offset and bits
#define STATUS_REG           (H_ACTIVE*(V_ACTIVE + V_ACTIVE/2)/32)
#define FIFO_FULL            0x02
#define FIFO_EMPTY           0x04
#define DRAWING_IN_PROGRESS  0x08
#define DMA_EXECUTE          0x10
#define VSYNC_ACTIVE         0x20

// display defines
#define DISPLAY_ON  0xFFFFFFFF;
#define DISPLAY_OFF        0x0;
#define INTERLACE          0x0;
#define REPEAT_FIELD       0x1;

// Horizontal timings (pixels)
#define H_FRONT_PORCH     32
#define H_SYNC            32
#define H_BACK_PORCH      64
#define H_ACTIVE         768

#define HBP_WORDS        H_BACK_PORCH/32
#define HAL_WORDS        H_ACTIVE/32

// Vertical timings (lines)
#define V_FRONT_PORCH     20
#define V_SYNC             3
#define V_BACK_PORCH      28
#define V_ACTIVE         576

#endif /* GDC_H_ */
