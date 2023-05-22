import xmostest
from uart_tx_checker import UARTTxChecker, Parity as TxParity


def do_test(baud, parity):
    myenv = {'baud': baud, 'parity': parity}
    path = "app_uart_test_half_duplex"
    resources = xmostest.request_resource("xsim")

    tx_checker = UARTTxChecker("tile[0]:XS1_PORT_1A", "tile[0]:XS1_PORT_1A", TxParity[parity], baud, 4, 1, 8)

    tester = xmostest.ComparisonTester(open('test_half_duplex_tx_uart.expect'),
                                       "lib_uart", "sim_regression", "half_duplex_tx_simple", myenv,
                                       regexp=True)

    # Only want no parity @ 115200 baud for smoke tests
    if baud != 115200 or parity != "UART_PARITY_NONE":
        tester.set_min_testlevel('nightly')

    xmostest.run_on_simulator(resources['xsim'],
                              'app_uart_test_half_duplex/bin/smoke/app_uart_test_half_duplex_smoke.xe',
                              simthreads=[tx_checker],
                              xscope_io=True,
                              tester=tester,
                              simargs=["--vcd-tracing", "-tile tile[0] -ports -o trace.vcd"],
                              clean_before_build=True,
                              build_env=myenv)


def runtest():
    for baud in [115200, 57600, 28800]:
        for parity in ['UART_PARITY_NONE', 'UART_PARITY_EVEN', 'UART_PARITY_ODD']:
            do_test(baud, parity)
