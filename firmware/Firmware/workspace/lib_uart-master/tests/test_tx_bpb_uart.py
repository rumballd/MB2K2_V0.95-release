import xmostest
import os
from xmostest.xmostest_subprocess import call
from uart_tx_checker import UARTTxChecker, Parity


def do_test(baud, parity, bpb):
    myenv = {'parity': parity, 'baud': baud, 'bits_per_byte': bpb}
    path = "app_uart_test_bpb"
    resources = xmostest.request_resource("xsim")

    checker = UARTTxChecker("tile[0]:XS1_PORT_1A", "tile[0]:XS1_PORT_1B", Parity[parity], baud, 4, 1, bpb)
    tester = xmostest.ComparisonTester(open('test_tx_bpb_uart.expect'),
                                       "lib_uart", "sim_regression", "tx_bpb", myenv,
                                       regexp=True)

    # Only want even parity @ 115200 baud for smoke tests
    if baud != 115200 or parity != 'UART_PARITY_EVEN':
        tester.set_min_testlevel('nightly')

    xmostest.run_on_simulator(resources['xsim'],
                              'app_uart_test_bpb/bin/smoke/app_uart_test_bpb_smoke.xe',
                              simthreads=[checker],
                              xscope_io=True,
                              tester=tester,
                              clean_before_build=True,
                              build_env=myenv)


def runtest():
    for baud in [115200, 230400]:
        for parity in ['UART_PARITY_NONE', 'UART_PARITY_EVEN', 'UART_PARITY_ODD']:
            for bpb in [5, 7, 8]:
                do_test(baud, parity, bpb)
