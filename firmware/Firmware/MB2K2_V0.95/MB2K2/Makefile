# The TARGET variable determines what target system the application is
# compiled for. It either refers to an XN file in the source directories
# or a valid argument for the --target option when compiling.

# In this case, the target depends on the build configuration.
TARGET = mb2k2_v1

# The APP_NAME variable determines the name of the final .xe file. It should
# not include the .xe postfix. If left blank the name will default to
# the project name
APP_NAME = mb2k2

# The flags passed to xcc when building the application
# You can also set the following to override flags for a particular language:
#
#    XCC_XC_FLAGS, XCC_C_FLAGS, XCC_ASM_FLAGS, XCC_CPP_FLAGS
#
# If the variable XCC_MAP_FLAGS is set it overrides the flags passed to
# xcc for the final link (mapping) stage.

# These flags define two build configurations - one for U-series and one for
# the xCORE-200 series.

BUILD_FLAGS = -report -DXUD_SERIES_SUPPORT=XUD_X200_SERIES -g -DUSB_TILE=tile[1] -lquadflash
XCC_FLAGS_xud_cdc.xc = $(XCC_FLAGS) -O1 -finline-functions
XCC_FLAGS_ps2.xc = $(XCC_FLAGS) -O1 -finline-functions

XCC_FLAGS_release_usb = $(BUILD_FLAGS) -O3 -DDEBUG_PRINT_ENABLE=0 -DUSB_SERIAL
XCC_FLAGS_release_ftdi = $(BUILD_FLAGS) -O3 -DDEBUG_PRINT_ENABLE=0 -DFTDI_SERIAL
XCC_FLAGS_debug_usb = $(BUILD_FLAGS) -O0 -DDEBUG_PRINT_ENABLE=1 -DUSB_SERIAL
XCC_FLAGS_debug_ftdi = $(BUILD_FLAGS) -O0 -DDEBUG_PRINT_ENABLE=1 -DFTDI_SERIAL

# The USED_MODULES variable lists other module used by the application.
USED_MODULES = lib_logging lib_trycatch lib_uart lib_usb lib_xassert lib_xcore_c

#=============================================================================
# The following part of the Makefile includes the common build infrastructure
# for compiling XMOS applications. You should not need to edit below here.

XMOS_MAKE_PATH ?= ../..
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
