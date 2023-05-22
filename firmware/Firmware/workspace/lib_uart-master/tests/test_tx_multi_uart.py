import xmostest
from uart_tx_checker import UARTTxChecker, Parity as TxParity
from uart_clock_device  import UARTClockDevice


def do_test(baud, internal_clock):
    myenv = {'baud': baud, 'internal_clock': internal_clock}
    path = "app_uart_test_multi_tx"
    resources = xmostest.request_resource("xsim")

    tx_checker = UARTTxChecker("tile[0]:XS1_PORT_1A", "tile[0]:XS1_PORT_8B.1", TxParity['UART_PARITY_NONE'], baud, 4, 1, 8)
    uart_clock = UARTClockDevice("tile[0]:XS1_PORT_1F", 230400)

    tester = xmostest.ComparisonTester(open('test_tx_multi_uart.expect'),
                                       "lib_uart", "sim_regression", "multi_tx_simple", myenv,
                                       regexp=True)

    # Only want no parity @ 230400 baud for smoke tests
    if baud != 115200:
        tester.set_min_testlevel('nightly')

    xmostest.run_on_simulator(resources['xsim'],
                              'app_uart_test_multi_tx/bin/smoke/app_uart_test_multi_tx_smoke.xe',
                              simthreads=[tx_checker, uart_clock],
                              xscope_io=True,
                              tester=tester,
                              simargs=["--vcd-tracing", "-tile tile[0] -pads -o trace.vcd"],
                              clean_before_build=True,
                              build_env=myenv)


def runtest():
    for baud in [57600, 115200]:
        for internal_clock in [0, 1]:
            do_test(baud, internal_clock)
