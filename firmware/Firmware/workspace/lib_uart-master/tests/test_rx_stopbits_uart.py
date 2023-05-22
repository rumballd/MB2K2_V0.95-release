import xmostest
import os
from xmostest.xmostest_subprocess import call
from uart_rx_checker import UARTRxChecker, Parity


def do_test(baud, stopbits):
    myenv = {'stop_bits': stopbits, 'baud': baud}
    path = "app_uart_test_rx_stopbits"
    resources = xmostest.request_resource("xsim")

    checker = UARTRxChecker("tile[0]:XS1_PORT_1A", "tile[0]:XS1_PORT_1B",
                            Parity['UART_PARITY_NONE'], baud, stopbits, 8)
    tester = xmostest.ComparisonTester(open('test_rx_stopbits_uart.expect'),
                                       "lib_uart", "sim_regression", "rx_stopbits", myenv,
                                       regexp=True)

    # Only want 115200 baud w/ 2 stopbits for smoke tests
    if baud != 115200 or stopbits != 2:
        tester.set_min_testlevel('nightly')

    xmostest.run_on_simulator(resources['xsim'],
                              'app_uart_test_rx_stopbits/bin/smoke/app_uart_test_rx_stopbits_smoke.xe',
                              simthreads=[checker],
                              xscope_io=True,
                              tester=tester,
                              clean_before_build=True,
                              build_env=myenv)


def runtest():
    for baud in [14400, 57600, 115200]:
        for stopbits in [1, 2, 3]:
            do_test(baud, stopbits)
