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

# VM architecture
VM_ARCH = amd64
# change default base (optional: only if you use this variable)
#BASE ?= debian
# base OS versions
DEBIAN_VERSION ?= 13
UBUNTU_VERSION ?= 24
# OS installer .iso paths
BASE_ISO_DIR ?= $(HOME)/Downloads/iso
UBUNTU_ISO_NAME ?= ubuntu-$(UBUNTU_VERSION).*-live-server-$(VM_ARCH).iso
DEBIAN_ISO_NAME ?= debian-$(DEBIAN_VERSION).*-$(VM_ARCH)-netinst.iso

_UBUNTU_ISO_FULL ?= $(call _find_last_file,$(BASE_ISO_DIR)/$(UBUNTU_ISO_NAME))
$(info UBUNTU ISO: $(_UBUNTU_ISO_FULL))

# VM defaults (for base images)
VM_TIMEZONE ?= Europe/Bucharest
VM_LOCALE ?= en_US
#VM_HOSTNAME ?= ubuntu  # auto: defaults to distro name

# Default user & password
# (passed as args - NOT SECURE! set something temporary in here!)
VM_USER ?= student
VM_PASSWORD ?= student
VM_CRYPTED_PASSWORD ?= $(shell mkpasswd -m sha-512 '$(VM_PASSWORD)')

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
			   $(call _packer_var,vm_debug,$(DEBUG)) \
			   $(call _packer_var,ssh_username,$(VM_USER)) \
			   $(call _packer_var,ssh_password,$(VM_PASSWORD))
PACKER_ARGS += $(PACKER_ARGS_EXTRA)

# ssh goal parameters
SSH ?= ssh
SSH_USER ?= student
SSH_PORT ?= 20022
SSH_ARGS ?= -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null

