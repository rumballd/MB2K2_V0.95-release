// Copyright (c) 2014-2018, XMOS Ltd, All rights reserved

#ifndef _uart_h_
#define _uart_h_
#include <stdint.h>
#include <stddef.h>
#include <xs1.h>
#include <gpio.h>

#ifdef __XC__

/** Type representing the parity of a UART */
typedef enum uart_parity_t {
  UART_PARITY_EVEN = 0, ///< Even parity.
  UART_PARITY_ODD = 1,  ///< Odd parity.
  UART_PARITY_NONE      ///< No parity.
} uart_parity_t;

/** UART configuration interface.
 *
 *  This interface enables dynamic reconfiguration of a UART. It is used by
 *  several UART components to provide a method of configuration.
 */
typedef interface uart_config_if {
  /** Set the baud rate of a UART.
   */
  void set_baud_rate(unsigned baud_rate);

  /** Set the parity of a UART.
   */
  void set_parity(enum uart_parity_t parity);

  /** Set number of stop bits used by a UART.
   */
  void set_stop_bits(unsigned stop_bits);

  /** Set number of bits per byte used by a UART (must be in the range [1-8])
   */
  void set_bits_per_byte(unsigned bits_per_byte);
} uart_config_if;


/*---------------------- Receiver API ---------------------------*/

/** UART RX interface.
 *
 *   This interface provides clients access to buffer uart receive
 *   functionality.
 */
typedef interface uart_rx_if {
  /** Get a byte from the receive buffer.
   *
   *   This function should be called after receiving a data_ready()
   *   notification. If these is no data in the buffer (for example, this
   *   function is called before receiving a notification) then the return
   *   value is undefined.
   */
  [[clears_notification]] uint8_t read(void);

  /** Notification that data is in the receive buffer.
   *
   *   This notification function can be selected on by the client and
   *   will event when the is data in the receive buffer. After this
   *   notification the client should call the read() function.
   */
  [[notification]] slave void data_ready(void);

  /** Returns whether there is data in the buffer.
   */
  int has_data();
} uart_rx_if;

extends client interface uart_rx_if : {

  /** Get a byte from the receive buffer.
   *
   *   This function will wait until there is data in the receive buffer
   *   of the uart and then fetch that data. On getting the data, it
   *   will clear the notification flag on the interface.
   */
  inline uint8_t wait_for_data_and_read(client uart_rx_if i) {
    if (!i.has_data()) {
      select {
      case i.data_ready():
        break;
      }
    }
    return i.read();
  }
}

/** UART RX.
 *
 *    This function runs a uart receiver.
 *    Bytes received by the this task are buffered.
 *    When the buffer is full further incoming bytes of data will be dropped.
 *    The function never returns and will run indefinitely.
 *
 *    \param i_data        the interface connection allowing clients to
 *                         receive data
 *    \param i_config      the interface connection allowing clients to
 *                         reconfigure the UART
 *    \param buffer_size   the size of the buffer
 *    \param baud          the initial baud rate
 *    \param parity        the initial parity setting
 *    \param bits_per_byte the initial number of bits per byte (must be
 *                         in the range [1-8])
 *    \param stop_bits     the initial number of stop bits
 *    \param p_rxd         the gpio interface to input data on
 */
[[combinable]]
void uart_rx(server interface uart_rx_if i_data,
             server interface uart_config_if ?i_config,
             const static unsigned buffer_size,
             unsigned baud,
             enum uart_parity_t parity,
             unsigned bits_per_byte,
             unsigned stop_bits,
             client input_gpio_if p_rxd);

/** Fast/Streaming UART RX.
 *
 * This function implements a fast UART. The UART configuration is
 * fixed to a single start bit, 8 bits per byte, and a single stop bit.
 * On a 62.5 MIPS thread this function should be able to keep up with a 10
 * MBit UART sustained (provided that the streaming channel can keep up
 * with it too).
 *
 * This function does not return.
 *
 * \param p      input port, 1 bit port on which data comes in.
 *
 * \param c      output streaming channel to connect to the application.
 *
 * \param ticks_per_bit  number of clock ticks between bits.
 *                       This number depends on the clock that is
 *                       attached to port p. If it is the
 *                       100 Mhz reference clock then this value
 *                       should be at least 10.
 */
void uart_rx_streaming(in port p, streaming chanend c, int ticks_per_bit);

/** Receive a byte from a streaming UART receiver.
 *
 *  This function receives a byte from the fast/streaming UART component. It is
 *  "select handler" so can be used within a select e.g.
 *
    \verbatim
     uint8_t byte;
     size_t index;
     select {
       case uart_rx_streaming_receive_byte(c, byte):
            // use sample and index here...
            ...
            break;
     ...
    \endverbatim
 *
 *   The case in this select will fire when the UART component has data ready.
 *
 *   \param c       chanend connected to the streaming UART receiver component
 *   \param data    This reference parameter gets set with the incoming
 *                  data
 */
#pragma select handler
void uart_rx_streaming_read_byte(streaming chanend c, uint8_t &data);

/*---------------------- Transmitter API ---------------------------*/

/** UART transmit interface.
 *
 *  This interface provides functions for transmitting data on an
 *  unbuffered UART.
 */
typedef interface uart_tx_if {

  /** Write a byte to a UART.
   *
   *  This function writes a byte of data to a UART. It will output
   *  immediately and block until the data is output.
   *
   *  \param data  The data to write.
   */
  void write(uint8_t data);
} uart_tx_if;


/** UART transmitter.
 *
 *  This function implements an unbuffered UART transmitter.
 *
 *    \param i_data        interface enabling client to send data
 *    \param i_config      interface enabling client to configure the UART
 *    \param baud          the initial baud rate
 *    \param parity        the initial parity setting
 *    \param bits_per_byte the initial number of bits per byte (must be in
 *                         the range [1-8])
 *    \param stop_bits     the initial number of stop bits
 *    \param p_txd         the gpio interface to output data on

 */
[[distributable]]
void uart_tx(server interface uart_tx_if i_data,
             server interface uart_config_if ?i_config,
             unsigned baud,
             uart_parity_t parity,
             unsigned bits_per_byte,
             unsigned stop_bits,
             client output_gpio_if p_txd);

/** UART transmit interface (buffered).
 *
 *  This interface contains functions to write to a buffered UART and
 *  manage the buffering.
 *
 */
typedef interface uart_tx_buffered_if {

  /** Write a byte to a UART.
   *
   *  This function writes a byte of data to a UART. It will place the
   *  data in the output buffer queue to write and then return. If the
   *  buffer is full then the data is discarded.
   *
   *  \param data  The data to write.
   *
   *  \returns     Zero if the write was successful. If the buffer was
   *               full then the function will return 1 and the data is
   *               discarded.
   */
  [[clears_notification]]
  int write(uint8_t data);

  /** Ready to transmit notification.
   *
   *  This notification will occur when the UART is ready to transmit (either
   *  intially or after a write() call when there is space in the buffer).
   */
  [[notification]]
  slave void ready_to_transmit(void);

  /** Get avaiable buffer size.
   *
   *  This function returns the number of bytes remaining in the buffer that
   *  can be filled by write() calls.
   */
  size_t get_available_buffer_size(void);
} uart_tx_buffered_if;

/** UART transmitter (buffered).
 *
 *  This function implements a UART transmitter. Data sent to the task will
 *  be placed in a buffer and sent at the rate of the UART.
 *
 *    \param i_data        interface enabling client to send data
 *    \param i_config      interface enabling client to configure the UART
 *    \param buffer_size   the size of the transmit buffer in bytes
 *    \param baud          the initial baud rate
 *    \param parity        the initial parity setting
 *    \param bits_per_byte the initial number of bits per byte (must be in
 *                         the range [1-8])
 *    \param stop_bits     the initial number of stop bits
 *    \param p_txd         the gpio interface to output data on
 */
[[combinable]]
void uart_tx_buffered(server interface uart_tx_buffered_if i_data,
                      server interface uart_config_if ?i_config,
                      const static unsigned buffer_size,
                      unsigned baud,
                      uart_parity_t parity,
                      unsigned bits_per_byte,
                      unsigned stop_bits,
                      client output_gpio_if p_txd);

/** Fast/Streaming UART TX.
 *
 * This function implements a fast UART transmitter.
 * It needs an unbuffered 1-bit
 * port, a streaming channel end, and a number of port-clocks to wait
 * between bits. It receives a start bit, 8 bits, and a stop bit, and
 * transmits the 8 bits over the streaming channel end as a single token.
 * On a 62.5 MIPS thread this function should be able to keep up with a 10
 * MBit UART sustained (provided that the streaming channel can keep up
 * with it too).
 *
 * This function does not return.
 *
 * \param p      input port, 1 bit port on which data comes in.
 *
 * \param c      output streaming channel to connect to the application.
 *
 * \param ticks_per_bit  number of clock ticks between bits.
 *                       This number depends on the clock that is
 *                       attached to port p. If it is the
 *                       100 Mhz reference clock then this value
 *                       should be at least 10.
 */
void uart_tx_streaming(out port p, streaming chanend c, int ticks_per_bit);

/** Write a byte to a streaming UART transmitter.
 *
 *  This function writes a
 *   \param c       chanend connected to the streaming UART Tx component
 *   \param data    The data to send.
 */
void uart_tx_streaming_write_byte(streaming chanend c, uint8_t data);


/*---------------------- Half Duplex API ---------------------------*/

/** Type representing the mode (direction) of a uart. */
typedef enum uart_half_duplex_mode_t {
  UART_RX_MODE, ///<  Uart is in receive mode.
  UART_TX_MODE  ///<  Uart is in transmit mode.
} uart_half_duplex_mode_t;

/** Interface to control the mode of a half-duplex UART */
typedef interface uart_control_if {
  /** Set the mode of the UART.
   *
   *  This function can be used to control whether the UART is in send or
   *  receive mode.
   */
  void set_mode(uart_half_duplex_mode_t mode);
} uart_control_if;

/** Half duplex UART.
 *
 *  This function implements a UART that can either transmit or receive on
 *  the same wire. The application explicitly control whether the component
 *  is in transmit or receive mode.
 *
 *  \param i_tx           interface for transmitting data
 *  \param i_rx           interface for receiving data
 *  \param i_control      interface for controlling the direction of the UART
 *  \param i_config       interface for configuring the UART
 *  \param tx_buf_length  the size of the transmit buffer (in bytes)
 *  \param rx_buf_length  the size of the receive buffer (in bytes)
 *  \param baud           baud rate
 *  \param parity         the parity of the UART
 *  \param bits_per_byte  bits per byte (must be in the range [1-8])
 *  \param stop_bits      The number of stop bits
 *  \param p_uart         the 1-bit port to send/recieve the UART signals.
 */
void uart_half_duplex(server interface uart_tx_buffered_if i_tx,
                      server interface uart_rx_if i_rx,
                      server interface uart_control_if i_control,
                      server interface uart_config_if ?i_config,
                      const static unsigned tx_buf_length,
                      const static unsigned rx_buf_length,
                      unsigned baud,
                      uart_parity_t parity,
                      unsigned bits_per_byte,
                      unsigned stop_bits,
                      port p_uart);

/*---------------------- Multi-UART API ---------------------------*/

typedef enum multi_uart_read_result_t {
  UART_RX_VALID_DATA,   ///< Data received is valid.
  UART_RX_INVALID_DATA  ///< Data received is not valid.
} multi_uart_read_result_t;

/** Multi-UART receive interface */
interface multi_uart_rx_if {

  /** Initialize the multi-UART RX component.
   *
   *  \param   c    The chanend connected to the multi-UART RX task
   */
  void init(streaming chanend c);

  /** Read a byte for the next UART with ready data.
   *
   *  This function will read out a byte from the next UART with data available.
   *  If several UARTS have data available then the data is read out in a
   *  round-robin fashion.
   *
   *  \param  index        This index of the UART to read from
   *  \param  data         The data byte read
   *  \returns             An enum type that indicates if the data is valid
   */
  enum multi_uart_read_result_t read(size_t index, uint8_t &data);

  /** Pause the multi-UART RX component for reconfiguration.
   *
   *  This call will stop the mulit-UART component so that the UARTs can be
   *  reconfigured.
   */
  void pause(void);

  /** Restart the multi-UART RX component after reconfiguration.
   *
   *  This call will restart the multi-UART component.
   */
  void restart(void);

  /** Set the baud rate of a UART.
   *
   *  This call will set the baud rate of one of the UARTs.
   *  The rate must be a divisor of the clock rate of the underlying
   *  clock used for the component.
   *
   *  \param   index       The index of the UART to configure
   *  \param   baud_rate   The required baud rate
   */
  void set_baud_rate(size_t index, unsigned baud_rate);

  /** Set parity of a UART.
   *
   *  This call will set the parity of one of the UARTs.
   *  The rate must be a divisor of the clock rate of the underlying
   *  clock used for the component.
   *
   *  \param   index       The index of the UART to configure.
   *  \param   parity      The required parity
   */
  void set_parity(size_t index, enum uart_parity_t parity);

  /** Set the number of stop bits of a UART.
   *
   *  This call will set the number of stop bits of one of the UARTs.
   *
   *  \param   index       The index of the UART
   *  \param   stop_bits   The number of stop bits
   */
  void set_stop_bits(size_t index, unsigned stop_bits);

  /** Set the number of bit per byte of a UART.
   *
   *  This call will set the number of stop bits of one of the UARTs.
   *
   *  \param   index          The index of the UART
   *  \param   bits_per_byte  The number of bits per byte (must be in the
   *                          range [1-8])
   */
  void set_bits_per_byte(size_t index, unsigned bits_per_byte);
} [[sametile]];

typedef interface multi_uart_rx_if multi_uart_rx_if;

#pragma select handler
inline void multi_uart_data_ready(streaming chanend c_rx, size_t &index);

/** Multi-UART receiver.
 *
 *  This function implements multiple UART receivers on a multi-bit port. The
 *  UARTS all have the same baud rate.
 *  The parity, bits per byte and number of stop bits
 *  is the same for all UARTs and cannot be changed dynamically.
 *
 *  \param  c               a chanend used internally for high speed communication
 *  \param  i               the interface for getting data from the task
 *  \param  p               the multibit port
 *  \param  clk             a clock block for the component to use. This needs
 *                          to be set to run of the reference clock (the default
 *                          state for clock blocks)
 *  \param  num_uarts       the number of uarts to run (must be less than or
 *                          equal to the width of \p p)
 *  \param  clock_rate_hz   the clock rate in Hz
 *  \param  baud            baud rate
 *  \param  parity          the parity of the UART
 *  \param  bits_per_byte   bits per byte (must be in the range [1-8])
 *  \param  stop_bits       number of stop bits
 */
void multi_uart_rx(streaming chanend c,
                   server interface multi_uart_rx_if i,
                   in buffered port:32 p, clock clk,
                   size_t num_uarts,
                   unsigned clock_rate_hz,
                   unsigned baud,
                   enum uart_parity_t parity,
                   unsigned bits_per_byte,
                   unsigned stop_bits);

/** Multi-UART transmit interface */
interface multi_uart_tx_if {

  /** Initialize the multi-UART TX component.
   *
   *  \param   c    The chanend connected to the multi-UART TX task
   */
  void init(chanend c);

  /** Check whether transmit slot is free.
   *
   *  This function checks whether the application can write data to
   *  a specific UART.
   *
   *  \param  index     The index of the UART to check
   *  \returns          non-zero if the slot is free (i.e. data can be sent)
   */
  int is_slot_free(size_t index);

  /** Write to a UART.
   *
   *  This function writes a byte of data to a UART. This byte will be buffered
   *  to send. If the transmit buffer for
   *  that UART is not available then the data is ignored (use
   *  is_tx_slot_free() to determine availability).
   *
   *  \param  index      The index of the UART to write to
   *  \param  data       The data to write
   */
  void write(size_t index, uint8_t data);

  /** Pause the multi-UART RX component for reconfiguration.
   *
   *  This call will stop the mulit-UART component so that the UARTs can be
   *  reconfigured.
   */
  void pause(void);

  /** Restart the multi-UART RX component after reconfiguration.
   *
   *  This call will restart the multi-UART component.
   */
  void restart(void);

  /** Set the baud rate of a UART.
   *
   *  This call will set the baud rate of one of the UARTs.
   *  The rate must be a divisor of the clock rate of the underlying
   *  clock used for the component.
   *
   *  \param   index       The index of the UART to configure.
   *  \param   baud_rate   The required baud rate
   */
  void set_baud_rate(size_t index, unsigned baud_rate);

  /** Set parity of a UART.
   *
   *  This call will set the parity of one of the UARTs.
   *  The rate must be a divisor of the clock rate of the underlying
   *  clock used for the component.
   *
   *  \param   index       The index of the UART to configure.
   *  \param   parity      The required parity
   */
  void set_parity(size_t index, enum uart_parity_t parity);

  /** Set the number of stop bits of a UART.
   *
   *  This call will set the number of stop bits of one of the UARTs.
   *
   *  \param   index       The index of the UART
   *  \param   stop_bits   The number of stop bits
   */
  void set_stop_bits(size_t index, unsigned stop_bits);

  /** Set the number of bit per byte of a UART.
   *
   *  This call will set the number of stop bits of one of the UARTs.
   *
   *  \param   index          The index of the UART
   *  \param   bits_per_byte  The number of bits per byte (must be in the
   *                          range [1-8])
   */
  void set_bits_per_byte(size_t index, unsigned bits_per_byte);
} [[sametile]];

typedef interface multi_uart_tx_if multi_uart_tx_if;

/** Multi-UART transmitter.
 *
 *  This function implements multiple UART transmiiters on a multi-bit port. The
 *  UARTS all have the same baud rate.
 *  The parity, bits per byte and number of stop bits
 *  is the same for all UARTs and cannot be changed dynamically.
 *
 *  \param  c               a chanend used internally for high speed communication
 *  \param  i               the interface for sending data to the task
 *  \param  p               the multibit port
 *  \param  num_uarts       the number of uarts to run (must be less than or
 *                          equal to the width of \p p)
 *  \param  clock_rate_hz   the clock rate in Hz
 *  \param  baud            baud rate
 *  \param  parity          the parity of the UART
 *  \param  bits_per_byte   bits per byte (must be in the range [1-8])
 *  \param  stop_bits       number of stop bits
 */
void multi_uart_tx(chanend c,
                   server interface multi_uart_tx_if i,
                   out port p,
                   size_t num_uarts,
                   unsigned clock_rate_hz,
                   unsigned baud,
                   uart_parity_t parity,
                   unsigned bits_per_byte,
                   unsigned stop_bits);


#include "multi_uart_impl.h"

#endif // __XC__

#endif /* _uart_h_ */
