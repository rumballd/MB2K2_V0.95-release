// Copyright (c) 2016, XMOS Ltd, All rights reserved
/* This sets the variable 'DFU_reset_override' to exists at the end of the
   heap. This means it will not be overwritten by the boot procedure after
   a soft reset and provides a storage location to persist through a reset.
 */
.linkset DFU_reset_override, _edp.bss
.globl DFU_reset_override
