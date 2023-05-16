/*
* gdc.xc
*
*  Created on: Feb 23, 2020
*      Author: david
*/

#include <syscall.h>
#include <platform.h>
#include <xs1.h>
#include <xclib.h>
#include "debug_print.h"

#include "gdc.h"
#include "char_set.h"


// ports
on tile[0] : buffered out port:32 p_pix = XS1_PORT_1M;
on tile[0] : buffered out port:32 p_hs  = XS1_PORT_1N;
on tile[0] : out port p_vs  = XS1_PORT_1O;

// clock blocks
on tile[0] : clock pixel_clk = XS1_CLKBLK_2;

// globals
// graphics RAM + text RAM + status reg
// interpreted as 16 bits words for engine and 32 bits ints for display
unsigned short vram[((H_ACTIVE*(V_ACTIVE + V_ACTIVE/2)/32) + 1) * 2] = {
#include "bootImage.h"
};


//output a blank line ( stream 32 bit words to avoid jitter issues with port timers)
void BlankLine() {

   unsigned i;

   //horizontal front porch
   p_hs  <: 0xFFFFFFFF;
   p_pix <: 0x00000000;

   //horizontal sync
   p_hs  <: 0x00000000;
   p_pix <: 0x00000000;

   //horizontal back porch + active line
#pragma loop unroll
   for (i=0; i<(HBP_WORDS + HAL_WORDS); i++ ) {
       p_hs  <: 0xFFFFFFFF;
       p_pix <: 0x00000000;
   }
}

// display thread
#pragma unsafe arrays
void gdcDisplay(chanend c_disp) {

   unsigned l, i, h;
   unsigned* unsafe vram;

   unsigned startPart1, startPart2, lengthPart1, lengthPart2;
   unsigned blank, repeatLine;

   // outputs are all clocked at pixel rate
   configure_clock_rate(pixel_clk, 125, 4); // pixel clock = 31.25MHz (1/4 of 125MHz system clock)
   configure_out_port(p_pix, pixel_clk, 0);
   configure_out_port(p_hs,  pixel_clk, 1);
   configure_out_port(p_vs,  pixel_clk, 1);
   start_clock(pixel_clk);

   unsafe {
       c_disp :> vram; // get vram pointer from engine thread

       // pick up initial parameter set
       c_disp :> blank;       // display off/on
       c_disp :> repeatLine;  // display mode ('interlaced'/'repeat field'
       c_disp :> startPart1;  // partition 1 start address
       c_disp :> startPart2;  // partition 2 start address
       c_disp :> lengthPart1; // partition 1 length (lines)
       c_disp :> lengthPart2; // partition 2 length (lines)

       startPart1 /= 2; // adjust for 16bit -> 32bit addressing
       startPart2 /= 2;
       if(repeatLine) { // double partition lengths if repeatline
           lengthPart1 *= 2;
           lengthPart2 *= 2;
       }

   while(1) { // display loop

       select {

           // pick up any parameter changes
           case c_disp :> blank :
                c_disp :> repeatLine;
                c_disp :> startPart1;
                c_disp :> startPart2;
                c_disp :> lengthPart1;
                c_disp :> lengthPart2;

                startPart1 /= 2; // adjust for 16bit -> 32bit addressing
                startPart2 /= 2;
                if(repeatLine) { // double partition lengths if repeatline
                    lengthPart1 *= 2;
                    lengthPart2 *= 2;
                }
           break;

           default : // continue with display

     // vertical front porch
           for(l=0; l < V_FRONT_PORCH; l++) {
               BlankLine();
           }
     // vertical sync
           p_vs <: 0;
           vram[STATUS_REG] |= VSYNC_ACTIVE; // set VS flag in status reg
           for(l=0; l < V_SYNC; l++) {
               BlankLine();
           }
           p_vs <: 1;
           vram[STATUS_REG] &= ~VSYNC_ACTIVE; // clr VS flag in status reg
     // vertical back porch
           for(l=0; l < V_BACK_PORCH; l++) {
               BlankLine();
           }

     // partition 1
           if (lengthPart1 != 0) {

               h = startPart1;

               for(l=0; l < lengthPart1; l++) {

     // horizontal front porch
                   p_hs  <: 0xFFFFFFFF;
                   p_pix <: 0x00000000;

     // horizontal sync
                   p_hs  <: 0x00000000;
                   p_pix <: 0x00000000;

     // horizontal back porch
                   #pragma loop unroll
                   for (i=0; i<HBP_WORDS; i++ ) {
                       p_hs  <: 0xFFFFFFFF;
                       p_pix <: 0x00000000;
                   }

     // active line
                   #pragma loop unroll
                   for (i=0; i<HAL_WORDS; i++ ) {
                       p_hs  <: 0xFFFFFFFF;
                       p_pix <: bitrev(((vram[h] & 0x0000FFFF) << 16) | ((vram[h] & 0xFFFF0000) >> 16)) & blank;
                       h++;
                   }

     // if repeat field at end of even lines step pointer back a line
                   if ((repeatLine) && ((l/2)*2 == l)) {
                       h -= HAL_WORDS;
                   }

               }// of active lines for

           }// of partition 1

     // partition 2
             if (lengthPart2 != 0) {

                 h = startPart2;

                 for(l=0; l < lengthPart2; l++) {

     // horizontal front porch
                     p_hs  <: 0xFFFFFFFF;
                     p_pix <: 0x00000000;

     // horizontal sync
                     p_hs  <: 0x00000000;
                     p_pix <: 0x00000000;

     // horizontal back porch
                     #pragma loop unroll
                     for (i=0; i<HBP_WORDS; i++ ) {
                         p_hs  <: 0xFFFFFFFF;
                         p_pix <: 0x00000000;
                     }

     // active line
                     #pragma loop unroll
                     for (i=0; i<HAL_WORDS; i++ ) {
                         p_hs  <: 0xFFFFFFFF;
                         p_pix <: bitrev(((vram[h] & 0x0000FFFF) << 16) | ((vram[h] & 0xFFFF0000) >> 16)) & blank;
                         h++;
                     }

                     // if repeat field at end of even lines step pointer back a line
                     if ((repeatLine) && ((l/2)*2 == l)) {
                         h -= HAL_WORDS;
                     }
                 }// of active lines for

           }// of partition 2

           break;

       }// of select

   }/// of while

   }// of unsafe region

}

// get a command/parameter
// there is no explicit 'fifo' as this is inherent in the Xmos channel architecture
unsigned popFIFO(chanend c_gdc, unsigned* vram) {

    unsigned cmd;

    cmd = 0xFF;

    while (cmd == 0xFF) {

        c_gdc :> cmd; //wait on access

        switch (cmd & 0x80000001) {

        case (0x00000000) : // status reg -> 6809
            cmd = vram[STATUS_REG] | FIFO_EMPTY & ~FIFO_FULL; // FIFO is always empty and never full
            c_gdc <: cmd & 0xFF;
            cmd = 0xFF; // mark as not a command
            break;

        case (0x80000001) : // 6809 -> command
            cmd = ((cmd & 0x00FF0000) >> 16);
            break;

        case (0x80000000) : // 6809 -> parameter
            cmd = ((cmd & 0x00FF0000) >> 16) | 0x00000100; // set bit 8 for parameter
            break;

        case (0x00000001) : // command reg -> 6809
            c_gdc <: 0;
            break;

        default:
        break;

        }// of switch

    }//of while

    //debug_printf("popFifo -> %0x\n", cmd);

    return cmd & 0x1FF;
}

// draw the character at row/col
#pragma unsafe arrays
void drawChar( unsigned scrollLines, unsigned row, unsigned col, unsigned attribute, unsigned cmd, unsigned cursor) {

    unsigned offset, cy, bitMask, charMask;
    unsigned short eAD, dAD;

    // get eAD and dAD from row/col
    eAD = 0x6C00 + (row * 48 * charSet[5]) + ((col * charSet[4]) / 16) + (scrollLines * 48);
    if (eAD >= 0xA200) {
        eAD -= (24 * 12 * 48);
    }
    dAD = ((col * charSet[4])) - (((col * charSet[4]) / 16) * 16);

    // point to the start of the char pattern
    offset = (cmd - 0x20) * charSet[3] + 8; //  ASCCI * char rows + attribute table offset

    // draw the char
    for(cy=0; cy<charSet[3]; cy++) {

        bitMask = 0xFF000000;
        bitMask >>= dAD;

        charMask = charSet[offset + cy] << 24;
        if (attribute) {
            charMask ^= 0xFF000000; // invert the pattern
        }

        charMask >>= dAD;

        if (cursor) { // invert text at cursor position

            vram[eAD]   = vram[eAD]    ^ (charMask >> 16);
            vram[eAD+1] = vram[eAD+1]  ^  charMask; // overflow into next word

        } else { // normal text

            vram[eAD]   = (vram[eAD]   & (~bitMask >> 16)) | (charMask >> 16);
            vram[eAD+1] = (vram[eAD+1] &  ~bitMask)        |  charMask; // overflow into next word
        }
            eAD+= 48;

    }// of for
}

short abs(short value) {
  if (value < 0)
    return -value;
  return value;
}

// interface and drawing engine thread
#pragma unsafe arrays
void gdc(chanend c_disp, chanend c_gdc, chanend c_bell) {

   unsafe {

   unsigned i, j, time, storedCommand, cmd, command, pRAMindex;
   unsigned blank, repeatLine, startPart1, startPart2, lengthPart1, lengthPart2;
   unsigned short dAD, eAD, mask, eADInc;
   short DC, D, D2, D1, DM;
   short x, y, dX, dY, endX, endY, dI, dD;
   unsigned direction, figureType, rmwMode, xferType, xferData;
   char pRAM[16];
   unsigned offset, bitMask, charMask, cx, cy;
   timer tmr;

   unsigned scrollLines = 0, row = 0, col = 0, attribute = 0;
   char escape = 0, cursor = 0, cursorType = 0x80;

   // send vram pointer and initial display parameters to the display thread
   c_disp <:(unsigned* unsafe) &vram;

   // clear the text area
   for(i=(576*768/16); i < (576*768*3/2/16); i++) {
       vram[i] = 0xFFFF;
   }

   // wait for the initial reset command
       while (popFIFO(c_gdc, (unsigned*)&vram) != 0) {};
// ignore next 8 video timing parameters
       for (i=0; i<8; i++) {
           popFIFO(c_gdc, (unsigned*)&vram);
       }
       vram[STATUS_REG * 2] = 0; // init status reg
       // set up initial graphics partition
       c_disp <: DISPLAY_ON;
       blank = DISPLAY_ON;
       c_disp <: INTERLACE;
       repeatLine = INTERLACE;
       c_disp <: 0x00000000;
       startPart1 = 0x00000000;
       c_disp <: 0x00003600;
       startPart2 = 0x00003600;
       c_disp <: 576;
       lengthPart1 = 576;
       c_disp <: 0;
       lengthPart2 = 0;

       storedCommand = 0;

// command process loop
       while(1) {

           if (storedCommand) { // cmd already has the nect command
               storedCommand = 0;
           } else {
               cmd =  popFIFO(c_gdc, (unsigned*)&vram);
           }

           //debug_printf("cmd = %0x\n", cmd);

// convert mixed command/parameters to base command
           switch (cmd) {

              case COMMAND_RESET: command = CMD_RESET; break;
              case COMMAND_CCHAR: command = CMD_CCHAR; break;
              case COMMAND_START: command = CMD_START; break;
              case COMMAND_ZOOM:  command = CMD_ZOOM;  break;
              case COMMAND_CURS:  command = CMD_CURS;  break;
              case COMMAND_PITCH: command = CMD_PITCH; break;
              case COMMAND_MASK:  command = CMD_MASK;  break;
              case COMMAND_FIGS:  command = CMD_FIGS;  break;
              case COMMAND_FIGD:  command = CMD_FIGD;  break;
              case COMMAND_GCHRD: command = CMD_GCHRD; break;
              case COMMAND_CURD:  command = CMD_CURD;  break;


              default:
                  switch (cmd & 0xFE) {

                  case COMMAND_SYNC:  command = CMD_SYNC;  break;
                  case COMMAND_VSYNC: command = CMD_VSYNC; break;
                  case COMMAND_BCTRL: command = CMD_BCTRL; break;

                  default:
                      switch (cmd & 0xF0) {
                      case COMMAND_PRAM: command = CMD_PRAM; break;
                      case COMMAND_TERM: command = CMD_TERM; break; // extra command not in the uPD7220A for faster terminal emulation

                      default:
                          switch (cmd & 0xE4) {
                          case COMMAND_WDAT: command = CMD_WDAT; break;
                          case COMMAND_RDAT: command = CMD_RDAT; break;
                          case COMMAND_DMAR: command = CMD_DMAR; break;
                          case COMMAND_DMAW: command = CMD_DMAW; break;
                          }
                      }
                  }
              }

// process command
           switch (command) {

           case CMD_VSYNC : // ignore

               break;

           case CMD_PITCH : // ignore

               popFIFO(c_gdc, (unsigned*)&vram); // dump param

               break;

           case CMD_CCHAR : // ignore

               popFIFO(c_gdc, (unsigned*)&vram); // dump params
               popFIFO(c_gdc, (unsigned*)&vram);
               popFIFO(c_gdc, (unsigned*)&vram);

               break;

           case CMD_ZOOM : // ignore

               popFIFO(c_gdc, (unsigned*)&vram); // dump params

               break;

           case CMD_START : // start display

               blank = DISPLAY_ON;
               c_disp <: blank;
               c_disp <: repeatLine;
               c_disp <: startPart1;
               c_disp <: startPart2;
               c_disp <: lengthPart1;
               c_disp <: lengthPart2;

               break;

           case CMD_BCTRL : // enable/disable display

               if (cmd & 0x01) {
                   blank = DISPLAY_ON;
               } else {
                   blank = DISPLAY_OFF;
               }
               c_disp <: blank;
               c_disp <: repeatLine;
               c_disp <: startPart1;
               c_disp <: startPart2;
               c_disp <: lengthPart1;
               c_disp <: lengthPart2;

               break;

           case CMD_PRAM : // load parameter ram

               pRAMindex = cmd & 0x0F; // offset into the PRAM, 0 for partition data, 8 -> 15 for patterns

               if (pRAMindex == 0) { // this is a display partition change fixed at 8 bytes

                   for(i=0; i<8; i++) {
                       pRAM[i] = popFIFO(c_gdc, (unsigned*)&vram) & 0xFF;
                   }

                   startPart1  = 0;
                   startPart1 = (pRAM[0] | (pRAM[1] << 8));
                   startPart1 -= 0x5E00; // subtract the MB2 ramdisk offset (ramdisk is not in the gdc ram on the MB2K2)
                   lengthPart1 = 0;
                   lengthPart1 = (((pRAM[2] >> 4) & 0xF) | (pRAM[3] << 4)) & 0x3FF;

                   startPart2  = 0;
                   startPart2 = (pRAM[4] | (pRAM[5] << 8));
                   startPart2 -= 0x5E00;
                   lengthPart2 = 0;
                   lengthPart2 = (((pRAM[6] >> 4) & 0xF) | (pRAM[7] << 4)) & 0x3FF;

                   c_disp <: blank;
                   c_disp <: repeatLine;
                   c_disp <: startPart1;
                   c_disp <: startPart2;
                   c_disp <: lengthPart1;
                   c_disp <: lengthPart2;

               } else {// this will be a char definition and of variable size

               for(i=pRAMindex; i < 16; i++) {

                   cmd = popFIFO(c_gdc, (unsigned*)&vram);
                   if (cmd & 0x100) { // parameter bit set?
                       pRAM[i] = cmd & 0xFF;
                   } else { // this is a command
                       storedCommand = 1;
                       break;
                      }// of if

                   }// of for

               }/// of else

               break;

          case CMD_SYNC : // set display mode

              repeatLine = INTERLACE;
              if((popFIFO(c_gdc, (unsigned*)&vram) & 0x09) == 0) {
                  repeatLine = REPEAT_FIELD;
              }
              c_disp <: blank;
              c_disp <: repeatLine;
              c_disp <: startPart1;
              c_disp <: startPart2;
              c_disp <: lengthPart1;
              c_disp <: lengthPart2;

              break;

          case CMD_CURS : // set curser address eAD/dAD

              //debug_printf("CMD_CURS\n");

              eAD = popFIFO(c_gdc, (unsigned*)&vram) & 0xFF;
              dAD = popFIFO(c_gdc, (unsigned*)&vram) & 0xFF;

              eAD = eAD | (dAD << 8);
              eAD -= 0x5E00; // subtract the MB2 ramdisk offset (ramdisk is not in the gdc ram on the MB2K2)
              dAD = (popFIFO(c_gdc, (unsigned*)&vram) & 0xF0) >> 4;

              //debug_printf("eAD =  %0x  dAD = %0x\n", eAD, dAD);

              break;

          case CMD_MASK : // set mask reg

             mask = popFIFO(c_gdc, (unsigned*)&vram) & 0xFF;
              mask = mask | ((popFIFO(c_gdc, (unsigned*)&vram) & 0xFF) << 8);

              break;

          case CMD_FIGS : // set figure drawing parameters

              //debug_printf("CMD_FIGS\n");

              DC = 0; // as parameter set length is variable, set default values
              D = 8;
              D2 = 8;
              D1 = -1;
              DM = -1;

              cmd = popFIFO(c_gdc, (unsigned*)&vram) & 0xFF;
              direction = cmd & 0x07; // drawing direction
              figureType = (cmd & 0xF8) >> 3; // figure drawing type
              //debug_printf("direction = %0x  figureType = %0x\n", direction, figureType);

              //DC
              cmd = popFIFO(c_gdc, (unsigned*)&vram);
              if (cmd & 0x100) { // parameter bit set?
                  DC = cmd & 0xFF;
                  DC = DC | ((popFIFO(c_gdc, (unsigned*)&vram) & 0xFF) << 8);
              } else { // this is a command
                  storedCommand = 1;
                  break;
              }
              //debug_printf("DC = %0x\n", DC);

              //D
              cmd = popFIFO(c_gdc, (unsigned*)&vram);
              if (cmd & 0x100) { // parameter bit set?
                  D = cmd & 0xFF;
                  D = D | ((popFIFO(c_gdc, (unsigned*)&vram) & 0xFF) << 8);
              } else { // this is a command
                  storedCommand = 1;
                  break;
              }
              //debug_printf("D = %0x\n", D);

              //D2
              cmd = popFIFO(c_gdc, (unsigned*)&vram);
              if (cmd & 0x100) { // parameter bit set?
                  D2 = cmd & 0xFF;
                  D2 = D2 | ((popFIFO(c_gdc, (unsigned*)&vram) & 0xFF) << 8);
              } else { // this is a command
                  storedCommand = 1;
                  break;
              }
              //debug_printf("D2 = %0x\n", D2);

              //D1
              cmd = popFIFO(c_gdc, (unsigned*)&vram);
              if (cmd & 0x100) { // parameter bit set?
                  D1 = cmd & 0xFF;
                  D1 = D1 | ((popFIFO(c_gdc, (unsigned*)&vram) & 0xFF) << 8);
              } else { // this is a command
                  storedCommand = 1;
                  break;
              }
              //debug_printf("D1 = %0x\n", D1);

              //DM
              cmd = popFIFO(c_gdc, (unsigned*)&vram);
              if (cmd & 0x100) { // parameter bit set?
                  DM = cmd & 0xFF;
                  DM = DM | ((popFIFO(c_gdc, (unsigned*)&vram) & 0xFF) << 8);
              } else { // this is a command
                  storedCommand = 1;
                  break;
              }
              //debug_printf("DM = %0x\n", DM);

              //debug_printf("DC =  %0x  D = %0x  D2 = %0x  D1 = %0x  DM = %0x\n", DC, D, D2, D1, DM);

              break;

          case CMD_WDAT : // write data to RAM

              rmwMode = cmd & 0x03; // write data mode
              xferType = (cmd & 0x18) >> 3; // WDAT data type

              cmd = popFIFO(c_gdc, (unsigned*)&vram);
              if (cmd & 0x100) { // parameter bit set?
                  xferData = cmd & 0xFF; //WDAT data
                  xferData = xferData | ((popFIFO(c_gdc, (unsigned*)&vram) & 0xFF) << 8);

              } else { // this is a command
                  storedCommand = 1;
                  break;
              }

              if (DC != 0) {

                  DC++; // adjust cycle count
              // transfer data to eAD set previously
                  for (i=0; i<DC; i++) {
                  vram[eAD] = 0x0000;
                  eAD++;
                  }
              }

              DC = 0;

              break;

          case CMD_GCHRD : // area fill/character draw

              for(cy=15; cy>15-DC-1; cy--) {

                  bitMask = 0xFF000000 >> dAD;

                  charMask = pRAM[cy] << 24;
                  charMask >>= dAD;

                  switch (rmwMode) {

                  case REPLACE :
                      vram[eAD]   = (vram[eAD]   & (~bitMask >> 16)) | (charMask >> 16);
                      vram[eAD+1] = (vram[eAD+1] &  ~bitMask)        |  charMask; // overflow into next word
                  break;

                  case COMPLEMENT :
                      vram[eAD]   = vram[eAD]    ^ (charMask >> 16);
                      vram[eAD+1] = vram[eAD+1]  ^  charMask; // overflow into next word
                  break;

                  case RESET :
                      vram[eAD]   = vram[eAD]   &  ~(charMask >> 16);
                      vram[eAD+1] = vram[eAD+1] &   ~charMask; // overflow into next word
                  break;

                  case SET :
                      vram[eAD]   = vram[eAD]   | (charMask >> 16);
                      vram[eAD+1] = vram[eAD+1] |  charMask; // overflow into next word
                  break;

              }// of switch

                  eAD += 48; // advance to next line

              }// of cy loop

              break;

// 'hidden' accelerator command
// command is of form Dx where x is the four bit sub command :-
// x = 0 - draw char at existing eAD/dAD
//     1 - draw inverse char at existing eAD/dAD
//     2 - process char in terminal emulator using embedded char set
//     3 - cursor off
//     4 - cursor on
//     5 - toggle cursor
//     6 - calculate eAD/dAD from row, col and offset
//     7 - calculate eAD/dAD from x,y (SETCRG replacement)

          case CMD_TERM :

              switch (cmd & 0x0F) {

              case 0 : // draw char at existing eAD/dAD

                  cmd = popFIFO(c_gdc, (unsigned*)&vram) & 0x7F; // pick up char

                  // point to the start of the char pattern
                  offset = (cmd - 0x20) * charSet[3] + 8; //  ASCCI * char rows + attribute table offset

                  // draw the char
                  for(cy=0; cy<charSet[3]; cy++) {

                      bitMask = 0xFF000000 >> dAD;

                      charMask = charSet[offset + cy] << 24;
                      charMask >>= dAD;

                      switch (rmwMode) {

                          case REPLACE :
                              vram[eAD]   = (vram[eAD]   & (~bitMask >> 16)) | (charMask >> 16);
                              vram[eAD+1] = (vram[eAD+1] &  ~bitMask)        |  charMask; // overflow into next word
                          break;

                          case COMPLEMENT :
                              vram[eAD]   = vram[eAD]    ^ (charMask >> 16);
                              vram[eAD+1] = vram[eAD+1]  ^  charMask; // overflow into next word
                          break;
                      }

                      eAD+= 48;

                  }// of for

                  break;

              case 1 : // draw inverse char at existing eAD/dAD

                  cmd = popFIFO(c_gdc, (unsigned*)&vram) & 0xFF; // pick up char

                  // point to the start of the char pattern
                  offset = (cmd - 0x20) * charSet[3] + 8; //  ASCCI * char rows + attribute table offset

                  // draw the char
                  for(cy=0; cy<charSet[3]; cy++) {

                      bitMask = 0xFF000000 >> dAD;

                      charMask = charSet[offset + cy] << 24;
                      charMask ^= 0xFF000000; // invert char pattern
                      charMask >>= dAD;

                      switch (rmwMode) {

                          case REPLACE :
                              vram[eAD]   = (vram[eAD]   & (~bitMask >> 16)) | (charMask >> 16);
                              vram[eAD+1] = (vram[eAD+1] &  ~bitMask)        |  charMask; // overflow into next word
                          break;

                          case COMPLEMENT :
                              vram[eAD]   = vram[eAD]    ^ (charMask >> 16);
                              vram[eAD+1] = vram[eAD+1]  ^  charMask; // overflow into next word
                          break;
                      }

                      eAD+= 48;

                  }// of for

                  break;

              case 2 : // process char in terminal emulator

                  // cursor off
                  if (cursor & 0x80)  {
                      cursor &= 0x7F;
                      drawChar(scrollLines, row, col, attribute, cursorType, COMPLEMENT);
                  }

                  cmd = popFIFO(c_gdc, (unsigned*)&vram) & 0x7F; // pick up char

                  if (escape == 2) {

                      row = cmd - 0x20;
                      escape--;
                      break;
                  }

                  if (escape == 1) {

                      col = cmd - 0x20;
                      escape--;
                      break;
                  }


                  if (cmd < 0x20) {// control character?

                       switch (cmd) {

                       case BELL :
                           c_bell <: 1; // send message to the PIA task to ring the bell
                           tmr :> time;
                           time += 10000000;
                           tmr when timerafter(time) :> int _;
                           c_bell <: 0;
                           break;

                       case BACKSPACE :
                           if (col > 0) {
                               col--;
                           }
                           break;

                       case CURSOR_R :
                           if (col < 83) {
                               col++;
                           }
                           break;

                       case LINEFEED :
                           row ++;
                           if (row == 24) { // scroll up by adjusting display partitions
                               row = 23;
                               scrollLines += 12;

                               startPart1 += 12 * 48;
                               lengthPart1 -= 12;
                               lengthPart2 += 12;

                               if (lengthPart1 == 0) { // at end of scroll cycle, reset partitions
                                   startPart1 -= 24 * 12 * 48;
                                   lengthPart1 = 24 * 12;
                                   lengthPart2 = 0;
                                   scrollLines = 0;
                               }

                               for (i=0; i<84; i++) { // clear the uncovered line
                                   drawChar(scrollLines, row, i, attribute, ' ', REPLACE);
                               }

                               c_disp <: blank;
                               c_disp <: repeatLine;
                               c_disp <: startPart1;
                               c_disp <: startPart2;
                               c_disp <: lengthPart1;
                               c_disp <: lengthPart2;
                           }
                           break;

                       case CURSOR_U :
                           if (row > 0) {
                               row--;
                           } else { // scroll down by adjusting display partitions

                               if (lengthPart2 == 0) {

                                     startPart1 = (48*12*23)+0x6C00;
                                     startPart2 = 0x6C00;
                                     lengthPart1 = 12;
                                     lengthPart2 = 276;
                                     scrollLines = 276;

                               } else {

                                   startPart1 -= (12 * 48);
                                   lengthPart1 += 12;
                                   lengthPart2 -= 12;
                                   scrollLines -= 12;

                               }

                               for (i=0; i<84; i++) { // clear the uncovered line
                                   drawChar(scrollLines, row, i, attribute, ' ', REPLACE);
                               }

                               c_disp <: blank;
                               c_disp <: repeatLine;
                               c_disp <: startPart1;
                               c_disp <: startPart2;
                               c_disp <: lengthPart1;
                               c_disp <: lengthPart2;

                           }
                           break;

                       case CLEARSCREEN :
                           row = 0;
                           col = 0;
                           scrollLines = 0;

                           startPart1 = 0x6C00; // reset the partitions
                           startPart2 = 0x6C00;
                           lengthPart1 = 288;
                           lengthPart2 = 0;

                           c_disp <: blank;
                           c_disp <: repeatLine;
                           c_disp <: startPart1;
                           c_disp <: startPart2;
                           c_disp <: lengthPart1;
                           c_disp <: lengthPart2;

                           for(i=(576*768/16); i < (576*768*3/2/16); i++) {
                               vram[i] = 0x0000;
                           }
                           break;

                       case RETURN :
                           col = 0;
                           break;

                       case MOVE_CURSOR : // next two chars are the row/col coords
                           escape = 2;
                           break;

                       case HOME :
                           row = 0;
                           col = 0;
                           break;

                       case SCREEN_ON :
                           break;

                       case SCREEN_OFF :
                           break;

                       case CURSOR_ON :
                           if ((cursor & 0x80) == 0)  {
                               cursor |= 0x80;
                               drawChar(scrollLines, row, col, attribute, cursorType, COMPLEMENT);
                           }
                           break;

                       case CURSOR_OFF :
                           if (cursor & 0x80)  {
                               cursor &= 0x7F;
                               drawChar(scrollLines, row, col, attribute, cursorType, COMPLEMENT);
                           }
                           break;

                       case CURSOR_TYPE1 :
                           cursor &= 0xFE;
                           break;

                       case CURSOR_TYPE2 :
                           cursorType |= 0x01;
                           break;

                       case INVERT_ON :
                           attribute = 1;
                           break;

                       case INVERT_OFF :
                           attribute = 0;
                           break;

                       case CLEARTO_EOS :

                           // clear to the end of any partial line
                           while ( col < 84) {

                               drawChar(scrollLines, row, col, attribute, ' ', REPLACE);
                               col++;
                           }

                           col = 0;
                           while ( row < 24) {
                               // calculate the address of the first word in the row
                                eAD = 0x6C00 + (row * 48 * charSet[5]) + ((col * charSet[4]) / 16) + (scrollLines * 48);
                                eAD = (eAD/48) * 48; // force to begining of line
                                if (eAD >= 0xA200) {
                                    eAD -= (24 * 12 * 48);
                                }
                                // clear the row
                                for(i=0; i < (12*48); i++) {
                                    vram[eAD+i] = 0x0000;
                                }
                                row++;
                           }
                           break;

                       case CLEAR_LINE :

                           col = 0;
                           // calculate the address of the first word in the row
                           eAD = 0x6C00 + (row * 48 * charSet[5]) + ((col * charSet[4]) / 16) + (scrollLines * 48);
                           eAD = (eAD/48) * 48; // force to begining of line
                           if (eAD >= 0xA200) {
                               eAD -= (24 * 12 * 48);
                           }

                           // clear the row
                           for(i=0; i < (12*48); i++) {
                               vram[eAD+i] = 0x0000;
                           }

                           break;

                       case CLEARTO_EOL :
                           while ( col < 84) {

                               drawChar(scrollLines, row, col, attribute, ' ', REPLACE);
                               col++;
                           }

                           col = 83;
                          break;

                       default :
                           break;
                      }// of switch

                  } else {

                      drawChar(scrollLines, row, col, attribute, cmd, REPLACE);

                      // Update screen position, do not allow movement off rh edge
                      if (col < 83) {
                      col++;

//                      // draw the cursor (invert current location)
//                      drawChar(scrollLines, row, col, attribute, cursorType, COMPLEMENT);
//                      cursor |= 0x80;
                      }

                  }// of else
                  break;

              case 3: // force cursor on
                  if ((cursor & 0x80) == 0)  {
                      cursor |= 0x80;
                      drawChar(scrollLines, row, col, attribute, cursorType, COMPLEMENT);
                  }
                  break;

              case 4: // force cursor off
                  if (cursor & 0x80)  {
                      cursor &= 0x7F;
                      drawChar(scrollLines, row, col, attribute, cursorType, COMPLEMENT);
                  }
                  break;

              case 5 : // toggle cursor
                  drawChar(scrollLines, row, col, attribute, cursorType, COMPLEMENT);
                  cursor ^= 0x80;
                  break;

              case 6 : //calculate eAD/dAD from row, col and offset

                  row = popFIFO(c_gdc, (unsigned*)&vram) & 0xFF;
                  col = popFIFO(c_gdc, (unsigned*)&vram) & 0xFF;

                  offset = popFIFO(c_gdc, (unsigned*)&vram) & 0xFF; // low byte
                  offset = offset | ((popFIFO(c_gdc, (unsigned*)&vram) & 0xFF) << 8); // high byte

                  // get eAD and dAD from row/col
                  eAD = 0x6C00 + (row * 48 * charSet[5]) + ((col * charSet[4]) / 16) + (offset * 48);
                  if (eAD >= 0xA200) {
                      eAD -= (24 * 12 * 48);
                  }
                  dAD = ((col * charSet[4])) - (((col * charSet[4]) / 16) * 16);

                  break;

              case 7 : //calculate eAD/dAD from x,y (SETCRG accel)

                  x = popFIFO(c_gdc, (unsigned*)&vram) & 0xFF; // lo byte
                  x = x | ((popFIFO(c_gdc, (unsigned*)&vram) & 0xFF) << 8); // hi byte
                  y = popFIFO(c_gdc, (unsigned*)&vram) & 0xFF;
                  y = y | ((popFIFO(c_gdc, (unsigned*)&vram) & 0xFF) << 8);

                  eAD = (y * 48) + x/16;
                  dAD = x % 16;

                  break;

              case 8 : //calculate line drawing parameters from x,y
                  endX = popFIFO(c_gdc, (unsigned*)&vram) & 0xFF; // lo byte
                  endX = endX | ((popFIFO(c_gdc, (unsigned*)&vram) & 0xFF) << 8); // hi byte
                  endY = popFIFO(c_gdc, (unsigned*)&vram) & 0xFF;
                  endY = endY | ((popFIFO(c_gdc, (unsigned*)&vram) & 0xFF) << 8);

                  dX = endX - x;
                  dY = endY - y;

                  // determine direction
                  direction = 0;
                  if (abs(dX) > abs(dY)) {
                      direction++;
                  }
                  if ((dX >= 0) && (dY < 0)) {
                      direction = 2;
                      if (abs(dY) > abs(dX)) {
                          direction++;
                      }
                  }
                  if ((dX < 0) && (dY < 0)) {
                      direction = 4;
                      if (abs(dX) > abs(dY)) {
                          direction++;
                      }
                  }
                  if ((dX < 0) && (dY >= 0)) {
                      direction = 6;
                      if (abs(dY) > abs(dX)) {
                          direction++;
                      }
                  }

                  // determine independent/dependent axis
                  if (abs(dX) >= abs(dY)) {
                      dI = dX;
                      dD = dY;
                  } else {
                      dI = dY;
                      dD = dX;
                  }

                  // calculate FIGS parameters
                  DC = abs(dI);
                  D = (2*abs(dD)) - abs(dI);
                  D2 = 2*(abs(dD) - abs(dI));
                  D1 = 2*abs(dD);


                  // switch on the direction (for speed)
                  switch (direction) {

                  case 0 : // x+ve, y+ve, dx < dy, y is independent

                      for (int i=0; i<=DC; i++) {

                          bitMask = 0x8000 >> dAD;

                          switch (rmwMode) {

                              case REPLACE :
                              case SET :
                                  vram[eAD] |= bitMask;
                              break;

                              case COMPLEMENT :
                                  vram[eAD] ^= bitMask;
                              break;

                              case RESET :
                                  vram[eAD] &= ~bitMask;
                              break;
                          }

                          eAD += 48;

                          if(D < 0) {
                              D += D1;
                          } else {
                              D += D2;
                              if (dAD < 15) {
                                  dAD++;
                              } else {
                                  dAD = 0;
                                  eAD++;
                              }
                          }
                      }// of for

                      break;

                  case 1 :// x+ve, y+ve, dx > dy, x is independent

                      for (int i=0; i<=DC; i++) {

                          bitMask = 0x8000 >> dAD;

                          switch (rmwMode) {

                              case REPLACE :
                              case SET :
                                  vram[eAD] |= bitMask;
                              break;

                              case COMPLEMENT :
                                  vram[eAD] ^= bitMask;
                              break;

                              case RESET :
                                  vram[eAD] &= ~bitMask;
                              break;
                          }

                          if (dAD < 15) {
                              dAD++;
                          } else {
                              dAD = 0;
                              eAD++;
                          }

                          if(D < 0) {
                              D += D1;
                          } else {
                              D += D2;
                              eAD+= 48;
                          }
                      }// of for

                      break;

                  case 2 :// x+ve, y-ve, dx > dy, x is independent

                      for (int i=0; i<=DC; i++) {

                          bitMask = 0x8000 >> dAD;

                          switch (rmwMode) {

                              case REPLACE :
                              case SET :
                                  vram[eAD] |= bitMask;
                              break;

                              case COMPLEMENT :
                                  vram[eAD] ^= bitMask;
                              break;

                              case RESET :
                                  vram[eAD] &= ~bitMask;
                              break;
                          }

                          if (dAD < 15) {
                              dAD++;
                          } else {
                              dAD = 0;
                              eAD++;
                          }

                          if(D < 0) {
                              D += D1;
                          } else {
                              D += D2;
                              eAD-= 48;
                          }
                       }// of for

                      break;

                  case 3 :// x+ve, y-ve, dx < dy, y is independent

                      for (int i=0; i<=DC; i++) {

                          bitMask = 0x8000 >> dAD;

                          switch (rmwMode) {

                              case REPLACE :
                              case SET :
                                  vram[eAD] |= bitMask;
                              break;

                              case COMPLEMENT :
                                  vram[eAD] ^= bitMask;
                              break;

                              case RESET :
                                  vram[eAD] &= ~bitMask;
                              break;
                          }

                          eAD -= 48;

                          if(D < 0) {
                              D += D1;
                          } else {
                              D += D2;
                              if (dAD < 15) {
                                  dAD++;
                              } else {
                                  dAD = 0;
                                  eAD++;
                              }
                          }
                      }// of for

                      break;

                  case 4 : // x-ve, y-ve, dx < dy, y is independent

                      for (int i=0; i<=DC; i++) {

                          bitMask = 0x8000 >> dAD;

                          switch (rmwMode) {

                              case REPLACE :
                              case SET :
                                  vram[eAD] |= bitMask;
                              break;

                              case COMPLEMENT :
                                  vram[eAD] ^= bitMask;
                              break;

                              case RESET :
                                  vram[eAD] &= ~bitMask;
                              break;
                          }

                          eAD -= 48;

                          if(D < 0) {
                              D += D1;
                          } else {
                              D += D2;
                              if (dAD) {
                                  dAD--;
                              } else {
                                  dAD = 15;
                                  eAD--;
                              }
                          }
                      }// of for

                      break;

                  case 5 :// x-ve, y-ve, dx > dy, x is independent

                      for (int i=0; i<=DC; i++) {

                          bitMask = 0x8000 >> dAD;

                          switch (rmwMode) {

                              case REPLACE :
                              case SET :
                                  vram[eAD] |= bitMask;
                              break;

                              case COMPLEMENT :
                                  vram[eAD] ^= bitMask;
                              break;

                              case RESET :
                                  vram[eAD] &= ~bitMask;
                              break;
                          }

                          if (dAD) {
                              dAD--;
                          } else {
                              dAD = 15;
                              eAD--;
                          }

                          if(D < 0) {
                              D += D1;
                          } else {
                              D += D2;
                              eAD -= 48;
                          }
                      }// of for

                      break;

                  case 6 :// x-ve, y+ve, dx > dy, x is independent

                      for (int i=0; i<=DC; i++) {

                          bitMask = 0x8000 >> dAD;

                          switch (rmwMode) {

                              case REPLACE :
                              case SET :
                                  vram[eAD] |= bitMask;
                              break;

                              case COMPLEMENT :
                                  vram[eAD] ^= bitMask;
                              break;

                              case RESET :
                                  vram[eAD] &= ~bitMask;
                              break;
                          }

                          if (dAD) {
                              dAD--;
                          } else {
                              dAD = 15;
                              eAD--;
                          }

                          if(D < 0) {
                              D += D1;
                          } else {
                              D += D2;
                              eAD += 48;
                          }
                      }// of for

                      break;

                  case 7 :// x-ve, y+ve, dx < dy, y is independent

                      for (int i=0; i<=DC; i++) {

                          bitMask = 0x8000 >> dAD;

                          switch (rmwMode) {

                              case REPLACE :
                              case SET :
                                  vram[eAD] |= bitMask;
                              break;

                              case COMPLEMENT :
                                  vram[eAD] ^= bitMask;
                              break;

                              case RESET :
                                  vram[eAD] &= ~bitMask;
                              break;
                          }

                          eAD += 48;

                          if(D < 0) {
                              D += D1;
                          } else {
                              D += D2;
                              if (dAD) {
                                  dAD--;
                              } else {
                                  dAD = 15;
                                  eAD--;
                              }
                          }
                      }// of for

                      break; // of case 7

                  }
                  break; // of direction switch


                  break;

              default :
                  break;

              } // of CMD_TERM sub command switch

              break;

              case CMD_FIGD : // figure draw command (point/line etc)

                  //debug_printf("CMD_FIGD\n");

                  // sign extend the D & D2 FIGS parameters from 14 bit to 16 bit
                  if (D  & 0x2000) {D  |= 0xC000;}
                  if (D2 & 0x2000) {D2 |= 0xC000;}

                  //debug_printf("direction = %0d  figureType = %0d\n", direction, figureType);
                  //debug_printf("DC = %0d  D = %0d  D2 = %0d  D1 = %0d\n", DC, D, D2, D1);

                  switch (figureType) {

                      case 0 : // draw a point at the currect eAD/dAD

                      bitMask = 0x8000 >> dAD;

                      switch (rmwMode) {

                          case REPLACE :
                          case SET :
                              vram[eAD] |= bitMask;
                          break;

                          case COMPLEMENT :
                              vram[eAD] ^= bitMask;
                          break;

                          case RESET :
                              vram[eAD] &= ~bitMask;
                          break;
                      }

                      break;

                     case 1 : // draw a line from the current eAD/dAD

                         // switch on the direction (for speed)
                         switch (direction) {

                         case 0 : // x+ve, y+ve, dx < dy, y is independent

                             for (int i=0; i<=DC; i++) {

                                 bitMask = 0x8000 >> dAD;

                                 switch (rmwMode) {

                                     case REPLACE :
                                     case SET :
                                         vram[eAD] |= bitMask;
                                     break;

                                     case COMPLEMENT :
                                         vram[eAD] ^= bitMask;
                                     break;

                                     case RESET :
                                         vram[eAD] &= ~bitMask;
                                     break;
                                 }

                                 eAD += 48;

                                 if(D < 0) {
                                     D += D1;
                                 } else {
                                     D += D2;
                                     if (dAD < 15) {
                                         dAD++;
                                     } else {
                                         dAD = 0;
                                         eAD++;
                                     }
                                 }
                             }// of for

                             break;

                         case 1 :// x+ve, y+ve, dx > dy, x is independent

                             for (int i=0; i<=DC; i++) {

                                 bitMask = 0x8000 >> dAD;

                                 switch (rmwMode) {

                                     case REPLACE :
                                     case SET :
                                         vram[eAD] |= bitMask;
                                     break;

                                     case COMPLEMENT :
                                         vram[eAD] ^= bitMask;
                                     break;

                                     case RESET :
                                         vram[eAD] &= ~bitMask;
                                     break;
                                 }

                                 if (dAD < 15) {
                                     dAD++;
                                 } else {
                                     dAD = 0;
                                     eAD++;
                                 }

                                 if(D < 0) {
                                     D += D1;
                                 } else {
                                     D += D2;
                                     eAD+= 48;
                                 }
                             }// of for

                             break;

                         case 2 :// x+ve, y-ve, dx > dy, x is independent

                             for (int i=0; i<=DC; i++) {

                                 bitMask = 0x8000 >> dAD;

                                 switch (rmwMode) {

                                     case REPLACE :
                                     case SET :
                                         vram[eAD] |= bitMask;
                                     break;

                                     case COMPLEMENT :
                                         vram[eAD] ^= bitMask;
                                     break;

                                     case RESET :
                                         vram[eAD] &= ~bitMask;
                                     break;
                                 }

                                 if (dAD < 15) {
                                     dAD++;
                                 } else {
                                     dAD = 0;
                                     eAD++;
                                 }

                                 if(D < 0) {
                                     D += D1;
                                 } else {
                                     D += D2;
                                     eAD-= 48;
                                 }
                              }// of for

                             break;

                         case 3 :// x+ve, y-ve, dx < dy, y is independent

                             for (int i=0; i<=DC; i++) {

                                 bitMask = 0x8000 >> dAD;

                                 switch (rmwMode) {

                                     case REPLACE :
                                     case SET :
                                         vram[eAD] |= bitMask;
                                     break;

                                     case COMPLEMENT :
                                         vram[eAD] ^= bitMask;
                                     break;

                                     case RESET :
                                         vram[eAD] &= ~bitMask;
                                     break;
                                 }

                                 eAD -= 48;

                                 if(D < 0) {
                                     D += D1;
                                 } else {
                                     D += D2;
                                     if (dAD < 15) {
                                         dAD++;
                                     } else {
                                         dAD = 0;
                                         eAD++;
                                     }
                                 }
                             }// of for

                             break;

                         case 4 : // x-ve, y-ve, dx < dy, y is independent

                             for (int i=0; i<=DC; i++) {

                                 bitMask = 0x8000 >> dAD;

                                 switch (rmwMode) {

                                     case REPLACE :
                                     case SET :
                                         vram[eAD] |= bitMask;
                                     break;

                                     case COMPLEMENT :
                                         vram[eAD] ^= bitMask;
                                     break;

                                     case RESET :
                                         vram[eAD] &= ~bitMask;
                                     break;
                                 }

                                 eAD -= 48;

                                 if(D < 0) {
                                     D += D1;
                                 } else {
                                     D += D2;
                                     if (dAD) {
                                         dAD--;
                                     } else {
                                         dAD = 15;
                                         eAD--;
                                     }
                                 }
                             }// of for

                             break;

                         case 5 :// x-ve, y-ve, dx > dy, x is independent

                             for (int i=0; i<=DC; i++) {

                                 bitMask = 0x8000 >> dAD;

                                 switch (rmwMode) {

                                     case REPLACE :
                                     case SET :
                                         vram[eAD] |= bitMask;
                                     break;

                                     case COMPLEMENT :
                                         vram[eAD] ^= bitMask;
                                     break;

                                     case RESET :
                                         vram[eAD] &= ~bitMask;
                                     break;
                                 }

                                 if (dAD) {
                                     dAD--;
                                 } else {
                                     dAD = 15;
                                     eAD--;
                                 }

                                 if(D < 0) {
                                     D += D1;
                                 } else {
                                     D += D2;
                                     eAD -= 48;
                                 }
                             }// of for

                             break;

                         case 6 :// x-ve, y+ve, dx > dy, x is independent

                             for (int i=0; i<=DC; i++) {

                                 bitMask = 0x8000 >> dAD;

                                 switch (rmwMode) {

                                     case REPLACE :
                                     case SET :
                                         vram[eAD] |= bitMask;
                                     break;

                                     case COMPLEMENT :
                                         vram[eAD] ^= bitMask;
                                     break;

                                     case RESET :
                                         vram[eAD] &= ~bitMask;
                                     break;
                                 }

                                 if (dAD) {
                                     dAD--;
                                 } else {
                                     dAD = 15;
                                     eAD--;
                                 }

                                 if(D < 0) {
                                     D += D1;
                                 } else {
                                     D += D2;
                                     eAD += 48;
                                 }
                             }// of for

                             break;

                         case 7 :// x-ve, y+ve, dx < dy, y is independent

                             for (int i=0; i<=DC; i++) {

                                 bitMask = 0x8000 >> dAD;

                                 switch (rmwMode) {

                                     case REPLACE :
                                     case SET :
                                         vram[eAD] |= bitMask;
                                     break;

                                     case COMPLEMENT :
                                         vram[eAD] ^= bitMask;
                                     break;

                                     case RESET :
                                         vram[eAD] &= ~bitMask;
                                     break;
                                 }

                                 eAD += 48;

                                 if(D < 0) {
                                     D += D1;
                                 } else {
                                     D += D2;
                                     if (dAD) {
                                         dAD--;
                                     } else {
                                         dAD = 15;
                                         eAD--;
                                     }
                                 }
                             }// of for

                             break; // of case 7

                         }
                         break; // of direction switch

                  }// of figuretype switch
                  break;

          default: // ignore everthing else for now
//            debug_printf("UNKNOWN_CMD = %0x\n", cmd);
              break;

           }// of command switch

       }/// of while

   }// of unsafe region

}
