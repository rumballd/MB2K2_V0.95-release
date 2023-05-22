// Copyright (c) 2013-2016, XMOS Ltd, All rights reserved

#include <xs1.h>

.cc_top trycatch_trap_handler.function
.globl trycatch_trap_handler
.type trycatch_trap_handler, @function
.align XS1_KEP_ALIGNMENT
#ifdef __XS2A__
.issue_mode single
trycatch_trap_handler:
  ENTSP_lu6 0
#else
trycatch_trap_handler:
#endif
  // No need to save state since we end by calling longjmp.

  // Set sp to trycatch_state.
  get r11, id
  ldc r0, 3 * 4
  mul r0, r0, r11
  ldap r11, trycatch_state
  add r0, r0, r11
  set sp, r0

  // Set the spc to return_from_exception.
  ldap r11, return_from_exception
  stw r11, sp[1]
  ldw spc, sp[1]

  // Store et and ed.
  get r11, et
#ifdef __XS2A__
  // An additional et bit (0x16) indicates
  // the lane that caused the exception.
  zext r11, 4
#endif
  stw r11, sp[0]
  get r11, ed
  stw r11, sp[1]

  // Leave kernel mode.
  kret

#ifdef __XS2A__
.align 4
.issue_mode single
return_from_exception:
  // Call longjump.
  ENTSP_lu6 0
#else
.align 2
return_from_exception:
  // Call longjump.
#endif
  ldw r0, sp[2]
  ldc r1, 1
  bu longjmp
.size trycatch_trap_handler, .-trycatch_trap_handler
.cc_bottom trycatch_trap_handler.function
