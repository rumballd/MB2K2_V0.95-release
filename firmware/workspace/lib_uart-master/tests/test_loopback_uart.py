import xmostest

from uart_rx_checker import UARTRxChecker, Parity as RxParity
from uart_tx_checker import UARTTxChecker, Parity as TxParity


def do_test(baud):
    myenv = {'baud': baud}
    resources = xmostest.request_resource("xsim")

    rx_checker = UARTRxChecker("tile[0]:XS1_PORT_1A", "tile[0]:XS1_PORT_1B",
                               RxParity['UART_PARITY_NONE'], baud, 1, 8)

    tx_checker = UARTTxChecker("tile[0]:XS1_PORT_1D", "tile[0]:XS1_PORT_1C",
                               TxParity['UART_PARITY_NONE'], baud, 4, 1, 8)

    tester = xmostest.ComparisonTester(open('test_loopback_uart.expect'),
                                       "lib_uart", "sim_regression", "loopback", myenv,
                                       regexp=True)

    if baud != 115200:
        tester.set_min_testlevel('nightly')

    xmostest.run_on_simulator(resources['xsim'],
                              'app_uart_test_loopback/bin/{}/app_uart_test_loopback_{}.xe'.format(baud, baud),
                              simthreads=[rx_checker, tx_checker],
                              xscope_io=True,
                              tester=tester,
                              simargs=["--vcd-tracing", "-tile tile[0] -functions -ports -o trace.vcd"],
                              clean_before_build=True,
                              build_env=myenv)


def runtest():
    for baud in [14400, 28800, 57600, 115200]:
        do_test(baud)
