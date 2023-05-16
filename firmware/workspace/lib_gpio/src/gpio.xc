// Copyright (c) 2014-2016, XMOS Ltd, All rights reserved
#include <xs1.h>
#include <gpio.h>
#include <xassert.h>
#include <print.h>

[[distributable]]
void input_gpio(server input_gpio_if i[n], static const size_t n,
                in port p, char (&?pin_map)[n])
{
  char *pmap;
  char default_pmap[n];
  if (!isnull(pin_map)) {
    pmap = pin_map;
  }
  else {
    pmap = default_pmap;
    for (size_t i = 0; i < n; i++)
      pmap[i] = i;
  }
  while (1) {
    select {
    case i[int j].input() -> unsigned result:
      unsigned pos = pmap[j];
      p :> result;
      result = (result >> pos) & 1;
      break;
    case i[int j].input_and_timestamp(gpio_time_t &ts) -> unsigned result:
      unsigned pos = pmap[j];
      p :> result @ ts;
      result = (result >> pos) & 1;
      break;
    case i[int j].event_when_pins_eq(unsigned value):
      fail("input_gpio task does not support events.");
      break;
    }
  }
}


#pragma unsafe arrays
[[combinable]]
void input_gpio_with_events(server input_gpio_if i[n],
                            static const size_t n,
                            in port p,
                            char (&?pin_map)[n])
{
  char *pmap;
  char default_pmap[32];
  if (!isnull(pin_map)) {
    pmap = pin_map;
  }
  else {
    pmap = default_pmap;
    for (size_t i = 0; i < n; i++)
      pmap[i] = i;
  }
  unsigned pval = 0;
  char test_vals[32];
  unsigned waiting = 0;
  for (size_t j = 0; j < n; j++)
    test_vals[j] = -1;
  while (1) {
    select {
    case i[int j].input() -> unsigned result:
      unsigned pos = pmap[j];
      p :> result;
      result = (result >> pos) & 1;
      break;
    case i[int j].input_and_timestamp(gpio_time_t &ts) -> unsigned result:
      unsigned pos = pmap[j];
      p :> result @ ts;
      result = (result >> pos) & 1;
      break;
    case i[int j].event_when_pins_eq(unsigned value):
      unsigned val;
      p :> val;
      unsigned pos = pmap[j];
      unsigned bit = (val >> pos) & 1;
      if (bit == value)
        i[j].event();
      else {
        if (test_vals[j] != -1)
          waiting++;
        test_vals[j] = value;
      }
      break;
    case waiting => p when pinsneq(pval) :> pval:
      for (size_t j = 0; j < n; j++) {
        unsigned pos = pmap[j];
        unsigned bit = (pval >> pos) & 1;
        if (bit == test_vals[j]) {
          test_vals[j] = -1;
          waiting--;
          i[j].event();
        }
      }
      break;
    }
  }
}



[[combinable]]
void input_gpio_1bit_with_events(server input_gpio_if i, in port p)
{
  unsigned test_val = -1;
  while (1) {
    select {
    case i.input() -> unsigned result:
      p :> result;
      break;
    case i.input_and_timestamp(gpio_time_t &ts) -> unsigned result:
      p :> result @ ts;
      break;
    case i.event_when_pins_eq(unsigned value):
      test_val = value;
      break;
    case (test_val != -1) => p when pinseq(test_val) :> int:
      i.event();
      test_val = -1;
      break;
    }
  }
}



[[distributable]]
void output_gpio(server output_gpio_if i[n], static const size_t n, out port p,
                 char (&?pin_map)[n])
{
  char *pmap;
  char default_pmap[n];
  if (!isnull(pin_map)) {
    pmap = pin_map;
  }
  else {
    pmap = default_pmap;
    for (size_t i = 0; i < n; i++)
      pmap[i] = i;
  }
  unsigned current_val = 0;
  while (1) {
    select {
    case i[int j].output(unsigned data):
      unsigned pos = pmap[j];
      current_val &= ~(1 << pos);
      current_val |= ((data & 1) << pos);
      p <: current_val;
      break;

    case i[int j].output_and_timestamp(unsigned data) -> gpio_time_t ts:
      unsigned pos = pmap[j];
      current_val &= ~(1 << pos);
      current_val |= ((data & 1) << pos);
      p <: current_val @ ts;
      break;
    }
  }
}
