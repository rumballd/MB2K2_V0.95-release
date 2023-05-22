#!/usr/bin/env python
import xmostest

if __name__ == "__main__":
    xmostest.init()

    xmostest.register_group("lib_uart",
                            "sim_regression",
                            "Uart Simulator Regression",
    """
    Several tests are performed in simulation with a loopback between the UART Tx
    and Rx ports. This tests the features of the individual components,
    verifying them against each other. The various options and use cases of the
    components are tested.
    """)

    xmostest.register_group("lib_uart", "sim_regression", "Uart Transmission Test",
    """
    """)


    xmostest.runtests()


    xmostest.finish()
