/*
 * memory.h
 *
 *  Created on: 15 Jul 2019
 *      Author: david
 */


#ifndef MEMORY_H_
#define MEMORY_H_

#include <xs1.h>
#include <platform.h>
#include "xassert.h"

// defines
#define BYTE_READ   0x00000000
#define BYTE_WRITE  0x80000000
#define WORD_READ   0x01000000
#define WORD_WRITE  0x81000000

#define MEM_SIZE  65536

// function prototypes
extern void decodeMem(chanend c_addrData, chanend c_acia, chanend c_rtc,
                      chanend c_pia, chanend c_ramdisk, chanend c_promdisk,
                      chanend c_gdc, chanend c_tmr);

extern void reset_cpu(void);

//globals
#include "mem.h"    // 64KB array with MON09 and FLEX binaries pre-loaded
#include "shadow.h" // 4KB array with character set pre-loaded

#endif /* MEMORY_H_ */
