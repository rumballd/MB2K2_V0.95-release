// Copyright (c) 2016, XMOS Ltd, All rights reserved

// _SELECT_CALLBACK_STACK_SIZE also defined in xcore_c_select_impl.h
#ifdef __XS2A__
# define _SELECT_CALLBACK_STACK_SIZE  2
#else
# define _SELECT_CALLBACK_STACK_SIZE  1
#endif

.text

.globl _xcore_c_select_callback_common
#ifdef __XS2A__
.issue_mode single
#endif
.align 2              // We arrive in single issue mode.
.type  _xcore_c_select_callback_common,@function
.cc_top _xcore_c_select_callback_common.function,_xcore_c_select_callback_common
_xcore_c_select_callback_common:
  // This is the body of the _xcore_c_select_callback_XXX functions.
  // We have an active _SELECT_CALLBACK_STACK_SIZE word sp stack.
  // r1 holds the select_callback_t function to call.
  // event fired viz: clrsr 0x1
  get r11, ed
  add r0, r11, 0
  bla r1              // The select_callback_t function.
  ldw lr, sp[_SELECT_CALLBACK_STACK_SIZE]
  ldaw sp, sp[_SELECT_CALLBACK_STACK_SIZE]
  waiteu              // setsr 0x1
.cc_bottom _xcore_c_select_callback_common.function
.set   _xcore_c_select_callback_common.nstackwords, 0
.globl _xcore_c_select_callback_common.nstackwords
.set   _xcore_c_select_callback_common.maxcores, 1
.globl _xcore_c_select_callback_common.maxcores
.set   _xcore_c_select_callback_common.maxtimers, 0
.globl _xcore_c_select_callback_common.maxtimers
.set   _xcore_c_select_callback_common.maxchanends, 0
.globl _xcore_c_select_callback_common.maxchanends
.size  _xcore_c_select_callback_common, . - _xcore_c_select_callback_common


// We arrived here from select_wait, select_no_wait, select_wait_ordered or select_no_wait_ordered
// in response to an event set up by _resource_setup_select().
.globl _select_non_callback
#ifdef __XS2A__
.issue_mode dual
.align 4
#else
.align 2
#endif
.type  _select_non_callback,@function
.cc_top _select_non_callback.function,_select_non_callback
_select_non_callback:
  // event fired viz: clrsr 0x1
  get r11, ed
#ifdef __XS2A__
  nop                 // handle dual issue.
#endif
  add r0, r11, 0
  retsp 0             // The return from select_wait, select_no_wait, select_wait_ordered or select_no_wait_ordered.
.cc_bottom _select_non_callback.function
.set   _select_non_callback.nstackwords, 0
.globl _select_non_callback.nstackwords
.set   _select_non_callback.maxcores, 1
.globl _select_non_callback.maxcores
.set   _select_non_callback.maxtimers, 0
.globl _select_non_callback.maxtimers
.set   _select_non_callback.maxchanends, 0
.globl _select_non_callback.maxchanends
.size  _select_non_callback, . - _select_non_callback


.globl select_wait
#ifdef __XS2A__
.issue_mode dual
.align 4
#else
.align 2
#endif
.type  select_wait,@function
.cc_top select_wait.function,select_wait
select_wait:
  waiteu              // setsr 0x1
#ifdef __XS2A__
  nop // handle dual issue.
#endif
  // function returns via _select_non_callback
.cc_bottom select_wait.function
.set   select_wait.nstackwords, 0 + _select_non_callback.nstackwords
.globl select_wait.nstackwords
.set   select_wait.maxcores, 1 $M _select_non_callback.maxcores
.globl select_wait.maxcores
.set   select_wait.maxtimers, 0 $M _select_non_callback.maxtimers
.globl select_wait.maxtimers
.set   select_wait.maxchanends, 0 $M _select_non_callback.maxchanends
.globl select_wait.maxchanends
.size  select_wait, . - select_wait


.globl select_no_wait
#ifdef __XS2A__
.issue_mode single
.align 4
#else
.align 2
#endif
.type  select_no_wait,@function
.cc_top select_no_wait.function,select_no_wait
select_no_wait:
#ifdef __XS2A__
  ENTSP_lu6 0
#endif
  setsr 0x1           // Enable events
#if defined(__XS2A__)
  nop                 // Allow channel events to fire
#endif
  // function either returns via _select_non_callback
  // or there was no pending event.
  clrsr 0x1           // Disable events
  retsp 0             // return no_wait_value in r0
.cc_bottom select_no_wait.function
.set   select_no_wait.nstackwords, 0 + _select_non_callback.nstackwords
.globl select_no_wait.nstackwords
.set   select_no_wait.maxcores, 1 $M _select_non_callback.maxcores
.globl select_no_wait.maxcores
.set   select_no_wait.maxtimers, 0 $M _select_non_callback.maxtimers
.globl select_no_wait.maxtimers
.set   select_no_wait.maxchanends, 0 $M _select_non_callback.maxchanends
.globl select_no_wait.maxchanends
.size  select_no_wait, . - select_no_wait


.globl select_wait_ordered
#ifdef __XS2A__
.issue_mode single
.align 4
#else
.align 2
#endif
.type  select_wait_ordered,@function
.cc_top select_wait_ordered.function,select_wait_ordered
select_wait_ordered:
#ifdef __XS2A__
  ENTSP_lu6 0
#endif
  clre                // disable all 'select event' resources
  setsr 0x1           // Enable events on core
  ldc r2, 0           // Resource list index
  // Enable each individual resource in the list in order
select_wait_ordered_loop:
  ldw r3, r0[r2]
  bf r3, select_wait_ordered_done
  eeu res[r3]
  add r2, r2, 1
  bu select_wait_ordered_loop
select_wait_ordered_done:
  waiteu              // setsr 0x1
  // function returns via _select_non_callback
.cc_bottom select_wait_ordered.function
.set   select_wait_ordered.nstackwords, 0 + _select_non_callback.nstackwords
.globl select_wait_ordered.nstackwords
.set   select_wait_ordered.maxcores, 1 $M _select_non_callback.maxcores
.globl select_wait_ordered.maxcores
.set   select_wait_ordered.maxtimers, 0 $M _select_non_callback.maxtimers
.globl select_wait_ordered.maxtimers
.set   select_wait_ordered.maxchanends, 0 $M _select_non_callback.maxchanends
.globl select_wait_ordered.maxchanends
.size  select_wait_ordered, . - select_wait_ordered


.globl select_no_wait_ordered
#ifdef __XS2A__
.issue_mode single
.align 4
#else
.align 2
#endif
.type  select_no_wait_ordered,@function
.cc_top select_no_wait_ordered.function,select_no_wait_ordered
select_no_wait_ordered:
#ifdef __XS2A__
  ENTSP_lu6 0
#endif
  clre                // disable all 'select event' resources
  setsr 0x1           // Enable events on core
  ldc r2, 0           // Resource list index
  // Enable each individual resource in the list in order
select_no_wait_ordered_loop:
  ldw r3, r1[r2]
  bf r3, select_no_wait_ordered_done
  eeu res[r3]
  add r2, r2, 1
  bu select_no_wait_ordered_loop
select_no_wait_ordered_done:
  // function either returns via _select_non_callback
  // or there was no pending event.
  clrsr 0x1           // Disable events
  retsp 0             // return no_wait_value in r0
.cc_bottom select_no_wait_ordered.function
.set   select_no_wait_ordered.nstackwords, 0 + _select_non_callback.nstackwords
.globl select_no_wait_ordered.nstackwords
.set   select_no_wait_ordered.maxcores, 1 $M _select_non_callback.maxcores
.globl select_no_wait_ordered.maxcores
.set   select_no_wait_ordered.maxtimers, 0 $M _select_non_callback.maxtimers
.globl select_no_wait_ordered.maxtimers
.set   select_no_wait_ordered.maxchanends, 0 $M _select_non_callback.maxchanends
.globl select_no_wait_ordered.maxchanends
.size  select_no_wait_ordered, . - select_no_wait_ordered
