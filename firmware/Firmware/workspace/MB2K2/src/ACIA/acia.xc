// Copyright (c) 2016, XMOS Ltd, All rights reserved

#include <platform.h>
#include <xs1.h>
#include <stdio.h>
#include <string.h>
#include <timer.h>
#ifdef USB_SERIAL
#include "usb.h"
#include "xud_cdc.h"
#endif
#ifdef FTDI_SERIAL
#include "uart.h"
#endif


// access LEDs
on tile[1] :port p_acia0_led = XS1_PORT_1C;
on tile[1] :port p_acia1_led = XS1_PORT_1D;

#ifdef USB_SERIAL
void acia(client interface usb_cdc_interface cdc0, client interface usb_cdc_interface cdc1, chanend c_acia) {

    unsigned cmd, time, end_time;
    timer t;

    while (1) {

#pragma ordered
        select {

            case c_acia :> cmd :

            switch (cmd & 0x8000000F) {

            case  (0x80000008) : // acia1 write data reg

                p_acia0_led <: -1;

                t :> time;
                end_time = time + 100000; //(1ms)

                cdc1.put_char((cmd & 0x00FF0000) >> 16);
                break;

            case  (0x00000008) : // acia1 read data reg

                p_acia0_led <: -1;

                t :> time;
                end_time = time + 100000; //(1ms)

                if(cdc1.available_bytes()) {

                    cmd = cdc1.get_char();
                    c_acia <: cmd & 0xFF;

                } else { // return 0

                    c_acia <: 0;
                }

                break;

            case  (0x80000009) : // acia1 write control reg
                cdc1.flush_buffer(); // any write to the control reg flushes the buffer
                break;

            case  (0x00000009) : // acia1 read control reg (as per WD2123 DUART)
                if(cdc1.available_bytes()) {
                c_acia <: 0x03; // Rx ready, Tx ready
                } else {
                   c_acia <: 0x01; // Tx ready
                }
                break;

            case  (0x80000004) : // acia2 write data reg

                p_acia1_led <: -1;

                t :> time;
                end_time = time + 10000; //(100 us)

                cdc0.put_char((cmd & 0x00FF0000) >> 16);
                break;

            case  (0x00000004) : // acia2 read data reg

                p_acia1_led <: -1;

                t :> time;
                end_time = time + 10000; //(100 us)

                if(cdc0.available_bytes()) {

                    cmd = cdc0.get_char();
                    c_acia <: cmd & 0xFF;

                } else { // return 0

                    c_acia <: 0;
                }
               break;

            case  (0x80000005) : // acia2 write control reg
                cdc0.flush_buffer(); // any write to the control reg flushes the buffer
                break;

            case  (0x00000005) : // acia2 read control reg
                if(cdc0.available_bytes()) {
                c_acia <: 0x03; // Rx ready, Tx ready
                } else {
                   c_acia <: 0x01; // Tx ready
                }
                break;

            default:
                break;

            }// of switch
            break;

            case t when timerafter ( end_time ) :> void : //turn off LEDs when timer triggers
                p_acia0_led <: 0;
                p_acia1_led <: 0;
            break;

        }// of select

    } // of while

}
#endif

#ifdef FTDI_SERIAL
void acia(client uart_tx_if i_tx0, client uart_rx_if i_rx0, // (WD2123)
                 client uart_tx_if i_tx1, client uart_rx_if i_rx1,
                 chanend c_acia) {

    unsigned cmd, time, end_time;
    timer t;

    while (1) {

#pragma ordered
        select {

            case c_acia :> cmd :

            switch (cmd & 0x8000000F) {

            case  (0x80000008) : // acia1 write data reg

                p_acia0_led <: -1;
                t :> time;
                end_time = time + 1000; //(10us)

                i_tx0.write((cmd & 0x00FF0000) >> 16);

                break;

            case  (0x00000008) : // acia1 read data reg

                p_acia0_led <: -1;
                t :> time;
                end_time = time + 1000; //(10us)

                cmd = i_rx0.read();
                c_acia <: cmd & 0xFF;

                break;

            case  (0x80000009) : // acia1 write control reg
                break;

            case  (0x00000009) : // acia1 read control reg (as per WD2123 DUART)

                if(i_rx0.has_data()) {
                c_acia <: 0x03; // Rx ready, Tx ready
                } else {
                   c_acia <: 0x01; // Tx ready
                }

                break;

            case  (0x80000004) : // acia2 write data reg

                p_acia1_led <: -1;
                t :> time;
                end_time = time + 1000; //(10us)

                i_tx1.write((cmd & 0x00FF0000) >> 16);

                break;

            case  (0x00000004) : // acia2 read data reg

                p_acia1_led <: -1;
                t :> time;
                end_time = time + 1000; //(10us)

                cmd = i_rx1.read();
                c_acia <: cmd & 0xFF;

               break;

            case  (0x80000005) : // acia2 write control reg
                break;

            case  (0x00000005) : // acia2 read control reg

                if(i_rx1.has_data()) {
                c_acia <: 0x03; // Rx ready, Tx ready
                } else {
                   c_acia <: 0x01; // Tx ready
                }

                break;

            default:
                break;

            }// of switch
            break;

            case t when timerafter ( end_time ) :> void : //turn off LEDs when timer triggers
                p_acia0_led <: 0;
                p_acia1_led <: 0;
            break;

        }// of select

    } // of while

}
#endif

