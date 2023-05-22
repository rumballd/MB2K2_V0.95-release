UART library
============

Summary
-------

A software defined, industry-standard, UART (Universal Asynchronous
Receiver/Transmitter) library
that allows you to control a UART serial connection via the
xCORE GPIO ports. This library is controlled
via C using the XMOS multicore extensions.

Features
........

.. sidebysidelist::

 * UART receive and transmit
 * Supports speeds up to 10MBit/s
 * Half-duplex mode (applicable to RS485)
 * Efficient multi-uart mode for implementing multiple connections


Resource Usage
..............

.. resusage::


  * - configuration: Standard TX
    - globals:
    - locals: output_gpio_if i_gpio_tx; interface uart_tx_if i_tx;
    - fn: uart_tx(i_tx, null,
                  115200, UART_PARITY_NONE, 8, 1,
                  i_gpio_tx);
    - pins: 1
    - ports: 1

  * - configuration: Standard TX (buffered)
    - globals:
    - locals: output_gpio_if i_gpio_tx; interface uart_tx_buffered_if i_tx;
    - fn: uart_tx_buffered(i_tx, null, 5,
                  115200, UART_PARITY_NONE, 8, 1,
                  i_gpio_tx);
    - pins: 1
    - ports: 1

  * - configuration: Standard RX
    - globals:
    - locals: input_gpio_if i_gpio_rx; interface uart_rx_if i_rx;
    - fn: uart_rx(i_rx, null, 5,
                  115200, UART_PARITY_NONE, 8, 1,
                  i_gpio_rx);
    - pins: 1
    - ports: 1

  * - configuration: Fast/streaming TX
    - globals: out port p_uart_tx = XS1_PORT_1A;
    - locals: streaming chan c;
    - fn: uart_tx_streaming(p_uart_tx, c, 100);
    - pins: 1
    - ports: 1

  * - configuration: Fast/streaming RX
    - globals: in port p_uart_tx = XS1_PORT_1A;
    - locals: streaming chan c;
    - fn: uart_rx_streaming(p_uart_tx, c, 100);
    - pins: 1
    - ports: 1

  * - configuration: Multi-UART TX (8 UARTs)
    - globals: out buffered port:8 p_uart_tx  = XS1_PORT_8B;
    - locals:   interface multi_uart_tx_if i_tx;  chan c_tx;
    - fn:  multi_uart_tx(c_tx, i_tx, p_uart_tx, 8, 1843200, 115200, UART_PARITY_NONE, 8, 1);
    - pins: 8
    - ports: 1
    - cores: 1

  * - configuration: Multi-UART RX (8 UARTs)
    - globals: in buffered port:32 p_uart_rx  = XS1_PORT_8B;
    - locals:   interface multi_uart_rx_if i_rx;  streaming chan c_rx;
    - fn:  multi_uart_rx(c_rx, i_rx, p_uart_rx, 8, 1843200, 115200, UART_PARITY_NONE, 8, 1);
    - pins: 8
    - ports: 1
    - cores: 1

  * - configuration: Half Duplex
    - globals: port p_uart = XS1_PORT_1A;
    - locals: interface uart_tx_buffered_if i_tx; uart_rx_if i_rx;  uart_control_if i_ctl;
    - fn: uart_half_duplex(i_tx, i_rx, i_ctl, null, 10, 10, 115200, UART_PARITY_NONE, 8, 1, p_uart);
    - pins: 1
    - ports: 1
    - cores: 1


Software version and dependencies
.................................

.. libdeps::
