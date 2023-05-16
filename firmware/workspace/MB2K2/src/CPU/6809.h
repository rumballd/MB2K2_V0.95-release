/*
 * Copyright 2001 by Arto Salmi and Joze Fabcic
 * Copyright 2006 by Brian Dominy <brian@oddchange.com>
 *
 * This file is part of GCC6809.
 *
 * GCC6809 is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * GCC6809 is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with GCC6809; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */


#ifndef M6809_H
#define M6809_H

#include <xs1.h>
#include <platform.h>

#include "xcore_c.h"

#define E_FLAG 0x80
#define F_FLAG 0x40
#define H_FLAG 0x20
#define I_FLAG 0x10
#define N_FLAG 0x08
#define Z_FLAG 0x04
#define V_FLAG 0x02
#define C_FLAG 0x01

#define RDMEM(addr) read8 (addr)
#define WRMEM(addr, data) write8 (addr, data)

#define write_stack WRMEM
#define read_stack  RDMEM

#define BYTE_READ   0x00000000
#define BYTE_WRITE  0x80000000
#define WORD_READ   0x01000000
#define WORD_WRITE  0x81000000


typedef signed char INT8;
typedef signed short INT16;
typedef signed int INT32;


/* 6809.c */
void cpu_execute (chanend c_addrData);
extern void cpu_reset (void);




#endif /* M6809_H */
