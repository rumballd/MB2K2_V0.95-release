/*
 * ramdisk.h
 *
 *  Created on: Jul 22, 2019
 *      Author: david
 */


#ifndef RAMDISK_H_
#define RAMDISK_H_

#include <xs1.h>
#include <platform.h>

// defines
#define SECTORS_PER_TRACK  20
#define TRACKS_PER_DISK    40
#define BYTES_PER_SECTOR   256
#define RAMDISK_SIZE       204800

#define CONTROL_REG  0
#define TRACK_REG    1
#define SECTOR_REG   2
#define DATA_REG     3
#define MODE_REG     4


// function prototypes
void ramdisk(chanend c_ramdisk);

//globals
char rd_mem[RAMDISK_SIZE];


#endif /* RAMDISK_H_ */

