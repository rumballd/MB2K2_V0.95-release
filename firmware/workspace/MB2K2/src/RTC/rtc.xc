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


//I/O port definitions
on tile[0] : out port SCL         = XS1_PORT_1I;
on tile[0] :     port SDA         = XS1_PORT_1J; //SDA is bi-directional and will automatically 3-state

//globals
timer I2C_timer;    // Timer for I2C routines

// I2C primitives
// delay n*100us ( a delay of '1' corresponds to a 100KHz clock rate)
void I2C_delay(int delay) {
    unsigned int time;
    I2C_timer :> time;
    I2C_timer when timerafter (time + (delay * 333)) :> int tmp;
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
    unsigned cmd, temp;
    char addr = 0;

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

        switch (cmd & 0x80000001) {

        case  (0x80000001) : // write data reg

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

        case  (0x00000001) : // read data reg

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

        case  (0x80000000) : // write address reg
            addr =  (cmd >> 16) & 0x3F;
            break;

        case  (0x00000000) : // read address reg
            c_rtc <: (unsigned)addr;
            break;

        default:
            break;

        }// of switch

    } // of while

}

