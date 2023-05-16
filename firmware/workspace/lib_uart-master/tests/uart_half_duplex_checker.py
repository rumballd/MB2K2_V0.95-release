from uart_tx_checker import UARTTxChecker as TxC
from uart_rx_checker import UARTRxChecker as RxC

import xmostest


Parity = dict(
    UART_PARITY_EVEN=0,
    UART_PARITY_ODD=1,
    UART_PARITY_NONE=2,
)


class UARTHalfDuplexChecker(xmostest.SimThread):
    def __init__(self, rx_port, tx_port, notif_port, parity, baud, length, stop_bits, bpb):
        self._rx_port = rx_port
        self._tx_port = tx_port
        self._notif_port = notif_port
        self._parity = parity
        self._baud = baud
        self._length = length
        self._stop_bits = stop_bits
        self._bits_per_byte = bpb

        self._tx = TxC(rx_port, tx_port, parity, baud, length, stop_bits, bpb)
        self._rx = RxC(rx_port, tx_port, parity, baud, stop_bits, bpb)

    def do_read_test(self, xsi):
        # Device reads 4 bytes from UART.
        [self._rx.send_byte(xsi, byte) for byte in [0x7f, 0x00, 0x2f, 0xff]]

    def do_write_test(self, xsi):
        # Device sends 4 bytes down UART
        k = self._tx.read_packet(self.xsi, self._parity, self._length)
        print ", ".join(map((lambda x: "0x%02x" % ord(x)), k))

    def run(self):
        # Wait for the xcore to bring the uart tx port up
        self.wait((lambda x: self.xsi.is_port_driving(self._tx_port)))

        self._tx.xsi = self.xsi
        self.do_write_test(self.xsi)

        self.wait((lambda x: self.xsi.is_port_driving(self._notif_port)))

        self._rx.xsi = self.xsi
        self.do_read_test(self.xsi)
