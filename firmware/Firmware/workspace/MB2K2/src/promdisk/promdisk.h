/*
 * promdisk.h
 *
 *  Created on: Jul 23, 2019
 *      Author: david
 */


#ifndef PROMDISK_H_
#define PROMDISK_H_

#include <xs1.h>
#include <platform.h>
#include <quadflashlib.h>

// defines
#define SECTORS_PER_TRACK  30
#define TRACKS_PER_DISK    77
#define BYTES_PER_SECTOR   256
#define PROMDISK_SIZE      591360

#define CONTROL_REG  0
#define TRACK_REG    1
#define SECTOR_REG   2
#define DATA_REG     3
#define MODE_REG     4

#define PD_READ      0x84
#define PD_WRITE     0xA4

// ports
// Ports for QuadSPI access.
fl_QSPIPorts ports = {
  PORT_SQI_CS,
  PORT_SQI_SCLK,
  PORT_SQI_SIO,
  on tile[0]: XS1_CLKBLK_1
};

// function prototypes
void promdisk(chanend c_promdisk);

//globals

// List of QuadSPI devices that are supported by default.
 fl_QuadDeviceSpec deviceSpecs[] =
 {
   FL_QUADDEVICE_SPANSION_S25FL116K,
   FL_QUADDEVICE_SPANSION_S25FL132K,
   FL_QUADDEVICE_SPANSION_S25FL164K,
   FL_QUADDEVICE_ISSI_IS25LQ080B,
   FL_QUADDEVICE_ISSI_IS25LQ016B,
   FL_QUADDEVICE_ISSI_IS25LQ032B,
   FL_QUADDEVICE_ISSI_IS25LP032,
};

#endif /* PROMDISK_H_ */
