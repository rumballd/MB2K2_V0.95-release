// Copyright (c) 2014-2016, XMOS Ltd, All rights reserved
#ifndef __gpio_h__
#define __gpio_h__
#include <stdint.h>
#include <stddef.h>

#ifdef __XC__

typedef uint16_t gpio_time_t;

/** This interface provides access to a GPIO that can perform input
    operations only. All GPIOs are single bit. */
typedef interface input_gpio_if
{
  /** Perform an input on a GPIO
   *
   *  \returns The value input from the port in the least significant bit.
   *           The rest of the value will be zero extended.
   */
 unsigned input(void);

  /** Perform an input on a GPIO and get a timestamp
   *
   *  \param   timestamp  This pass-by-reference parameter will be set
   *                      to the time the value was input. This timestamp
   *                      is the 16-bit port timer value. The port timer is
   *                      driven at the rate of the port clock.
   *
   *  \returns The value input from the port in the least significant bit.
   *           The rest of the value will be zero extended.
   */
 unsigned input_and_timestamp(gpio_time_t &timestamp);

 /** Request an event when the pin is a certain value.
  *
  *  This function will cause a notification to occur when the pins
  *  match the specified value.
  *
  *  \param val   The least significant bit represents the 1-bit value to match.
  */
 [[clears_notification]]
 void event_when_pins_eq(unsigned val);

 /** A pin event has occurred.
  *
  *  This notification will occur when a pin event has occurred.
  *  Events can be requested using the event_when_pins_eq() call.
  */
 [[notification]]
 slave void event(void);

} input_gpio_if;

/** This interface provides access to a GPIO that can perform output
    operations only.  All GPIOs are single bit. */
typedef interface output_gpio_if
{
  /** Perform an output on a GPIO.
   *
   *  \param data  The value to be output. The least significant bit
   *               represents the 1-bit value to be output.
   */
 void output(unsigned data);

  /** Perform an output on a GPIO and get a timestamp of when the output
   *  occurs.
   *
   *  \param data  The value to be output. The least significant bit
   *               represents the 1-bit value to be output.
   *
   *  \returns     The time the value was input. This timestamp
   *               is the 16-bit port timer value. The port timer is driven
   *               at the rate of the port clock.
   */
 gpio_time_t output_and_timestamp(unsigned data);
} output_gpio_if;


/** Task that splits a multi-bit port into several 1-bit GPIO interfaces.
 *
 * This component allows other tasks to access the individual bits of
 * a multi-bit output port.
 *
 * \param   i         The array of interfaces to connect to other tasks.
 * \param   n         The number of interfaces connected.
 * \param   p         The output port to be split.
 * \param   pin_map   This array maps the connected interfaces to the pin
 *                    of the port. For example, if 3 clients are connected
 *                    to split a 8-bit port and the array {2,5,3} is supplied.
 *                    Then bit 2 will go to interface 0, bit 5 to inteface 1
 *                    and bit 3 to inteface 2. If null is supplied for this
 *                    argument then the pin map is assumed to be {0,1,2...}.
 */
[[distributable]]
void output_gpio(server output_gpio_if i[n], static const size_t n, out port p,
                 char (&?pin_map)[n]);

/** Task that splits a multi-bit input port into several 1-bit GPIO interfaces
 * (no events).
 *
 * This component allows other tasks to access the individual bits of
 * a multi-bit input port. It does not support events but is distributable so
 * requires no specific logical core to run on. If the event_when_pins_eq()
 * function is called then the component will trap.
 *
 * \param   i         The array of interfaces to connect to other tasks.
 * \param   n         The number of interfaces connected.
 * \param   p         The input port to be split.
 * \param   pin_map   This array maps the connected interfaces to the pin
 *                    of the port. For example, if 3 clients are connected
 *                    to split a 8-bit port and the array {2,5,3} is supplied.
 *                    Then bit 2 will go to interface 0, bit 5 to inteface 1
 *                    and bit 3 to inteface 2. If null is supplied for this
 *                    argument then the pin map is assumed to be {0,1,2...}.
 */
[[distributable]]
void input_gpio(server input_gpio_if i[n], static const size_t n, in port p,
                char (&?pin_map)[n]);

/* Task that splits a multi-bit input port into several 1-bit GPIO interfaces
 * (with events).
 *
 * This component allows other tasks to access the individual bits of
 * a multi-bit input port. It does support events so requires a logical
 * core to run on (but can be combined with other tasks on the same core).
 *
 * \param   i         The array of interfaces to connect to other tasks.
 * \param   n         The number of interfaces connected.
 * \param   p         The input port to be split.
 * \param   pin_map   This array maps the connected interfaces to the pin
 *                    of the port. For example, if 3 clients are connected
 *                    to split a 8-bit port and the array {2,5,3} is supplied.
 *                    Then bit 2 will go to interface 0, bit 5 to inteface 1
 *                    and bit 3 to inteface 2. If null is supplied for this
 *                    argument then the pin map is assumed to be {0,1,2...}.
 */
[[combinable]]
void input_gpio_with_events(server input_gpio_if i[n],
                            static const size_t n,
                            in port p,
                            char (&?pin_map)[n]);

/** Convert a 1-bit port to a single 1-bit GPIO interface.
 *
 * This component allows other tasks to access a 1-bit port as a GPIO
 * interface. It is more efficient that using input_gpio_with_events() for the
 * restricted case where a 1-bit port is used.
 *
 * \param   i         The interface to connect to other tasks.
 * \param   p         The input port.
 */
[[combinable]]
void input_gpio_1bit_with_events(server input_gpio_if i, in port p);

#endif
#endif // __gpio_h__
