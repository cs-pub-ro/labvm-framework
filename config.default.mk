# Default make configuration variables

# just in case you want to change it, do it from your Makefile
USER_CONFIG_DIR ?= .
-include $(USER_CONFIG_DIR)/config.local.mk

# Framework self-reference (relative) directory (should be set in Makefile)
#FRAMEWORK_DIR ?= .

# Default / initial goals (may also be set in Makefile)
DEFAULT_GOAL ?= init
INIT_GOAL ?= $(build-vms)

# Packer base build directory
BUILD_DIR ?= $(HOME)/.cache/packer

# Base OS installation .iso image
BASE_VM_INSTALL_ISO ?= $(HOME)/Downloads/ubuntu-22.04.3-server-amd64.iso

# Build modifiers
DELETE ?=
FORCE ?= $(DELETE)
DEBUG ?=
PACKER_DEBUG ?=
PAUSE ?= $(DEBUG)

# Packer invocation arguments
PACKER ?= packer
PACKER_ARGS_EXTRA ?=
PACKER_ARGS ?= -on-error=abort $(if $(PACKER_DEBUG),-debug) \
			   $(call _packer_var,vm_pause,$(PAUSE)) \
			   $(call _packer_var,vm_debug,$(DEBUG))
PACKER_ARGS += $(PACKER_ARGS_EXTRA)

# ssh goal parameters
SSH ?= ssh
SSH_USER ?= student
SSH_PORT ?= 20022
SSH_ARGS ?= -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null

