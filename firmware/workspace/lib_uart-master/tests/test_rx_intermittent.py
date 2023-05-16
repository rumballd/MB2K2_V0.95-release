import xmostest
import os
from xmostest.xmostest_subprocess import call
from uart_rx_checker import UARTRxChecker, Parity


def do_test(baud):
    myenv = {'baud': baud, 'parity': 'UART_PARITY_EVEN'}
    path = "app_uart_test_rx_intermittent"
    resources = xmostest.request_resource("xsim")

    checker = UARTRxChecker("tile[0]:XS1_PORT_1A", "tile[0]:XS1_PORT_1B",
                            Parity['UART_PARITY_BAD'], baud, 1, 8,
                            data=range(50), intermittent=True)
    tester = xmostest.ComparisonTester(open('test_rx_intermittent_uart.expect'),
                                       "lib_uart", "sim_regression", "rx_intermittent", myenv,
                                       regexp=True)

    if baud != 115200:
        tester.set_min_testlevel('nightly')

    xmostest.run_on_simulator(resources['xsim'],
                              'app_uart_test_rx_intermittent/bin/smoke/app_uart_test_rx_intermittent_smoke.xe',
                              simthreads=[checker],
                              xscope_io=True,
                              tester=tester,
                              simargs=["--vcd-tracing", "-tile tile[0] -ports -o trace.vcd"],
                              clean_before_build=True,
                              build_env=myenv)


def runtest():
    for baud in [57600, 115200]:
        do_test(baud)
