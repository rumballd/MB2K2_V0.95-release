/*
 * memory.xc
 *
 *  Created on: 15 Jul 2019
 *      Author: david
 */

#include "memory.h"

/*
  MB2K2 address map
    -- RAM          $0000 - $BFFF

    -- Flex         $C000 - $DDFF

    -- MON09
        $E000 - $EFFF monitor commands (switched out when Flex running)
        $F000 - $FFFF monitor subroutines and drivers
        $DE00      Scratch RAM + stack space.
        (RAM+127-16) Top of system stack.
        (RAM+384)  Start of scratch space.

    -- IO space
        $FF00      I/O base address.

        PIA1
        KEYREG   EQU   $FF00
        PIACA    EQU   $FF01
        SYSREG   EQU   $FF02
        PIACB    EQU   $FF03

        DUART
        UARTD2   EQU   $FF04
        UARTC2   EQU   $FF05
        UARTD1   EQU   $FF08
        UARTC1   EQU   $FF09
        BAUD1    EQU   $FF0C
        BAUD2    EQU   $FF0D

        FDC
        COMREG   EQU   $FF10
        TRKREG   EQU   $FF11
        SECREG   EQU   $FF12
        DATREG   EQU   $FF13

        GDC
        GDCPRM   EQU   $FF14
        GDCCOM   EQU   $FF15

        RTC
        RTCADD   EQU   $FF18
        RTCDAT   EQU   $FF19

        PIA2
        PORTA    EQU   $FF1C
        PORTB    EQU   $FF1D
        PORTC    EQU   $FF1E
        BITCON   EQU   $FF1F

        RDC (ramdisk controller)
        COMREG   EQU   $FF20
        TRKREG   EQU   $FF21
        SECREG   EQU   $FF22
        DATREG   EQU   $FF23
        MODREG   EQU   $FF24

        PDC (promdisk controller)
        COMREG   EQU   $FF30
        TRKREG   EQU   $FF31
        SECREG   EQU   $FF32
        DATREG   EQU   $FF33
        MODREG   EQU   $FF34

        TMR (50Hz timer)
        TMRREG   EQU   $FF40

        FDC (f-ramdisk controller)
        COMREG   EQU   $FF58
        TRKREG   EQU   $FF59
        SECREG   EQU   $FF5A
        DATREG   EQU   $FF5B
        MODREG   EQU   $FF5C

*/

// 6809 reset switch
on tile[0] : port p_reset_switch = XS1_PORT_1P;

unsigned switch_state;

// debounce reset switch and wait for release
void debounce(void) {

    unsigned time;
    timer t;

    //20ms debounce
    t :> time;
    t when timerafter(time+2000000) :> void;

    // wait for button up
    while ((switch_state & 1) == 0) {
        p_reset_switch :> switch_state;
    }
    //20ms debounce again
    t :> time;
    t when timerafter(time+2000000) :> void;
}


void decodeMem(chanend c_addrData, chanend c_acia, chanend c_rtc,
               chanend c_pia, chanend c_ramdisk, chanend c_promdisk,
               chanend c_gdc, chanend c_tmr) {

    unsigned cmd, addr, data, switch_state, map = 0x04;

// loop servicing memeory accesses
    while (1) {

        c_addrData :> cmd;
        addr = cmd & 0xFFFF;

        if ( (addr >= 0xFF00) && (addr <= 0xFF7F)) { // I/O

            switch (addr) {

            // f-ramdisk
            case (0xFF58) : //f-ramdisk control reg
            case (0xFF59) : //f-ramdisk track reg
            case (0xFF5A) : //f-ramdisk sector reg
            case (0xFF5B) : //f-ramdisk data reg
            case (0xFF5C) : //f-ramdisk mode reg

            if (cmd & 0xFF000000) {  //write
                c_rtc <: cmd;
                }
                else { //read
                    c_rtc <: cmd;
                    c_rtc :> cmd;
                    c_addrData <: cmd;
                }

                break;

            // TMR
           case (0xFF40) :

               if (cmd & 0xFF000000) {  //write
                    c_tmr <: cmd;
               }
               else { //read
                   c_tmr <: cmd;
                   c_tmr :> cmd;
                   c_addrData <: cmd;
                 }
                 break;

            // GDC
            case (0xFF14) : //GDC parameter write/status reg
            case (0xFF15) : //GDC parameter read/command reg

              if (cmd & 0xFF000000) {  //write
                   c_gdc <: cmd;
                }
                else { //read
                    c_gdc <: cmd;
                    c_gdc :> cmd;
                    c_addrData <: cmd;
                }

                break;

            // DUART
            case (0xFF08) : //ACIA1 data reg
            case (0xFF09) : //ACIA1 control reg
            case (0xFF04) : //ACIA2 data reg
            case (0xFF05) : //ACIA2 control reg

              if (cmd & 0xFF000000) {  //write
                   c_acia <: cmd;
                }
                else { //read
                    c_acia <: cmd;
                    c_acia :> cmd;
                    c_addrData <: cmd;
                }

                break;

            //RTC
            case (0xFF18) : //RTC data reg
            case (0xFF19) : //RTC address reg
                if (cmd & 0xFF000000) {  //write
                   c_rtc <: cmd;
                }
                else { //read
                    c_rtc <: cmd;
                    c_rtc :> cmd;
                    c_addrData <: cmd;
                }
                break;

            //PIA
            case (0xFF00) : //PIA data reg A
            case (0xFF01) : //PIA cntrl reg A
            case (0xFF02) : //PIA data reg B
            case (0xFF03) : //PIA cntrl reg B
                if (cmd & 0xFF000000) {  //write
                    if ((cmd & 0x3) == 2) { //port B data reg
                        map = cmd & 0x00040000; //set map bit (swap MON09 range $E000-$EFFF with shadow RAM if set)
                    }
                   c_pia <: cmd;
                }
                else { //read
                    c_pia <: cmd;
                    c_pia :> cmd;
                    c_addrData <: cmd;
                }
                break;

            // ramdisk
            case (0xFF20) : //ramdisk control reg
            case (0xFF21) : //ramdisk track reg
            case (0xFF22) : //ramdisk sector reg
            case (0xFF23) : //ramdisk data reg
            case (0xFF24) : //ramdisk mode reg

            if (cmd & 0xFF000000) {  //write
                    c_ramdisk <: cmd;
                }
                else { //read
                    c_ramdisk <: cmd;
                    c_ramdisk :> cmd;
                    c_addrData <: cmd;
                }

                break;

            // promdisk
            case (0xFF30) : //promdisk control reg
            case (0xFF31) : //promdisk track reg
            case (0xFF32) : //promdisk sector reg
            case (0xFF33) : //promdisk data reg
            case (0xFF34) : //promdisk mode reg

                if (cmd & 0xFF000000) {  //write
                    c_promdisk <: cmd;
                }
                else { //read
                    c_promdisk <: cmd;
                    c_promdisk :> cmd;
                    c_addrData <: cmd;
                }

                break;

            default :
                if (cmd & 0xFF000000) {  //ignore writes
                }
                else { //return dummy value for reads
                    cmd = 0xAA;
                    c_addrData <: cmd;
                }
                break;

            }// of switch

        } else { // RAM and shadow RAM

            if ((addr >= 0xE000) && (addr <= 0xEFFF) && (map == 0)) { // shadow RAM

                addr -= 0xE000; // remove offset to shadow RAM

                switch (cmd & 0xFF000000) {
                case (BYTE_READ) :
                    data = shadowRAM[addr] & 0xFF;

                    // check for 6809 reset
                    p_reset_switch :> switch_state;
                    if ((switch_state & 1) == 0) {

                        debounce();
                        reset_cpu();
                    }

                    c_addrData <: data;
                    break;
                case (BYTE_WRITE) :
                    shadowRAM[addr] = (cmd >> 16) & 0xFF;
                    break;

                case (WORD_READ) :
                    data = (shadowRAM[addr] << 8) & 0xFF00;
                    data = data | shadowRAM[addr+1];

                    // check for 6809 reset
                    p_reset_switch :> switch_state;
                    if ((switch_state & 1) == 0) {

                        debounce();
                        reset_cpu();
                    }

                    c_addrData <: data;
                    break;

                case (WORD_WRITE) :
                    break;

                default :
                    break;

                }// of switch

            } else { //RAM

                switch (cmd & 0xFF000000) {
                case (BYTE_READ) :
                    data = mem[addr] & 0xFF;

                    // check for 6809 reset
                    p_reset_switch :> switch_state;
                    if ((switch_state & 1) == 0) {

                        debounce();
                        reset_cpu();
                    }

                    c_addrData <: data;
                    break;

                case (BYTE_WRITE) :
// FIXME something in FLEX is stamping on the reset vector, ignore for now
                    if ((addr & 0xFFFE) != 0xFFFE) {
                        mem[addr] = (cmd >> 16) & 0xFF;
                    }
                    break;

                case (WORD_READ) :
                    data = (mem[addr] << 8) & 0xFF00;
                    data = data | mem[addr+1];

                    // check for 6809 reset
                    p_reset_switch :> switch_state;
                    if ((switch_state & 1) == 0) {

                        debounce();
                        reset_cpu();
                    }

                    c_addrData <: data;
                    break;

                case (WORD_WRITE) :
                    break;

                default :
                    break;

                }// of switch

            } //of if

        }// of else

    }// of while

}



