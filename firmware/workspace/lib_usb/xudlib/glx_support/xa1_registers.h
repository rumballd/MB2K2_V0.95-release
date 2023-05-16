// Copyright (c) 2016, XMOS Ltd, All rights reserved
/*
 *
 *
 * AUTOGENERATED - DO NOT EDIT
 * by infr_libs_cpp/Scripts/CreateXS1.pl
 *
 */
#ifndef _xa1_registers_h_
#define _xa1_registers_h_
#define XS1_GLX_WR_NO_ACK_CHAN_END 0xff
#define XS1_GLX_PERIPH_ADRS_SIZE 0x8
#define XS1_GLX_PERIPH_DATA_SIZE 0x20
#define XS1_GLX_PERIPH_NUM_TOKENS_SIZE 0x1
#define XS1_GLX_PERIPH_NUM_TOKENS_8BITS 0x0
#define XS1_GLX_PERIPH_NUM_TOKENS_32BITS 0x1
#define XS1_GLX_PERIPH_USB_ID 0x1
#define XS1_GLX_PERIPH_ADC_ID 0x2
#define XS1_GLX_PERIPH_SCTH_ID 0x3
#define XS1_GLX_PERIPH_OSC_ID 0x4
#define XS1_GLX_PERIPH_RTC_ID 0x5
#define XS1_GLX_PERIPH_PWR_ID 0x6
#define XS1_GLX_CFG_DEV_ID_ADRS 0x0
#define XS1_GLX_CFG_VERSION_BASE 0x0
#define XS1_GLX_CFG_VERSION_SIZE 0x8
#define XS1_GLX_CFG_VERSION_BITS "7:0"
#define XS1_GLX_CFG_VERSION_VALUE 0x0
#define XS1_GLX_CFG_REVISION_BASE 0x8
#define XS1_GLX_CFG_REVISION_SIZE 0x8
#define XS1_GLX_CFG_REVISION_BITS "15:8"
#define XS1_GLX_CFG_REVISION_VALUE 0x0
#define XS1_GLX_CFG_MODE_ON_RST_BASE 0x10
#define XS1_GLX_CFG_MODE_ON_RST_SIZE 0x5
#define XS1_GLX_CFG_MODE_ON_RST_BITS "20:16"
#define XS1_GLX_CFG_MODE_BOOT_BASE 0x10
#define XS1_GLX_CFG_MODE_BOOT_SIZE 0x1
#define XS1_GLX_CFG_MODE_BOOT_BITS "16:16"
#define XS1_GLX_CFG_MODE_PROF_BASE 0x11
#define XS1_GLX_CFG_MODE_PROF_SIZE 0x1
#define XS1_GLX_CFG_MODE_PROF_BITS "17:17"
#define XS1_GLX_CFG_MODE_STACK_BASE 0x12
#define XS1_GLX_CFG_MODE_STACK_SIZE 0x1
#define XS1_GLX_CFG_MODE_STACK_BITS "18:18"
#define XS1_GLX_CFG_MODE_POWER_BASE 0x13
#define XS1_GLX_CFG_MODE_POWER_SIZE 0x2
#define XS1_GLX_CFG_MODE_POWER_BITS "20:19"
#define XS1_GLX_CFG_CHIP_ID_BASE 0x18
#define XS1_GLX_CFG_CHIP_ID_SIZE 0x8
#define XS1_GLX_CFG_CHIP_ID_BITS "31:24"
#define XS1_GLX_CFG_CHIP_ID_VALUE 0xf
#define XS1_GLX_CFG_NODE_CFG_ADRS 0x4
#define XS1_GLX_CFG_HDR_MODE_BASE 0x0
#define XS1_GLX_CFG_HDR_MODE_SIZE 0x1
#define XS1_GLX_CFG_HDR_MODE_BITS "0:0"
#define XS1_GLX_CFG_DISABLE_UPDATES_BASE 0x1f
#define XS1_GLX_CFG_DISABLE_UPDATES_SIZE 0x1
#define XS1_GLX_CFG_DISABLE_UPDATES_BITS "31:31"
#define XS1_GLX_CFG_NODE_ID_SCTH_ADRS 0x5
#define XS1_GLX_CFG_NODE_ID_SCTH_BASE 0x0
#define XS1_GLX_CFG_NODE_ID_SCTH_SIZE 0x10
#define XS1_GLX_CFG_NODE_ID_SCTH_BITS "15:0"
#define XS1_GLX_CFG_RST_MISC_ADRS 0x50
#define XS1_GLX_CFG_SFT_BOOT_BASE 0x0
#define XS1_GLX_CFG_SFT_BOOT_SIZE 0x1
#define XS1_GLX_CFG_SFT_BOOT_BITS "0:0"
#define XS1_GLX_CFG_PROC_BOOT_BASE 0x1
#define XS1_GLX_CFG_PROC_BOOT_SIZE 0x1
#define XS1_GLX_CFG_PROC_BOOT_BITS "1:1"
#define XS1_GLX_CFG_USB_EN_BASE 0x2
#define XS1_GLX_CFG_USB_EN_SIZE 0x1
#define XS1_GLX_CFG_USB_EN_BITS "2:2"
#define XS1_GLX_CFG_USB_CLK_EN_BASE 0x3
#define XS1_GLX_CFG_USB_CLK_EN_SIZE 0x1
#define XS1_GLX_CFG_USB_CLK_EN_BITS "3:3"
#define XS1_GLX_CFG_LAST_RST_SRC_BASE 0x8
#define XS1_GLX_CFG_LAST_RST_SRC_SIZE 0x3
#define XS1_GLX_CFG_LAST_RST_SRC_BITS "10:8"
#define XS1_GLX_CFG_OP_MODE_BASE 0x10
#define XS1_GLX_CFG_OP_MODE_SIZE 0x2
#define XS1_GLX_CFG_OP_MODE_BITS "17:16"
#define XS1_GLX_CFG_OP_MODE_RST_VALUE 0x2
#define XS1_GLX_CFG_RST_SRC_SFT_BOOT 0x1
#define XS1_GLX_CFG_RST_SRC_PWR_PG 0x3
#define XS1_GLX_CFG_RST_SRC_PWR_SM 0x4
#define XS1_GLX_CFG_RST_SRC_OSC_SEL 0x5
#define XS1_GLX_CFG_RST_SRC_PROC_BOOT 0x6
#define XS1_GLX_CFG_SYS_CLK_FREQ_ADRS 0x51
#define XS1_GLX_CFG_SYS_CLK_FREQ_BASE 0x0
#define XS1_GLX_CFG_SYS_CLK_FREQ_SIZE 0x7
#define XS1_GLX_CFG_SYS_CLK_FREQ_BITS "6:0"
#define XS1_GLX_CFG_SYS_CLK_FREQ_VALUE 0x19
#define XS1_GLX_CFG_PKT_DEC_DBG_ADRS 0x52
#define XS1_GLX_CFG_PKT_DEC_SM_PTR_BASE 0x0
#define XS1_GLX_CFG_PKT_DEC_SM_PTR_BITS "4:0"
#define XS1_GLX_CFG_PKT_DEC_WR_ACC_BASE 0x5
#define XS1_GLX_CFG_PKT_DEC_WR_ACC_SIZE 0x1
#define XS1_GLX_CFG_PKT_DEC_WR_ACC_BITS "5:5"
#define XS1_GLX_CFG_PKT_DEC_CFG_ACC_BASE 0x6
#define XS1_GLX_CFG_PKT_DEC_CFG_ACC_SIZE 0x1
#define XS1_GLX_CFG_PKT_DEC_CFG_ACC_BITS "6:6"
#define XS1_GLX_CFG_PKT_DEC_BYTE_BASE 0x8
#define XS1_GLX_CFG_PKT_DEC_BYTE_SIZE 0x2
#define XS1_GLX_CFG_PKT_DEC_BYTE_BITS "9:8"
#define XS1_GLX_CFG_PKT_DEC_BLK_BASE 0x10
#define XS1_GLX_CFG_PKT_DEC_BLK_SIZE 0x8
#define XS1_GLX_CFG_PKT_DEC_BLK_BITS "23:16"
#define XS1_GLX_CFG_PKT_DEC_MALF_BASE 0x18
#define XS1_GLX_CFG_PKT_DEC_MALF_SIZE 0x4
#define XS1_GLX_CFG_PKT_DEC_MALF_BITS "27:24"
#define XS1_GLX_CFG_PKT_GEN_DBG_ADRS 0x53
#define XS1_GLX_CFG_PKT_GEN_SM_PTR_BASE 0x0
#define XS1_GLX_CFG_PKT_GEN_SM_PTR_BITS "3:0"
#define XS1_GLX_CFG_PKT_GEN_WR_ACC_BASE 0x5
#define XS1_GLX_CFG_PKT_GEN_WR_ACC_SIZE 0x1
#define XS1_GLX_CFG_PKT_GEN_WR_ACC_BITS "5:5"
#define XS1_GLX_CFG_PKT_GEN_CFG_ACC_BASE 0x6
#define XS1_GLX_CFG_PKT_GEN_CFG_ACC_SIZE 0x1
#define XS1_GLX_CFG_PKT_GEN_CFG_ACC_BITS "6:6"
#define XS1_GLX_CFG_PKT_GEN_ADC_PKT_BASE 0x7
#define XS1_GLX_CFG_PKT_GEN_ADC_PKT_SIZE 0x1
#define XS1_GLX_CFG_PKT_GEN_ADC_PKT_BITS "7:7"
#define XS1_GLX_CFG_PKT_GEN_BYTE_BASE 0x8
#define XS1_GLX_CFG_PKT_GEN_BYTE_SIZE 0x2
#define XS1_GLX_CFG_PKT_GEN_BYTE_BITS "9:8"
#define XS1_GLX_CFG_PKT_GEN_ID_BASE 0x10
#define XS1_GLX_CFG_PKT_GEN_ID_SIZE 0x8
#define XS1_GLX_CFG_PKT_GEN_ID_BITS "23:16"
#define XS1_GLX_CFG_PKT_GEN_SAMP_BASE 0x18
#define XS1_GLX_CFG_PKT_GEN_SAMP_SIZE 0x8
#define XS1_GLX_CFG_PKT_GEN_SAMP_BITS "31:24"
#define XS1_GLX_CFG_PMU_TEST_MODE_ADRS 0x54
#define XS1_GLX_CFG_CCTEST_EN_BASE 0x1
#define XS1_GLX_CFG_CCTEST_EN_SIZE 0x1
#define XS1_GLX_CFG_CCTEST_EN_BITS "1:1"
#define XS1_GLX_CFG_CCTEST_RSTB_BASE 0x2
#define XS1_GLX_CFG_CCTEST_RSTB_SIZE 0x1
#define XS1_GLX_CFG_CCTEST_RSTB_BITS "2:2"
#define XS1_GLX_CFG_CCTEST_CLK_BASE 0x3
#define XS1_GLX_CFG_CCTEST_CLK_SIZE 0x1
#define XS1_GLX_CFG_CCTEST_CLK_BITS "3:3"
#define XS1_GLX_CFG_CCTEST_DATAIN_BASE 0x4
#define XS1_GLX_CFG_CCTEST_DATAIN_SIZE 0x1
#define XS1_GLX_CFG_CCTEST_DATAIN_BITS "4:4"
#define XS1_GLX_CFG_CCTEST_GPIN_BASE 0x5
#define XS1_GLX_CFG_CCTEST_GPIN_SIZE 0x1
#define XS1_GLX_CFG_CCTEST_GPIN_BITS "5:5"
#define XS1_GLX_CFG_CCTEST_DATAOUT_BASE 0x8
#define XS1_GLX_CFG_CCTEST_DATAOUT_SIZE 0x1
#define XS1_GLX_CFG_CCTEST_DATAOUT_BITS "8:8"
#define XS1_GLX_CFG_CCTEST_STAT1_BASE 0x9
#define XS1_GLX_CFG_CCTEST_STAT1_SIZE 0x1
#define XS1_GLX_CFG_CCTEST_STAT1_BITS "9:9"
#define XS1_GLX_CFG_CCTEST_STAT2_BASE 0xa
#define XS1_GLX_CFG_CCTEST_STAT2_SIZE 0x1
#define XS1_GLX_CFG_CCTEST_STAT2_BITS "10:10"
#define XS1_GLX_CFG_CCTEST_RSRVOUT_BASE 0xb
#define XS1_GLX_CFG_CCTEST_RSRVOUT_SIZE 0x1
#define XS1_GLX_CFG_CCTEST_RSRVOUT_BITS "11:11"
#define XS1_GLX_CFG_CCTEST_RSRVIN_BASE 0xc
#define XS1_GLX_CFG_CCTEST_RSRVIN_SIZE 0x8
#define XS1_GLX_CFG_CCTEST_RSRVIN_BITS "19:12"
#define XS1_GLX_CFG_ADC_DATA_BASE 0x14
#define XS1_GLX_CFG_ADC_DATA_SIZE 0xc
#define XS1_GLX_CFG_ADC_DATA_BITS "31:20"
#define XS1_GLX_CFG_LINK_CTRL_ADRS 0x80
#define XS1_GLX_CFG_WDOG_TMR_ADRS 0xd6
#define XS1_GLX_CFG_WDOG_EXP_BASE 0x0
#define XS1_GLX_CFG_WDOG_EXP_SIZE 0x10
#define XS1_GLX_CFG_WDOG_EXP_BITS "15:0"
#define XS1_GLX_CFG_WDOG_TMR_BASE 0x10
#define XS1_GLX_CFG_WDOG_TMR_SIZE 0x10
#define XS1_GLX_CFG_WDOG_TMR_BITS "31:16"
#define XS1_GLX_CFG_WDOG_INC_CTRL_SIZE 0x11
#define XS1_GLX_CFG_WDOG_DISABLE_ADRS 0xd7
#define XS1_GLX_CFG_WDOG_DISABLE_SIZE 0x20
#define XS1_GLX_CFG_WDOG_DISABLE_VALUE 0xd15ab1e
#define XS1_GLX_CFG_FTR_CTRL_ADRS 0xfc
#define XS1_GLX_CFG_FTR_EN_USB_BASE 0x0
#define XS1_GLX_CFG_FTR_EN_USB_SIZE 0x1
#define XS1_GLX_CFG_FTR_EN_USB_BITS "0:0"
#define XS1_GLX_CFG_FTR_EN_ADC_BASE 0x1
#define XS1_GLX_CFG_FTR_EN_ADC_SIZE 0x1
#define XS1_GLX_CFG_FTR_EN_ADC_BITS "1:1"
#define XS1_GLX_CFG_FTR_EN_PWR_LVL_UP_BASE 0x2
#define XS1_GLX_CFG_FTR_EN_PWR_LVL_UP_SIZE 0x1
#define XS1_GLX_CFG_FTR_EN_PWR_LVL_UP_BITS "2:2"
#define XS1_GLX_CFG_FTR_EN_PWR_LVL_DN_BASE 0x3
#define XS1_GLX_CFG_FTR_EN_PWR_LVL_DN_SIZE 0x1
#define XS1_GLX_CFG_FTR_EN_PWR_LVL_DN_BITS "3:3"
#define XS1_GLX_CFG_FTR_EN_JTAG_BASE 0x4
#define XS1_GLX_CFG_FTR_EN_JTAG_SIZE 0x1
#define XS1_GLX_CFG_FTR_EN_JTAG_BITS "4:4"
#define XS1_GLX_CFG_FTR_CTRL_DIS_ADRS 0xfd
#define XS1_GLX_CFG_FTR_CTRL_DIS_BASE 0x0
#define XS1_GLX_CFG_FTR_CTRL_DIS_SIZE 0x20
#define XS1_GLX_CFG_FTR_CTRL_DIS_BITS "31:0"
#define XS1_GLX_CFG_FTR_CTRL_DISABLED_VALUE 0xdeafdeaf
#define XS1_GLX_UTMI_DATA_WIDTH 0x8
#define XS1_XMOS_USB_DATA_WIDTH 0x8
#define XS1_XMOS_USB_LINESTATE_WIDTH 0x2
#define XS1_XMOS_USB_OPMODE_WIDTH 0x2
#define XS1_XMOS_USB_XCVRSEL_WIDTH 0x2
#define XS1_XMOS_USB_ULPI_REGWIDTH 0x8
#define XS1_XMOS_USB_ULPI_TXCMD_CMDCODE "7:6"
#define XS1_XMOS_USB_ULPI_RXCMD_RXEVENT "5:4"
#define XS1_XMOS_USB_ULPI_RXCMD_VBUS "3:2"
#define XS1_XMOS_USB_UTMI_PID "3:0"
#define XS1_XMOS_USB_ULPI_RXEVENT_WIDTH 0x2
#define XS1_XMOS_USB_ULPI_VBUSSTATE_WIDTH 0x2
#define XS1_XMOS_USB_3MS_CNTVAL_WIDTH 0x18
#define XS1_USB_PWR_STATE_IDLE 0x0
#define XS1_USB_PWR_STATE_RESET 0x1
#define XS1_USB_PWR_STATE_ACTIVE 0x2
#define XS1_USB_PWR_STATE_SUSPEND 0x3
#define XS1_USB_PWR_STATE_RESUMEK 0x4
#define XS1_USB_PWR_STATE_RESUMESE0 0x5
#define XS1_USB_PWR_STATE_WAITLINK 0x6
#define XS1_USB_PWR_STATE_TESTCODE 0x7
#define XS1_USB_PWR_STATE_TESTCONTROL 0x8
#define XS1_USB_PWR_STATE_BISTCODE 0x9
#define XS1_USB_PWR_STATE_BISTOK 0xa
#define XS1_XMOS_USB_LINESTATE_SE0 0x0
#define XS1_XMOS_USB_LINESTATE_J 0x1
#define XS1_XMOS_USB_LINESTATE_K 0x2
#define XS1_USB_RESET_EDGE "negedge"
#define XS1_USB_RESET_POLARITY 0x0
#define XS1_UIFM_PID_TOKEN 0x1
#define XS1_UIFM_PID_DATA 0x3
#define XS1_UIFM_PID_HANDSHAKE 0x2
#define XS1_UIFM_PID_SOF 0x1
#define XS1_UIFM_PID_SPECIAL 0x0
#define XS1_UIFM_NOT_PID_HANDSHAKE 0x1
#define XS1_UIFM_PID_DATA0 0x3
#define XS1_UIFM_PID_TOKEN_OUT 0x0
#define XS1_UIFM_PID_TOKEN_IN 0x2
#define XS1_UIFM_PID_TOKEN_SOF 0x1
#define XS1_UIFM_PID_TOKEN_SETUP 0x3
#define XS1_UIFM_PID_TOKEN_PING 0x1
#define XS1_UIFM_HANDSHAKE_ACK 0x0
#define XS1_UIFM_HANDSHAKE_NACK 0x2
#define XS1_UIFM_HANDSHAKE_NYET 0x1
#define XS1_UIFM_HANDSHAKE_STALL 0x3
#define XS1_UIFM_NOT_HANDSHAKE_ACK 0x3
#define XS1_UIFM_NOT_HANDSHAKE_NACK 0x1
#define XS1_UIFM_NOT_HANDSHAKE_NYET 0x2
#define XS1_UIFM_NOT_HANDSHAKE_STALL 0x0
#define XS1_UIFM_ADRS_WID 0x7
#define XS1_UIFM_RESET_REG 0x0
#define XS1_UIFM_IFM_CONTROL_REG 0x4
#define XS1_UIFM_IFM_CONTROL_DEFINED "7:0"
#define XS1_UIFM_IFM_CONTROL_DOTOKENS 0x0
#define XS1_UIFM_IFM_CONTROL_CHECKTOKENS 0x1
#define XS1_UIFM_IFM_CONTROL_DECODELINESTATE 0x2
#define XS1_UIFM_IFM_CONTROL_DONTUSE 0x3
#define XS1_UIFM_IFM_CONTROL_IFTIMINGMODE 0x4
#define XS1_UIFM_IFM_CONTROL_PWRSIGMODE 0x5
#define XS1_UIFM_IFM_CONTROL_SOFISTOKEN 0x6
#define XS1_UIFM_IFM_CONTROL_XEVACKMODE 0x7
#define XS1_UIFM_IFM_CONTROL_CHECKTOKENS_RST 0x0
#define XS1_UIFM_IFM_CONTROL_DOTOKENS_RST 0x0
#define XS1_UIFM_IFM_CONTROL_DECODELINESTATE_RST 0x0
#define XS1_UIFM_IFM_CONTROL_DONTUSE_RST 0x0
#define XS1_UIFM_IFM_CONTROL_IFTIMINGMODE_RST 0x0
#define XS1_UIFM_IFM_CONTROL_PWRSIGMODE_RST 0x0
#define XS1_UIFM_IFM_CONTROL_RESERVED 0x0
#define XS1_UIFM_DEVICE_ADDRESS_REG 0x8
#define XS1_UIFM_DEVICE_ADDRESS_DEFINED "6:0"
#define XS1_UIFM_DEVICE_ADDRESS_RESERVED 0x0
#define XS1_UIFM_DEVICE_ADDRESS_ADDRESS "6:0"
#define XS1_UIFM_DEVICE_ADDRESS_ADDRESS_RST 0x0
#define XS1_UIFM_FUNC_CONTROL_REG 0xc
#define XS1_UIFM_FUNC_CONTROL_DEFINED "3:0"
#define XS1_UIFM_FUNC_CONTROL_RESERVED 0x0
#define XS1_UIFM_FUNC_CONTROL_XCVRSELECT 0x0
#define XS1_UIFM_FUNC_CONTROL_TERMSELECT 0x1
#define XS1_UIFM_FUNC_CONTROL_OPMODE "3:2"
#define XS1_UIFM_FUNC_CONTROL_SUSPENDM_RST 0x1
#define XS1_UIFM_FUNC_CONTROL_XCVRSELECT_RST 0x0
#define XS1_UIFM_FUNC_CONTROL_TERMSELECT_RST 0x0
#define XS1_UIFM_FUNC_CONTROL_OPMODE_RST 0x1
#define XS1_UIFM_OTG_CONTROL_REG 0x10
#define XS1_UIFM_OTG_CONTROL_DEFINED "7:0"
#define XS1_UIFM_OTG_CONTROL_RESERVED 0x0
#define XS1_UIFM_OTG_CONTROL_IDPULLUP 0x0
#define XS1_UIFM_OTG_CONTROL_DPPULLDOWN 0x1
#define XS1_UIFM_OTG_CONTROL_DMPULLDOWN 0x2
#define XS1_UIFM_OTG_CONTROL_DISCHRGVBUS 0x3
#define XS1_UIFM_OTG_CONTROL_CHRGVBUS 0x4
#define XS1_UIFM_OTG_CONTROL_DRVVBUS 0x5
#define XS1_UIFM_OTG_CONTROL_DRVVBUSEXT 0x6
#define XS1_UIFM_OTG_CONTROL_EXTVBUSIND 0x7
#define XS1_UIFM_OTG_CONTROL_IDPULLUP_RST 0x0
#define XS1_UIFM_OTG_CONTROL_DPPULLDOWN_RST 0x0
#define XS1_UIFM_OTG_CONTROL_DMPULLDOWN_RST 0x0
#define XS1_UIFM_OTG_CONTROL_DISCHRGVBUS_RST 0x0
#define XS1_UIFM_OTG_CONTROL_CHRGVBUS_RST 0x0
#define XS1_UIFM_OTG_CONTROL_DRVVBUS_RST 0x0
#define XS1_UIFM_OTG_CONTROL_DRVVBUSEXT_RST 0x0
#define XS1_UIFM_OTG_CONTROL_EXTVBUSIND_RST 0x0
#define XS1_UIFM_OTG_FLAGS_REG 0x14
#define XS1_UIFM_OTG_FLAGS_DEFINED "5:0"
#define XS1_UIFM_OTG_FLAGS_RESERVED 0x0
#define XS1_UIFM_OTG_FLAGS_SESSEND 0x0
#define XS1_UIFM_OTG_FLAGS_SESSVLD 0x1
#define XS1_UIFM_OTG_FLAGS_VBUSVLD 0x2
#define XS1_UIFM_OTG_FLAGS_HOSTDIS 0x3
#define XS1_UIFM_OTG_FLAGS_NIDGND 0x4
#define XS1_UIFM_OTG_FLAGS_SESSVLDB 0x5
#define XS1_UIFM_OTG_FLAGS_RST 0x0
#define XS1_UIFM_SERIAL_MODE_REG 0x18
#define XS1_UIFM_SERIAL_MODE_DEFINED "6:0"
#define XS1_UIFM_SERIAL_MODE_RESERVED 0x0
#define XS1_UIFM_SERIAL_MODE_FSLSMODE 0x0
#define XS1_UIFM_SERIAL_MODE_TXENN 0x1
#define XS1_UIFM_SERIAL_MODE_TXDAT 0x2
#define XS1_UIFM_SERIAL_MODE_TXSE0 0x3
#define XS1_UIFM_SERIAL_MODE_RXDP 0x4
#define XS1_UIFM_SERIAL_MODE_RXDM 0x5
#define XS1_UIFM_SERIAL_MODE_RXRCV 0x6
#define XS1_UIFM_SERIAL_MODE_RST 0x2
#define XS1_UIFM_IFM_FLAGS_REG 0x1c
#define XS1_UIFM_IFM_FLAGS_DEFINED "6:0"
#define XS1_UIFM_IFM_FLAGS_RESERVED 0x0
#define XS1_UIFM_IFM_FLAGS_RXERROR 0x0
#define XS1_UIFM_IFM_FLAGS_RXACTIVE 0x1
#define XS1_UIFM_IFM_FLAGS_CRC16FAIL 0x2
#define XS1_UIFM_IFM_FLAGS_J 0x3
#define XS1_UIFM_IFM_FLAGS_K 4
#define XS1_UIFM_IFM_FLAGS_SE0 0x5
#define XS1_UIFM_IFM_FLAGS_NEWTOKEN 0x6
#define XS1_UIFM_IFM_FLAGS_RST 0x0
#define XS1_UIFM_FLAGS_STICKY_REG 0x20
#define XS1_UIFM_FLAGS_STICKY_DEFINED "6:0"
#define XS1_UIFM_FLAGS_STICKY_RESERVED 0x0
#define XS1_UIFM_FLAGS_STICKY_STICKY "6:0"
#define XS1_UIFM_FLAGS_STICKY_STICKY_RST 0x0
#define XS1_UIFM_FLAGS_MASK_REG 0x24
#define XS1_UIFM_FLAGS_MASK_DEFINED "31:0"
#define XS1_UIFM_FLAGS_MASK_MASK0 "7:0"
#define XS1_UIFM_FLAGS_MASK_MASK1 "15:8"
#define XS1_UIFM_FLAGS_MASK_MASK2 "23:16"
#define XS1_UIFM_FLAGS_MASK_MASK3 "31:24"
#define XS1_UIFM_FLAGS_MASK_RST 0x0
#define XS1_UIFM_SOFCOUNT_REG 0x28
#define XS1_UIFM_SOFCOUNT_DEFINED "10:0"
#define XS1_UIFM_SOFCOUNT_RESERVED 0x0
#define XS1_UIFM_SOFCOUNT_COUNT "10:0"
#define XS1_UIFM_SOFCOUNT_COUNT1 "7:0"
#define XS1_UIFM_SOFCOUNT_COUNT2 "10:8"
#define XS1_UIFM_SOFCOUNT_RST 0x0
#define XS1_UIFM_PID_REG 0x2c
#define XS1_UIFM_PID_DEFINED "3:0"
#define XS1_UIFM_PID_RESERVED 0x0
#define XS1_UIFM_PID_PID "3:0"
#define XS1_UIFM_PID_PID_MSB "3:2"
#define XS1_UIFM_PID_RST 0x0
#define XS1_UIFM_ENDPOINT_REG 0x30
#define XS1_UIFM_ENDPOINT_DEFINED "4:0"
#define XS1_UIFM_ENDPOINT_RESERVED 0x0
#define XS1_UIFM_ENDPOINT_ENDPOINT "3:0"
#define XS1_UIFM_ENDPOINT_MATCH 0x4
#define XS1_UIFM_ENDPOINT_RST 0x0
#define XS1_UIFM_ENDPOINT_MATCH_REG 0x34
#define XS1_UIFM_ENDPOINT_MATCH_DEFINED "15:0"
#define XS1_UIFM_ENDPOINT_MATCH_RESERVED 0x0
#define XS1_UIFM_ENDPOINT_MATCH_MATCH "15:0"
#define XS1_UIFM_ENDPOINT_MATCH_RST 0x0
#define XS1_UIFM_PWRSIG_REG 0x38
#define XS1_UIFM_PWRSIG_DEFINED "8:0"
#define XS1_UIFM_PWRSIG_RESERVED 0x0
#define XS1_UIFM_PWRSIG_DATA "7:0"
#define XS1_UIFM_PWRSIG_VALID 0x8
#define XS1_UIFM_PWRSIG_RST 0x0
#define XS1_UIFM_PHY_CONTROL_REG 0x3c
#define XS1_UIFM_PHY_CONTROL_DEFINED "18:0"
#define XS1_UIFM_PHY_CONTROL_RESERVED 0x0
#define XS1_UIFM_PHY_CONTROL_RST 0x2
#define XS1_UIFM_PHY_CONTROL_FORCERESET 0x0
#define XS1_UIFM_PHY_CONTROL_FORCESUSPEND 0x1
#define XS1_UIFM_PHY_CONTROL_TESTGO 0x2
#define XS1_UIFM_PHY_CONTROL_BISTGO 0x3
#define XS1_UIFM_PHY_CONTROL_PHYCONF "6:4"
#define XS1_UIFM_PHY_CONTROL_AUTORESUME 0x7
#define XS1_UIFM_PHY_CONTROL_SE0FILTVAL "11:8"
#define XS1_UIFM_PHY_CONTROL_SE0FILTVAL_BASE 0x8
#define XS1_UIFM_PHY_CONTROL_RESUMEK 0xc
#define XS1_UIFM_PHY_CONTROL_RESUMESE0 0xd
#define XS1_UIFM_PHY_CONTROL_PHYCLKCNT "17:14"
#define XS1_UIFM_PHY_CONTROL_PHYCLKCNT_BASE 0xe
#define XS1_UIFM_PHY_CONTROL_PULLDOWN_DISABLE 0x12
#define XS1_UIFM_PHY_TESTCODE_REG 0x40
#define XS1_UIFM_PHY_TESTCODE_DEFINED "3:0"
#define XS1_UIFM_PHY_TESTCODE_RST 0x0
#define XS1_UIFM_PHY_TESTCODE_RESERVED 0x0
#define XS1_UIFM_PHY_TESTCODE_CODE "3:0"
#define XS1_UIFM_PHY_TESTSTATUS_REG 0x44
#define XS1_UIFM_PHY_TESTSTATUS_DEFINED "10:0"
#define XS1_UIFM_PHY_TESTSTATUS_RST 0x0
#define XS1_UIFM_PHY_TESTSTATUS_RESERVED 0x0
#define XS1_UIFM_PHY_TESTSTATUS_DATA "7:0"
#define XS1_UIFM_PHY_TESTSTATUS_BISTOK 0x8
#define XS1_UIFM_PHY_TESTSTATUS_LINESTATEFILT "10:9"
#define XS1_UIFM_RXSTATE_IDLE 0x0
#define XS1_UIFM_RXSTATE_WAITIDLE 0x1
#define XS1_UIFM_RXSTATE_PID 0x2
#define XS1_UIFM_RXSTATE_TOKEN_ADDR 0x3
#define XS1_UIFM_RXSTATE_TOKEN_ENDP 0x4
#define XS1_UIFM_RXSTATE_DATA_PAYLOAD 0x5
#define XS1_UIFM_RXSTATE_SOF_FRAME1 0x6
#define XS1_UIFM_RXSTATE_SOF_FRAME2 0x7
#define XS1_UIFM_RXSTATE_PASSTHRU 0x8
#define XS1_UIFM_PORT_STATE_CMD 0x0
#define XS1_UIFM_PORT_STATE_RD 0x1
#define XS1_UIFM_PORT_STATE_WR 0x2
#define XS1_UIFM_PORT_STATE_WRACK 0x3
#define XS1_XMOS_USB_VCONTROL_WIDTH 0x4
#define XS1_XMOS_USB_VSTATUS_WIDTH 0x8
#define XS1_GLX_USB_RTC_TIME_LSBS_WIDTH 0x11
#define XS1_XMOS_USB_LINESTATE_FILTVAL_WIDTH 0x4
#define XS1_XMOS_USB_F_STATE_WIDTH 0x2
#define XS1_XMOS_USB_TESTCTR_WIDTH 0x10
#define XS1_XMOS_USB_SUS_FSM_WIDTH 0x4
#define XS1_XMOS_USB_SUS_DIVCTR_WIDTH 0x3
#define XS1_XMOS_UIFM_SOF_WIDTH 0xb
#define XS1_XMOS_UIFM_PID_WIDTH 0x4
#define XS1_XMOS_UIFM_ENDP_WIDTH 0x5
#define XS1_XMOS_UIFM_BRIDGE_FSM_WIDTH 0x4
#define XS1_GLX_ADC_CHAN0_CTRL_ADRS 0x0
#define XS1_GLX_ADC_CHAN1_CTRL_ADRS 0x4
#define XS1_GLX_ADC_CHAN2_CTRL_ADRS 0x8
#define XS1_GLX_ADC_CHAN3_CTRL_ADRS 0xc
#define XS1_GLX_ADC_CHAN4_CTRL_ADRS 0x10
#define XS1_GLX_ADC_CHAN5_CTRL_ADRS 0x14
#define XS1_GLX_ADC_CHAN6_CTRL_ADRS 0x18
#define XS1_GLX_ADC_CHAN7_CTRL_ADRS 0x1c
#define XS1_GLX_ADC_CHAN_EN_BASE 0x0
#define XS1_GLX_ADC_CHAN_EN_SIZE 0x1
#define XS1_GLX_ADC_CHAN_EN_BITS "0:0"
#define XS1_GLX_ADC_MISC_CTRL_ADRS 0x20
#define XS1_GLX_ADC_EN_BASE 0x0
#define XS1_GLX_ADC_EN_SIZE 0x1
#define XS1_GLX_ADC_EN_BITS "0:0"
#define XS1_GLX_ADC_GAIN_CAL_MODE_BASE 0x1
#define XS1_GLX_ADC_GAIN_CAL_MODE_SIZE 0x1
#define XS1_GLX_ADC_GAIN_CAL_MODE_BITS "1:1"
#define XS1_GLX_ADC_SAMP_PER_PKT_BASE 0x8
#define XS1_GLX_ADC_SAMP_PER_PKT_SIZE 0x8
#define XS1_GLX_ADC_SAMP_PER_PKT_BITS "15:8"
#define XS1_GLX_ADC_BITS_PER_SAMP_BASE 0x10
#define XS1_GLX_ADC_BITS_PER_SAMP_SIZE 0x2
#define XS1_GLX_ADC_BITS_PER_SAMP_BITS "17:16"
#define XS1_GLX_ADC_SAMP_DROPPED_BASE 0x18
#define XS1_GLX_ADC_SAMP_DROPPED_SIZE 0x1
#define XS1_GLX_ADC_SAMP_DROPPED_BITS "24:24"
#define XS1_GLX_ADC_NUM_CHANNELS 0x8
#define XS1_GLX_ADC_8BITS_PER_SAMP 0x0
#define XS1_GLX_ADC_16BITS_PER_SAMP 0x1
#define XS1_GLX_ADC_32BITS_PER_SAMP 0x3
#define XS1_GLX_ADC_SAMP_UPR_8BITS "11:4"
#define XS1_GLX_ADC_CHAN_SEL_SIZE 0x3
#define XS1_GLX_ADC_SAMPLE_SIZE 0xc
#define XS1_GLX_ADC_PWR_UP_TMR_SIZE 0x3
#define XS1_GLX_ADC_PWR_UP_TMR_EXP_VALUE 0x5
#define XS1_GLX_SCTH_BUFF_SIZE 0x80
#define XS1_GLX_XTAL_I_BGAP_SIZE 0x2
#define XS1_GLX_OSC_CTRL_ADRS 0x0
#define XS1_GLX_OSC_RST_EN_BASE 0x1
#define XS1_GLX_OSC_RST_EN_SIZE 0x1
#define XS1_GLX_OSC_RST_EN_BITS "1:1"
#define XS1_GLX_ON_SI_CTRL_ADRS 0x1
#define XS1_GLX_ON_SI_EN_BASE 0x0
#define XS1_GLX_ON_SI_EN_SIZE 0x1
#define XS1_GLX_ON_SI_EN_BITS "0:0"
#define XS1_GLX_XTAL_CTRL_ADRS 0x2
#define XS1_GLX_RTC_DATA_SIZE 0x20
#define XS1_GLX_RTC_TMR_SIZE 0x40
#define XS1_GLX_RTC_LWR_32BIT_ADRS 0x0
#define XS1_GLX_RTC_LWR_32BIT_BASE 0x0
#define XS1_GLX_RTC_LWR_32BIT_SIZE 0x20
#define XS1_GLX_RTC_LWR_32BIT_BITS "31:0"
#define XS1_GLX_RTC_UPR_32BIT_ADRS 0x4
#define XS1_GLX_RTC_UPR_32BIT_BASE 0x20
#define XS1_GLX_RTC_UPR_32BIT_SIZE 0x20
#define XS1_GLX_RTC_UPR_32BIT_BITS "63:32"
#define XS1_GLX_PWR_MISC_CTRL_ADRS 0x0
#define XS1_GLX_PWR_SLEEP_CLK_SEL_BASE 0x0
#define XS1_GLX_PWR_SLEEP_CLK_SEL_SIZE 0x1
#define XS1_GLX_PWR_SLEEP_CLK_SEL_BITS "0:0"
#define XS1_GLX_PWR_SLEEP_INIT_BASE 0x1
#define XS1_GLX_PWR_SLEEP_INIT_SIZE 0x1
#define XS1_GLX_PWR_SLEEP_INIT_BITS "1:1"
#define XS1_GLX_PWR_PIN_WAKEUP_EN_BASE 0x2
#define XS1_GLX_PWR_PIN_WAKEUP_EN_SIZE 0x1
#define XS1_GLX_PWR_PIN_WAKEUP_EN_BITS "2:2"
#define XS1_GLX_PWR_PIN_WAKEUP_ON_BASE 0x3
#define XS1_GLX_PWR_PIN_WAKEUP_ON_SIZE 0x1
#define XS1_GLX_PWR_PIN_WAKEUP_ON_BITS "3:3"
#define XS1_GLX_PWR_TMR_WAKEUP_EN_BASE 0x4
#define XS1_GLX_PWR_TMR_WAKEUP_EN_SIZE 0x1
#define XS1_GLX_PWR_TMR_WAKEUP_EN_BITS "4:4"
#define XS1_GLX_PWR_TMR_WAKEUP_64_BASE 0x5
#define XS1_GLX_PWR_TMR_WAKEUP_64_SIZE 0x1
#define XS1_GLX_PWR_TMR_WAKEUP_64_BITS "5:5"
#define XS1_GLX_PWR_USB_PD_EN_BASE 0x8
#define XS1_GLX_PWR_USB_PD_EN_SIZE 0x1
#define XS1_GLX_PWR_USB_PD_EN_BITS "8:8"
#define XS1_GLX_PWR_USB_PU_EN_BASE 0x9
#define XS1_GLX_PWR_USB_PU_EN_SIZE 0x1
#define XS1_GLX_PWR_USB_PU_EN_BITS "9:9"
#define XS1_GLX_PWR_WAKEUP_TMR_LWR_ADRS 0x4
#define XS1_GLX_PWR_WAKEUP_TMR_LWR_BASE 0x0
#define XS1_GLX_PWR_WAKEUP_TMR_LWR_SIZE 0x20
#define XS1_GLX_PWR_WAKEUP_TMR_LWR_BITS "31:0"
#define XS1_GLX_PWR_WAKEUP_TMR_UPR_ADRS 0x8
#define XS1_GLX_PWR_WAKEUP_TMR_UPR_BASE 0x0
#define XS1_GLX_PWR_WAKEUP_TMR_UPR_SIZE 0x20
#define XS1_GLX_PWR_WAKEUP_TMR_UPR_BITS "31:0"
#define XS1_GLX_PWR_VOUT1_EN_BASE 0x0
#define XS1_GLX_PWR_VOUT1_EN_SIZE 0x1
#define XS1_GLX_PWR_VOUT1_EN_BITS "0:0"
#define XS1_GLX_PWR_VOUT2_EN_BASE 0x1
#define XS1_GLX_PWR_VOUT2_EN_SIZE 0x1
#define XS1_GLX_PWR_VOUT2_EN_BITS "1:1"
#define XS1_GLX_PWR_VOUT3_EN_BASE 0x2
#define XS1_GLX_PWR_VOUT3_EN_SIZE 0x1
#define XS1_GLX_PWR_VOUT3_EN_BITS "2:2"
#define XS1_GLX_PWR_VOUT4_EN_BASE 0x3
#define XS1_GLX_PWR_VOUT4_EN_SIZE 0x1
#define XS1_GLX_PWR_VOUT4_EN_BITS "3:3"
#define XS1_GLX_PWR_VOUT5_EN_BASE 0x4
#define XS1_GLX_PWR_VOUT5_EN_SIZE 0x1
#define XS1_GLX_PWR_VOUT5_EN_BITS "4:4"
#define XS1_GLX_PWR_VOUT6_EN_BASE 0x5
#define XS1_GLX_PWR_VOUT6_EN_SIZE 0x1
#define XS1_GLX_PWR_VOUT6_EN_BITS "5:5"
#define XS1_GLX_PWR_VOUT7_EN_BASE 0x6
#define XS1_GLX_PWR_VOUT7_EN_SIZE 0x1
#define XS1_GLX_PWR_VOUT7_EN_BITS "6:6"
#define XS1_GLX_PWR_EXT_CLK_MASK_BASE 0xe
#define XS1_GLX_PWR_EXT_CLK_MASK_SIZE 0x1
#define XS1_GLX_PWR_EXT_CLK_MASK_BITS "14:14"
#define XS1_GLX_PWR_INT_EXP_BASE 0x10
#define XS1_GLX_PWR_INT_EXP_SIZE 0x5
#define XS1_GLX_PWR_INT_EXP_BITS "20:16"
#define XS1_GLX_PWR_STATE_ASLEEP_ADRS 0xc
#define XS1_GLX_PWR_STATE_WAKING1_ADRS 0x10
#define XS1_GLX_PWR_STATE_WAKING2_ADRS 0x14
#define XS1_GLX_PWR_STATE_AWAKE_ADRS 0x18
#define XS1_GLX_PWR_STATE_SLEEPING1_ADRS 0x1c
#define XS1_GLX_PWR_STATE_SLEEPING2_ADRS 0x20
#define XS1_GLX_PWR_SEQUENCE_DBG_ADRS 0x24
#define XS1_GLX_PWR_SM_PTR_BASE 0x10
#define XS1_GLX_PWR_SM_PTR_SIZE 0x3
#define XS1_GLX_PWR_SM_PTR_BITS "18:16"
#define XS1_GLX_PWR_SEQUENCE_TMR_DBG_ADRS 0x28
#define XS1_GLX_PWR_INT_TMR_BASE 0x0
#define XS1_GLX_PWR_INT_TMR_SIZE 0x20
#define XS1_GLX_PWR_INT_TMR_BITS "31:0"
#define XS1_GLX_PWR_PMU_CTRL_ADRS 0x2c
#define XS1_GLX_PWR_VOUT1_CLK_DIV_BASE 0x0
#define XS1_GLX_PWR_VOUT1_CLK_DIV_SIZE 0x5
#define XS1_GLX_PWR_VOUT1_CLK_DIV_BITS "4:0"
#define XS1_GLX_PWR_VOUT1_CLIMIT_BASE 0x5
#define XS1_GLX_PWR_VOUT1_CLIMIT_SIZE 0x2
#define XS1_GLX_PWR_VOUT1_CLIMIT_BITS "6:5"
#define XS1_GLX_PWR_VOUT2_CLK_DIV_BASE 0x8
#define XS1_GLX_PWR_VOUT2_CLK_DIV_SIZE 0x5
#define XS1_GLX_PWR_VOUT2_CLK_DIV_BITS "12:8"
#define XS1_GLX_PWR_VOUT2_CLIMIT_BASE 0xd
#define XS1_GLX_PWR_VOUT2_CLIMIT_SIZE 0x2
#define XS1_GLX_PWR_VOUT2_CLIMIT_BITS "14:13"
#define XS1_GLX_PWR_CLR_ERR_FLAG_BASE 0x10
#define XS1_GLX_PWR_CLR_ERR_FLAG_SIZE 0x1
#define XS1_GLX_PWR_CLR_ERR_FLAG_BITS "16:16"
#define XS1_GLX_PWR_1V0_PG_DEASSERT_BASE 0x18
#define XS1_GLX_PWR_1V0_PG_DEASSERT_SIZE 0x2
#define XS1_GLX_PWR_1V0_PG_DEASSERT_BITS "25:24"
#define XS1_GLX_PWR_1V0_PG_DEASSERT_0V8 0x0
#define XS1_GLX_PWR_1V0_PG_DEASSERT_0V85 0x1
#define XS1_GLX_PWR_1V0_PG_DEASSERT_0V9 0x2
#define XS1_GLX_PWR_1V0_PG_DEASSERT_0V75 0x3
#define XS1_GLX_PWR_PMU_DBG_ADRS 0x30
#define XS1_GLX_PWR_VOUT1_SFT_ST_BASE 0x0
#define XS1_GLX_PWR_VOUT1_SFT_ST_SIZE 0x1
#define XS1_GLX_PWR_VOUT1_SFT_ST_BITS "0:0"
#define XS1_GLX_PWR_VOUT2_SFT_ST_BASE 0x1
#define XS1_GLX_PWR_VOUT2_SFT_ST_SIZE 0x1
#define XS1_GLX_PWR_VOUT2_SFT_ST_BITS "1:1"
#define XS1_GLX_PWR_VOUT1_CL_FLAG_BASE 0x8
#define XS1_GLX_PWR_VOUT1_CL_FLAG_SIZE 0x1
#define XS1_GLX_PWR_VOUT1_CL_FLAG_BITS "8:8"
#define XS1_GLX_PWR_VOUT2_CL_FLAG_BASE 0x9
#define XS1_GLX_PWR_VOUT2_CL_FLAG_SIZE 0x1
#define XS1_GLX_PWR_VOUT2_CL_FLAG_BITS "9:9"
#define XS1_GLX_PWR_VOUT1_PG_BASE 0x10
#define XS1_GLX_PWR_VOUT1_PG_SIZE 0x1
#define XS1_GLX_PWR_VOUT1_PG_BITS "16:16"
#define XS1_GLX_PWR_VOUT3_PG_BASE 0x11
#define XS1_GLX_PWR_VOUT3_PG_SIZE 0x1
#define XS1_GLX_PWR_VOUT3_PG_BITS "17:17"
#define XS1_GLX_PWR_VOUT4_PG_BASE 0x12
#define XS1_GLX_PWR_VOUT4_PG_SIZE 0x1
#define XS1_GLX_PWR_VOUT4_PG_BITS "18:18"
#define XS1_GLX_PWR_VOUT5_PG_BASE 0x13
#define XS1_GLX_PWR_VOUT5_PG_SIZE 0x1
#define XS1_GLX_PWR_VOUT5_PG_BITS "19:19"
#define XS1_GLX_PWR_ON_SI_STBL_BASE 0x18
#define XS1_GLX_PWR_ON_SI_STBL_SIZE 0x1
#define XS1_GLX_PWR_ON_SI_STBL_BITS "24:24"
#define XS1_GLX_PWR_VOUT1_LVL_ADRS 0x34
#define XS1_GLX_PWR_VOUT3_LVL_ADRS 0x38
#define XS1_GLX_PWR_VOUT4_LVL_ADRS 0x3c
#define XS1_GLX_PWR_VOUT5_LVL_ADRS 0x40
#endif /* _xa1_registers_h_ */
