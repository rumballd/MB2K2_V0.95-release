import xmostest
from uart_half_duplex_checker import UARTHalfDuplexChecker, Parity as Parity


def do_test(baud, parity):
    myenv = {'baud': baud, 'parity': parity}
    path = "app_uart_test_half_duplex_combined"
    resources = xmostest.request_resource("xsim")

    hd_checker = UARTHalfDuplexChecker("tile[0]:XS1_PORT_1A", "tile[0]:XS1_PORT_1A", "tile[0]:XS1_PORT_1B",
                                       Parity[parity], baud, 4, 1, 8)

    tester = xmostest.ComparisonTester(open('test_half_duplex_combined.expect'),
                                       "lib_uart", "sim_regression", "half_duplex_combined", myenv,
                                       regexp=True)

    # Only want no parity @ 115200 baud for smoke tests
    if baud != 115200 or parity != "UART_PARITY_NONE":
        tester.set_min_testlevel('nightly')

    xmostest.run_on_simulator(resources['xsim'],
                              'app_uart_test_half_duplex_combined/bin/smoke/app_uart_test_half_duplex_combined_smoke.xe',
                              simthreads=[hd_checker],
                              xscope_io=True,
                              tester=tester,
                              simargs=["--vcd-tracing", "-tile tile[0] -ports -o trace.vcd"],
                              clean_before_build=True,
                              build_env=myenv)


def runtest():
    for parity in ["UART_PARITY_EVEN", "UART_PARITY_ODD", "UART_PARITY_NONE"]:
        for baud in [57600, 115200]:
            do_test(baud, parity)
