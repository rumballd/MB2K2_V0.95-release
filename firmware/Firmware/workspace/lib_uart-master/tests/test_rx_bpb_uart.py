import xmostest
import os
from xmostest.xmostest_subprocess import call
from uart_rx_checker import UARTRxChecker, Parity


def do_test(baud, parity, bpb):
    myenv = {'parity': parity, 'baud': baud, 'bits_per_byte': bpb}
    path = "app_uart_test_rx_bpb"
    resources = xmostest.request_resource("xsim")

    checker = UARTRxChecker("tile[0]:XS1_PORT_1A", "tile[0]:XS1_PORT_1B",
                            Parity[parity], baud, 1, bpb,
                            [0x00, 0x1a, 0x07, 0x12])
    tester = xmostest.ComparisonTester(open('test_rx_bpb_uart.expect'),
                                       "lib_uart", "sim_regression", "rx_bpb", myenv,
                                       regexp=True)

    # Only want no parity @ 115200 baud for smoke tests
    if baud != 115200 or parity != 'UART_PARITY_NONE':
        tester.set_min_testlevel('nightly')

    xmostest.run_on_simulator(resources['xsim'],
                              'app_uart_test_rx_bpb/bin/smoke/app_uart_test_rx_bpb_smoke.xe',
                              simthreads=[checker],
                              xscope_io=True,
                              tester=tester,
                              clean_before_build=True,
                              build_env=myenv)


def runtest():
    for baud in [14400, 57600, 115200]:
        for parity in ['UART_PARITY_NONE', 'UART_PARITY_ODD', 'UART_PARITY_EVEN']:
            for bpb in [5, 7, 8]:
                do_test(baud, parity, bpb)
