/*
 * TMR.xc
 *
 *  Created on: Jun 11, 2020
 *      Author: david
 */

#include <platform.h>
#include <xs1.h>
#include <stdio.h>
#include <string.h>
#include <timer.h>
#include "xud_cdc.h"

#include "tmr.h"

#define TICK 100 //ms


void tmr(chanend c_tmr) {

    unsigned cmd;
    timer t;
    unsigned end_time, tmr_enb, tmr_flg;

// event loop
    while (1) {

#pragma ordered

        select {

        case c_tmr :> cmd : // register access

            if (cmd & 0x80000000) { // write reg, enable & reset TMR

                tmr_enb = -1;
                t :> end_time;
                end_time += (TICK * 100000); // units of 10ns sysclk cycle time

            } else { // read reg, return and reset timer flag

                if (tmr_flg) {
                    c_tmr <: 0x00000080;
                    tmr_flg = 0;
                } else {
                    c_tmr <: 0x00000000;
                }

            }// of else

            break;

        case t when timerafter ( end_time ) :> void : //timer has triggered

            if (tmr_enb) {

                tmr_enb = 0;
                tmr_flg = -1;
                request_irq();
            }

            break;

        }// of select

    } // of while

}


