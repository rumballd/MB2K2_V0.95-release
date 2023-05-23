// Copyright (c) 2016, XMOS Ltd, All rights reserved

#ifdef __XS2A__
# define _XCORE_C_STACK_ALIGN(n)   ((n+1)/2)*2
#else
# define _XCORE_C_STACK_ALIGN(n)   n
#endif

.globl _xcore_c_interrupt_permitted_common
.align 2  // We arrive in single issue mode.
.type  _xcore_c_interrupt_permitted_common,@function
.cc_top _xcore_c_interrupt_permitted_common.function,_xcore_c_interrupt_permitted_common
_xcore_c_interrupt_permitted_common:
  // This is the body of the __xcore_c_interrupt_permitted_XXX functions.
  // We have an active _XCORE_C_STACK_ALIGN(3) word sp frame.
  // sp[2] = saved r5
  // sp[1] = saved r4
  // sp[0] will be trashed when we set up the kstack.
  // r0-3 = the original arguments not to be touched.
  // r4 = kstack words needed.
  // r5 = root_function.
  // Set up the kstack on our stack.
  ldaw r11, sp[0]
  ldaw r11, r11[-r4]  // Where the sp will be moved to.
  stw r11, sp[0]      // Make the current sp the ksp.
  ldaw r4, sp[0]      // Keep a record of the current sp
  krestsp 0           // Pop the new sp.
  // Call the root_function.
  bla r5
  set sp, r4          // Pop the kstack from our stack (making ksp invalid).
  // And return.
  ldw r4, sp[1]
  ldw r5, sp[2]
  retsp _XCORE_C_STACK_ALIGN(3)
.cc_bottom _xcore_c_interrupt_permitted_common.function
.set   _xcore_c_interrupt_permitted_common.nstackwords, 0
.globl _xcore_c_interrupt_permitted_common.nstackwords
.set   _xcore_c_interrupt_permitted_common.maxcores, 1
.globl _xcore_c_interrupt_permitted_common.maxcores
.set   _xcore_c_interrupt_permitted_common.maxtimers, 0
.globl _xcore_c_interrupt_permitted_common.maxtimers
.set   _xcore_c_interrupt_permitted_common.maxchanends, 0
.globl _xcore_c_interrupt_permitted_common.maxchanends
.size  _xcore_c_interrupt_permitted_common, . - _xcore_c_interrupt_permitted_common


.globl _xcore_c_interrupt_callback_common
.align 2  // We arrive in single issue mode.
.type  _xcore_c_interrupt_callback_common,@function
.cc_top _xcore_c_interrupt_callback_common.function,_xcore_c_interrupt_callback_common
_xcore_c_interrupt_callback_common:
  // This is the body of the _xcore_c_interrupt_callback_XXX functions.
  // We have an active _XCORE_C_STACK_ALIGN(7) word ksp frame.
  // r1 = interrupt_callback_t function
  stw lr, sp[6]
  // ksp[5] = r11
  stw r0, sp[4]
  // ksp[3] = r1
  stw r2, sp[2]
  stw r3, sp[1]
  // ksp[0] will be trashed by the bla.
  // And call the interrupt_callback_t.
  get r11, ed
  add r0, r11, 0
  bla r1
  // Restore the state and return.
  ldw r3, sp[1]
  ldw r2, sp[2]
  ldw r1, sp[3]
  ldw r0, sp[4]
  ldw r11, sp[5]
  ldw lr, sp[6]
  krestsp _XCORE_C_STACK_ALIGN(7)
  kret
.cc_bottom _xcore_c_interrupt_callback_common.function
.set   _xcore_c_interrupt_callback_common.nstackwords, 0
.globl _xcore_c_interrupt_callback_common.nstackwords
.set   _xcore_c_interrupt_callback_common.maxcores, 1
.globl _xcore_c_interrupt_callback_common.maxcores
.set   _xcore_c_interrupt_callback_common.maxtimers, 0
.globl _xcore_c_interrupt_callback_common.maxtimers
.set   _xcore_c_interrupt_callback_common.maxchanends, 0
.globl _xcore_c_interrupt_callback_common.maxchanends
.size  _xcore_c_interrupt_callback_common, . - _xcore_c_interrupt_callback_common
