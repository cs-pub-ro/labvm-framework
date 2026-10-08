## QEMU debugging tools

# HEADLESS=1 -> run qemu without a GUI (VNC is still available)
HEADLESS ?= 0
# QEMU_MONITOR=<path> -> expose the QEMU HMP monitor on a UNIX socket
QEMU_MONITOR ?=
# QEMU_SERIAL=<path> -> log the guest serial console to a file
QEMU_SERIAL ?=
# convenience switch enabling all of the above
DEBUG_CONSOLE ?=
ifneq ($(filter-out 0 no false,$(DEBUG_CONSOLE)),)
HEADLESS := 1
ifeq ($(QEMU_MONITOR),)
QEMU_MONITOR := $(BUILD_DIR)/qemu-monitor.sock
endif
ifeq ($(QEMU_SERIAL),)
QEMU_SERIAL := $(BUILD_DIR)/qemu-serial.log
endif
endif
# Packer expects a real boolean for the `headless` variable
HEADLESS_PACKER = $(if $(filter-out 0 no false,$(HEADLESS)),true,false)

