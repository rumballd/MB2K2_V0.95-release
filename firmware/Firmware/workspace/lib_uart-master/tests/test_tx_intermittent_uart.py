import xmostest
import os
from xmostest.xmostest_subprocess import call
from uart_tx_checker import UARTTxChecker, Parity


def do_test(baud):
    myenv = {'baud': baud}
    path = "app_uart_test_intermittent"
    resources = xmostest.request_resource("xsim")

    checker = UARTTxChecker("tile[0]:XS1_PORT_1A", "tile[0]:XS1_PORT_1B", Parity['UART_PARITY_NONE'], baud, 64, 1, 8)
    tester = xmostest.ComparisonTester(open('test_tx_intermittent_uart.expect'),
                                       "lib_uart", "sim_regression", "tx_intermittent", myenv,
                                       regexp=True)

    # Only want no parity @ 230400 baud for smoke tests
    if baud != 230400:
        tester.set_min_testlevel('nightly')

    xmostest.run_on_simulator(resources['xsim'],
                              'app_uart_test_intermittent/bin/smoke/app_uart_test_intermittent_smoke.xe',
                              simthreads=[checker],
                              xscope_io=True,
                              tester=tester,
                              clean_before_build=True,
                              build_env=myenv)


def runtest():
    for baud in [57600, 115200, 230400]:
        do_test(baud)
