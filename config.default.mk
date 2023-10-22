# Default make configuration variables

# Framework self-reference (relative) directory
FRAMEWORK_DIR ?= .

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
PACKER_ARGS ?= -on-error=abort $(if $(PACKER_DEBUG),-debug) \
			   $(call _packer_var,vm_pause,$(PAUSE)) \
			   $(call _packer_var,vm_debug,$(DEBUG))

# ssh goal parameters
SSH ?= ssh
SSH_USER ?= student
SSH_PORT ?= 20022
SSH_ARGS ?= -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null

# Load user overrides
include config.local.mk

