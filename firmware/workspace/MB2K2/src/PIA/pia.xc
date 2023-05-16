/*
 * pia.c
 *
 *  Created on: Jul 20, 2019
 *      Author: david
 */

#include <platform.h>
#include <xs1.h>

#include "ps2.h"
#include "keymap.h"

//#include "pia.h"

extern void ps2HandlerInit(port ps2_clock, struct ps2state &state);
extern select ps2Handler(port ps2_clock, port ps2_data, int clockBit, struct ps2state &state);

/*PIA port B definitions (SYSREG)
 * bit 0 - 3 are outputs
 * 0 - DRV (red LED)
 * 1 - /DDEN (green LED)
 * 2 - MAP bit (maps out bottom 4K of monitor ($E000-$EFFF) when 0) (Blue LED)
 * 3 - BELL
  * bit 4 - 7 are inputs
 * 4 - Initial input port
 * 5 - Initial output port
 * 6 - spare
 * 7 - Auto boot Flex
 */

// control bits and switches
on tile[0] :port p_switch = XS1_PORT_4E;
on tile[0] :port p_portb  = XS1_PORT_4F;

// PS/2 pins
on tile[0] :port p_ps2dat = XS1_PORT_1A;
on tile[0] :port p_ps2clk = XS1_PORT_1D;

void pia(chanend c_pia, chanend c_beep) {

    timer t;

    unsigned cmd, time, endTime;
    char addr;
    // PIA registers: data_a, cntrl_a, data_b, cntrl_b
    char regs[4] = { 0x00, 0x00, 0x00, 0x00 };
//TODO respect direction bits when reading/writing data registers.

    unsigned action, key, modifier, offset;
    struct ps2state ps2State;

    p_portb <: 0x00; // all outputs low

    // init PS/2 struct and I/O
    ps2HandlerInit(p_ps2clk, ps2State);

    while (1) {

        select {

            // pick up any accesses
            case c_pia :> cmd :

                addr = cmd & 0x03;

                if (cmd & 0x80000000) { // write

                    cmd = (cmd >> 16) & 0xFF;
                    regs[addr] = cmd;
                    if (addr == 2) { //if port B data reg then set outputs
                       p_portb <: cmd & 0x0B; // disable the unused LEDs for now
                    }

                } else { //read

                    p_switch :> cmd; // pick up switch settings regardless of which register is being read.
                    regs[2] &= 0x0F; // merge output and input bits
                    regs[2]  = regs[2] | ((cmd & 0x01) << 7) | // bit reversal to match MB2 PCB
                                        ((cmd & 0x02) << 5) |
                                        ((cmd & 0x04) << 3) |
                                        ((cmd & 0x08) << 1);
                    c_pia <: (unsigned int)regs[addr];

                    if (addr == 0) { // if port A data reg, clear data ready bit on read
                        regs[1] = 0;
                    }

                }// of else

                break;

            case c_beep :> cmd : // horrible hack to ring the bell from the GDC's terminal emulator.
                if (cmd) {
                    regs[2] |= 0x08;
                    p_portb <: (unsigned)regs[2] & 0x08;
                } else {
                    regs[2] &= 0xF7;
                    p_portb <: (unsigned)regs[2] & 0x08;
                }
                break;

            // handle activity on the PS/2 buss (non blocking)
                case ps2Handler(p_ps2clk, p_ps2dat, 0, ps2State);

            default:
                break;

        }// of select

        // decode raw PS/2 key value as a f(n) of shift etc
        {action, modifier, key} = ps2Interpret(ps2State);

        if (action == PS2_PRESS) {
            offset = ((modifier & PS2_MODIFIER_SHIFT) * 128)
                   + ((modifier & PS2_MODIFIER_CAPSL) *  32); // offset by 256 if shift pressed and 128 if capslock
            regs[0] = ps2lookupASCII[key + offset];

            if (modifier & PS2_MODIFIER_CTRL) { // control key?
                if (regs[0] >= 0x60) { // convert to upper case
                    regs[0] -= 0x20;
                }
                regs[0] -= 0x40; // convert to control code
            }
            // set data ready bit in port A control reg
            // note for compatibility with Stylograph which assumes that the system I/O is via an
            // ACIA, we spoof the ACIA Rx data ready bit (bit 0) as well.
            regs[1] = 0x81;
        }

    } // of while

}

