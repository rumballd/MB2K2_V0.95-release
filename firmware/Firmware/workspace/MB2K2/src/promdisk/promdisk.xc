/*
 * promdisk.xc
 *
 *  Created on: Jul 23, 2019
 *      Author: david
 */

#include "promdisk.h"

#include <quadflashlib.h>

#include "debug_print.h"

// access LEDs
on tile[0] :port p_pd_led = XS1_PORT_1H;


void promdisk(chanend c_promdisk) {

    unsigned param, cmd, addr, track, sector, os9, max_sector, max_track, i;
    char buff[256];
    char flash_buff[4096];

    timer t;
    unsigned time, end_time;

    fl_connectToDevice(ports, deviceSpecs, sizeof(deviceSpecs)/sizeof(fl_QuadDeviceSpec));

    // get the max sector/track from the installed FLEX image's SIR (tr = 0, sec = 3, offsets = 0x26/0x27)
    addr = 512;
    fl_readData(addr, 256, buff);
    max_track  = buff[0x26] + 1;
    max_sector = buff[0x27];

/*
    debug_printf("\n\nFlash Type: %d\n", fl_getFlashType());
    debug_printf("Flash Size: %x\n", fl_getFlashSize());
    debug_printf("Flash fl_getDataPartitionSize: %d\n", fl_getDataPartitionSize());
    debug_printf("Flash fl_getNumDataSectors: %d\n", fl_getNumDataSectors());
    debug_printf("Flash fl_getDataSectorSize(0): %d\n", fl_getDataSectorSize(0));
    debug_printf("Flash fl_getWriteScratchSize(0, 64): %d\n", fl_getWriteScratchSize(0, 256));

    fl_disconnect();
*/
    i = 0;
    os9 = 0;

    while (1) {

#pragma ordered

        select {

            case c_promdisk :> param :

        p_pd_led <: -1;
        t :> time;
        end_time = time + 100000; //(1ms)

        if (param & 0x80000000) { // write

            switch (param & 0x00000007) {

            case (CONTROL_REG) :

                cmd = (param>>16) & 0xFF;

                if (os9) {
                    addr = (BYTES_PER_SECTOR * (max_track * max_sector)) + (BYTES_PER_SECTOR * ((track << 8) | sector));
                } else {
                    addr = BYTES_PER_SECTOR * ((track * max_sector) + (sector-1));
                }

                switch (cmd) {

                case (PD_WRITE) :
                // write 256 bytes data to boot flash
                fl_writeData(addr, 256, buff, flash_buff);
                break;

                case (PD_READ) :
                // read 256 bytes data from boot flash
                fl_readData(addr, 256, buff);
                break;

                }// of switch

                break;

            case (TRACK_REG) :
                track = (param>>16) & 0xFF;
                i = 0; // reset data buffer pointer
                break;

            case (SECTOR_REG) :
                sector = (param>>16) & 0xFF;
                i = 0;
                break;

            case (DATA_REG) :
                buff[i] = (param>>16) & 0xFF;
                i++;
                break;

            case (MODE_REG) :
                os9 = (param>>16) & 0xFF;
                break;

            default:
                break;

            }// of switch

        } else { //read

            switch (param & 0x00000007) {
            case (CONTROL_REG) : // dummy return
                c_promdisk <: cmd;
                break;

            case (TRACK_REG) :
                c_promdisk <: track;
                break;

            case (SECTOR_REG) :
                c_promdisk <: sector;
                break;

            case (DATA_REG) : // return data from most recent 'sector' read
                param = buff[i];
                c_promdisk <: param & 0xFF;
                i++;
                i &= 0xFF;
                break;

            case (MODE_REG) :
                c_promdisk <: os9;
                break;

            default:
                c_promdisk <: 0;
                break;


            }// of switch

        }// of if/else
        break;

        case t when timerafter ( end_time ) :> void : //turn off LED when timer triggers
            p_pd_led <: 0;
            break;

        } // of select

    }// of while

}

