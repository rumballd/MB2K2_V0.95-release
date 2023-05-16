import xmostest
from uart_rx_checker import DriveHigh, UARTRxChecker, Parity as RxParity
from uart_clock_device  import UARTClockDevice


def do_test(baud):
    myenv = {'baud': baud}
    path = "app_uart_test_multi_rx"
    resources = xmostest.request_resource("xsim")

    rx_checker = UARTRxChecker("tile[0]:XS1_PORT_8B.0", "tile[0]:XS1_PORT_1A", RxParity['UART_PARITY_NONE'], baud, 1, 8, data=[0x7f, 0x00, 0x2f, 0xff])
    rx_checker2 = UARTRxChecker("tile[0]:XS1_PORT_8B.2", "tile[0]:XS1_PORT_1A", RxParity['UART_PARITY_NONE'], baud/2, 1, 8, data=[0xaa, 0x01, 0xfc, 0x8e])
    uart_clock = UARTClockDevice("tile[0]:XS1_PORT_1L", 1843200)

    drive_high0 = DriveHigh("tile[0]:XS1_PORT_8B.1")

    tester = xmostest.ComparisonTester(open('test_rx_multi_uart.expect'),
                                       "lib_uart", "sim_regression", "multi_rx_simple", myenv,
                                       regexp=True)

    if baud != 115200:
        tester.set_min_testlevel('nightly')

    xmostest.run_on_simulator(resources['xsim'],
                              'app_uart_test_multi_rx/bin/smoke/app_uart_test_multi_rx_smoke.xe',
                              simthreads=[drive_high0, rx_checker, rx_checker2, uart_clock],
                              xscope_io=True,
                              tester=tester,
                              simargs=["--trace-to", "trace", "--vcd-tracing", "-tile tile[0] -pads -o trace.vcd"],
                              clean_before_build=True,
                              build_env=myenv)


def runtest():
    for baud in [57600, 115200]:
#    for baud in [115200]:
        do_test(baud)
