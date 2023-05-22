// Copyright (c) 2016, XMOS Ltd, All rights reserved

#include <platform.h>
#include <xs1.h>
#include <stdio.h>
#include <string.h>
#include <timer.h>
#include "xud_cdc.h"

#define RTC_ADDR 0xDE
#define SEC_REG 0x00
#define MIN_REG 0x01
#define HOUR_REG 0x02
#define DAY_REG 0x03
#define DATE_REG 0x04
#define MONTH_REG 0x05
#define YEAR_REG 0x06
#define CNTL_REG 0x07
#define CALIBRATION_REG 0x08
// the calibration value allows adjustment of the RTC frequency
// as per section 5.2.3 of the MCP7941X data sheet
#define CALIBRATION_VALUE 0x7D // + 250 32.768KHz clocks/min (which slows the clock)

#define BYTE 1

// defines for f-ramdisk
#define SECTORS_PER_TRACK  10
#define TRACKS_PER_DISK    40
#define BYTES_PER_SECTOR   256
#define FRAMDISK_SIZE      (BYTES_PER_SECTOR * SECTORS_PER_TRACK * TRACKS_PER_DISK)

#define CONTROL_REG  58
#define TRACK_REG    59
#define SECTOR_REG   5A
#define DATA_REG     5B
#define MODE_REG     5C



//I/O port definitions
on tile[0] : out port SCL         = XS1_PORT_1I;
on tile[0] :     port SDA         = XS1_PORT_1J; //SDA is bi-directional and will automatically 3-state

//globals
timer I2C_timer;    // Timer for I2C routines

// I2C primitives
// delay n*100us ( a delay of '1' corresponds to a 400KHz clock rate)
void I2C_delay(int delay) {
    unsigned int time;
    I2C_timer :> time;
    I2C_timer when timerafter (time + (delay * 100)) :> int tmp;
    }

void init_I2C_buss(void) {
    SDA <: 1;   //set SDA and SCL
    SCL <: 1;
    I2C_delay(400);
}

void I2C_start() {
    SDA <: 1;   //set SDA and SCL
    SCL <: 1;
    I2C_delay(1);

    SDA <: 0;       //clr SDA
    I2C_delay(1);

    SCL <: 0;       //clr SCL
    I2C_delay(1);
}

void I2C_stop() {
    SDA <: 0;       //clr SDA
    I2C_delay(1);

    SCL <: 1;       //set SCL
    I2C_delay(1);

    SDA <: 1;       //set SDA
    I2C_delay(1);
}

void I2C_ack() {
    int temp;

    SDA :> temp;        //float SDA to allow the slave to drive the buss by a dummy read
    I2C_delay(1);

    SCL <: 1;       //set SCL
    I2C_delay(1);
    SCL <: 0;       //clr SCL
    I2C_delay(1);
}

void I2C_master_ack() {
    int temp;

    SDA <: 0;       //low for ACK
    I2C_delay(1);

    SCL <: 1;       //set SCL
    I2C_delay(1);
    SCL <: 0;       //clr SCL
    I2C_delay(1);

    SDA :> temp;        //let go of SDA
    I2C_delay(1);
}

void I2C_write_byte(int value) {
int i;

// send value one bit at a time, MSB first
    for(i=0; i<8; i++) {
        if (value & 0x80) {
            SDA <: 1;                   //set SDA
            I2C_delay(1);
        }
        else {
            SDA <: 0;                   //clr SDA
            I2C_delay(1);
        }

        SCL <: 1;       //set SCL
        I2C_delay(1);
        SCL <: 0;       //clr SCL
        I2C_delay(1);

        value*= 2; // shift next bit up
    }
}

int  I2C_read_byte() {
int i, value = 0, temp;

// get value, one bit at a time, MSB first
    for(i=0; i<8; i++) {

        I2C_delay(1);

        value*= 2; // shift bit up

        SCL <: 1;       //set SCL
        I2C_delay(1);

        SDA :> temp; // sample data line
        if((temp & 0x1) != 0) {
            value |= 0x01;
        }

        SCL <: 0;       //clr SCL
        I2C_delay(1);

    }
    return value & 0xFF;
}


void I2C_put_byte(int device_addr, int sub_addr, int data_width, int value) {

    I2C_start();

    I2C_write_byte((device_addr & 0xFE));   // LS bit is low for write
    I2C_ack();

    I2C_write_byte(sub_addr & 0xFF);        // send sub address byte
    I2C_ack();

    if (data_width == 2) {              // send high order data byte if needed
        I2C_write_byte((value>>8) & 0xFF);
        I2C_ack();
    }

    I2C_write_byte(value & 0xFF);
    I2C_ack();

    I2C_stop();

}

int I2C_get_byte(int device_addr, int sub_addr, int sub_addr_width) {
int value = 0;

    I2C_start();

    I2C_write_byte((device_addr & 0xFE));   // LS bit is low for device address write
    I2C_ack();

    if (sub_addr_width == 2) {              // send high order sub address byte if needed
        I2C_write_byte((sub_addr>>8) & 0xFF);
        I2C_ack();
    }

    I2C_write_byte(sub_addr & 0xFF);        // send sub address byte
    I2C_ack();

    I2C_start();

    I2C_write_byte((device_addr | 0x01));   // LS bit is high for read
    I2C_ack();

    value = I2C_read_byte();

    I2C_ack(); // this is really a NACK

    I2C_stop();

    return value;
}

//*00*/  0x00, 0x00, 0x00, 0x00, 0x12, 0x00, 0x06, 0x20, 0x07, 0x19,           // RTC time and date (20-Jul-2019, MB2K2's birthday!)
//*0A*/  0x00, 0x00, 0x00, 0x80,                                               // RTC control regs, no update in progress and data valid
//*0E*/  0x0F,                                                                 // no 2Mhz, no 256k, 128k Promdisk, 30ms step rate. (unused in MB2K2)
//*0F*/  0xAA,                                                                 // powerfail flag
//*10*/  0x00, 0x01, 0xFF, 0xFF,                                               //drive allocation: promdisk, ramdisk, unallocated, unallocated
//*14*/  0x7F, 0x00, 0x3a, 0x18, 0x50, 0x00, 0x00, 0x08, 0x00, 0x00, 0x1B,     //Flex TTYSET params 8,0,$3A,$18,$50,0,0,$08,0,0,$1B
//*1F*/  0x00, 0x01,                                                           //Flex ASN params, system = 0, work = 1
//*21*/  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,                       //GDC params
//*29*/  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,                             //spare
//*30*/  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,                             //spare
//*38*/  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00                  //spare

void rtc(chanend c_rtc)
{
    unsigned cmd, temp, i;
    char addr = 0;

    unsigned command_reg = 0, track_reg = 0, sector_reg = 1, os9 = 0, fram_addr = 0;

    //f-ramdisk buffer
    char fd_buff[BYTES_PER_SECTOR];

    init_I2C_buss();

// force RTC osc and battery on
    temp = I2C_get_byte(RTC_ADDR, SEC_REG, BYTE);
    temp |= 0x80; // set osc enable bit
    I2C_put_byte(RTC_ADDR, SEC_REG, BYTE, temp);

    temp = I2C_get_byte(RTC_ADDR, DAY_REG, BYTE);
    temp |= 0x08; // enable battery power
    I2C_put_byte(RTC_ADDR, DAY_REG, BYTE, temp);

    I2C_put_byte(RTC_ADDR, CNTL_REG, BYTE, 0xC0); // MFP output to 1s (allows calibration)

    I2C_put_byte(RTC_ADDR, CALIBRATION_REG, BYTE, CALIBRATION_VALUE); // set calibration value - YMMV


// event loop
    while (1) {

        c_rtc :> cmd;

        switch (cmd & 0x800000FF) {

        case  (0x80000019) : // RTC write data reg

            switch (addr) { // map out the time registers and offset the rest by 0x20

            case 0x00 : //MC146818 secs reg
                cmd = (cmd >> 16) & 0xFF;
                cmd = ((cmd / 10) << 4) | (cmd % 10); // binary to BCD conversion
                cmd |= 0x80; // set osc enable bit
                I2C_put_byte(RTC_ADDR, SEC_REG, BYTE, cmd);
                break;

            case 0x02 : //MC146818 mins reg
                cmd = (cmd >> 16) & 0xFF;
                cmd = ((cmd / 10) << 4) | (cmd % 10); // binary to BCD conversion
               I2C_put_byte(RTC_ADDR, MIN_REG, BYTE, cmd);
               break;

            case 0x04 : //MC146818 hours reg
                cmd = (cmd >> 16) & 0xFF;
                cmd = ((cmd / 10) << 4) | (cmd % 10); // binary to BCD conversion
                cmd &= 0x03F; // clear 12/24 hours bit
                I2C_put_byte(RTC_ADDR, HOUR_REG, BYTE, cmd);
                break;

            case 0x06 : //MC146818 day reg
                cmd = (cmd >> 16) & 0xFF;
                cmd = ((cmd / 10) << 4) | (cmd % 10); // binary to BCD conversion
                cmd |= 0x08; // set batt power bit
                I2C_put_byte(RTC_ADDR, DAY_REG, BYTE, cmd);
               break;

            case 0x07 : //MC146818 date reg
                cmd = (cmd >> 16) & 0xFF;
                cmd = ((cmd / 10) << 4) | (cmd % 10); // binary to BCD conversion
                I2C_put_byte(RTC_ADDR, DATE_REG, BYTE, cmd);
                break;

            case 0x08 : //MC146818 month reg
                cmd = (cmd >> 16) & 0xFF;
                cmd = ((cmd / 10) << 4) | (cmd % 10); // binary to BCD conversion
                I2C_put_byte(RTC_ADDR, MONTH_REG, BYTE, cmd);
                break;

            case 0x09 : //MC146818 year reg
                cmd = (cmd >> 16) & 0xFF;
                cmd = ((cmd / 10) << 4) | (cmd % 10); // binary to BCD conversion
                I2C_put_byte(RTC_ADDR, YEAR_REG, BYTE, cmd);
                break;

            default : // access the RTC RAM
                I2C_put_byte(RTC_ADDR, (addr + 0x20), BYTE, ((cmd >> 16) & 0xFF));
               break;
            }

            break;

        case  (0x00000019) : // RTC read data reg

            switch (addr) { // map out the time registers and offset the rest by 0x20

            case 0x00 :
                cmd = I2C_get_byte(RTC_ADDR, SEC_REG, BYTE);
                cmd &= 0x7F; // mask osc enable bit
                cmd = ((cmd >> 4) * 10) + (cmd & 0x0F); // convert BCD -> bin
                break;

            case 0x02 :
                cmd = I2C_get_byte(RTC_ADDR, MIN_REG, BYTE);
                cmd = ((cmd >> 4) * 10) + (cmd & 0x0F); // convert BCD -> bin
              break;

            case 0x04 :
                cmd = I2C_get_byte(RTC_ADDR, HOUR_REG, BYTE);
                cmd &= 0x3F; // mask unused and 12/24 hours bit
                cmd = ((cmd >> 4) * 10) + (cmd & 0x0F); // convert BCD -> bin
               break;

            case 0x06 :
                cmd = I2C_get_byte(RTC_ADDR, DAY_REG, BYTE);
                cmd &= 0x07; // mask unused and batt bits
                cmd = ((cmd >> 4) * 10) + (cmd & 0x0F); // convert BCD -> bin
               break;

            case 0x07 :
                cmd = I2C_get_byte(RTC_ADDR, DATE_REG, BYTE);
                cmd = ((cmd >> 4) * 10) + (cmd & 0x0F); // convert BCD -> bin
                break;

            case 0x08 :
                cmd = I2C_get_byte(RTC_ADDR, MONTH_REG, BYTE);
                cmd &= 0x1F; // mask unused and leap year bit
                cmd = ((cmd >> 4) * 10) + (cmd & 0x0F); // convert BCD -> bin
                break;

            case 0x09 :
                cmd = I2C_get_byte(RTC_ADDR, YEAR_REG, BYTE);
                cmd = ((cmd >> 4) * 10) + (cmd & 0x0F); // convert BCD -> bin
                break;

            case 0x0A : // reg 'A' always returns 0 as there is no update bit
            case 0x0B :
            case 0x0C :
                cmd = 0x00;
                break;

            case 0x0D : // reg 'D' returns 0x80 if RTC power is OK (RAM[0x2F] = 0xAA), else 0x00
                cmd = I2C_get_byte(RTC_ADDR, 0x2F, BYTE);
                if (cmd == 0xAA) {
                    cmd = 0x80;
                } else {
                    cmd = 0x00;
                }
                break;

            default : // access the RTC RAM
                cmd = I2C_get_byte(RTC_ADDR, (addr + 0x20), BYTE);
                break;
            }

            c_rtc <: cmd & 0xFF;

            break;

        case  (0x80000018) : // RTC write address reg
            addr =  (cmd >> 16) & 0x3F;
            break;

        case  (0x00000018) : // RTC read address reg
            c_rtc <: (unsigned)addr;
            break;

// F-RAM routines are here so as to be able to share the I2C data lines
        // f-ramdisk write
        case  (0x80000058) : // write F-RAM command reg
            cmd = (cmd>>16) & 0xFF;

            i = 0;

            if (os9) {
                fram_addr = (BYTES_PER_SECTOR * ((track_reg << 8) | sector_reg));
            } else {
                fram_addr = BYTES_PER_SECTOR * ((track_reg * SECTORS_PER_TRACK) + (sector_reg-1));
            }
            break;

        case  (0x80000059) : // write F-RAM track reg
            track_reg = (cmd>>16) & 0xFF;
            break;

        case  (0x8000005A) : // write F-RAM sector reg
            sector_reg = (cmd>>16) & 0xFF;
            break;

        case  (0x8000005B) : // write F-RAM data
            fd_buff[i] = (cmd>>16) & 0xFF;
            i++;

            if (i == 256) { // if buffer is full, write out buffer to F-RAM
                command_reg = 0x80; // set busy bit

                I2C_start();

                // device addr
                if (fram_addr >> 16) { //upper half of F-RAM?
                    I2C_write_byte(0xA2);   // device address is 101000+(A16)+(R/~W)
                } else {
                    I2C_write_byte(0xA0);   // device address is 101000+(A16)+(R/~W)
                }
                I2C_ack();

                // buffer base addr
                I2C_write_byte((fram_addr >> 8) & 0xFF);  // ADDH
                I2C_ack();
                I2C_write_byte(fram_addr & 0xFF);  // ADDL
                I2C_ack();

                // send buffer
                for (int k=0; k<256; k++) {
                    I2C_write_byte(fd_buff[k] & 0xFF);
                I2C_ack();
                }

                I2C_stop();
            }

            break;

        case  (0x8000005C) : // write mode reg
            os9 = (cmd>>16) & 0xFF;
            break;

        // f-ramdisk read
        case  (0x00000058) : // read F-RAM command reg
            c_rtc <: command_reg;
            break;

        case  (0x00000059) : // read F-RAM track reg
            c_rtc <: track_reg;
            break;

        case  (0x0000005A) : // read F-RAM sector reg
            c_rtc <: sector_reg;
            break;

        case  (0x0000005B) : // read F-RAM data
            if (i == 0) { // get buffer from F-RAM if first read since command

                I2C_start();

                // slave addr
                if (fram_addr >> 16) { //upper half of F-RAM?
                    I2C_write_byte(0xA2);   // device address is 101000+(A16)+(R/~W)
                } else {
                    I2C_write_byte(0xA0);   // device address is 101000+(A16)+(R/~W)
                }
                I2C_ack();

                // buffer base addr
                I2C_write_byte((fram_addr >> 8) & 0xFF);  // ADDH
                I2C_ack();
                I2C_write_byte(fram_addr & 0xFF);  // ADDL
                I2C_ack();

                I2C_start(); // for a read there is a second start and slave addr

                // slave addr
                if (fram_addr >> 16) { //upper half of F-RAM?
                    I2C_write_byte(0xA3);   // device address is 101000+(A16)+(R/~W)
                } else {
                    I2C_write_byte(0xA1);   // device address is 101000+(A16)+(R/~W)
                }
                I2C_ack();

                // get buffer
                for (int j=0; j<255; j++) {
                    fd_buff[j] = I2C_read_byte();
                    I2C_master_ack(); // master has to ACK to continue read
                }
                fd_buff[255] = I2C_read_byte();
                I2C_ack(); // last byte needs an ACK rather than a NACK

                I2C_stop();
            }

            cmd = fd_buff[i];
            c_rtc <: cmd & 0xFF;
            i++;

            break;

        case  (0x0000005C) : // read mode reg
            c_rtc <: os9;
            break;

        default:
            break;

        }// of switch

    } // of while

}

