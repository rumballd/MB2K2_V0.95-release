import xmostest

class UARTClockDevice(xmostest.SimThread):
    def __init__(self, clock_port, clock_frequency):
        """
        Create a clock input to a given port for the XCore.

        :param: clock_port        Port to clock
        :param: clock_frequency   Frequency in Hz of the clock
        """
        self._clock_port = clock_port
        self._clock_frequency = clock_frequency

    def run(self):
        xsi = self.xsi
        time = xsi.get_time()

        # (1s/(freq))/2 = T for 1 edge. 1s = 1e9ns, 0.5s = 5e8ns
        half_period_ns = float(5e8) / self._clock_frequency
        while True:
            xsi.drive_port_pins(self._clock_port, 1)
            self.wait_until(time + half_period_ns)
            time += half_period_ns

            xsi.drive_port_pins(self._clock_port, 0)
            self.wait_until(time + half_period_ns)
            time += half_period_ns
