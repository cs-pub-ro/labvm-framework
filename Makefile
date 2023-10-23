# Makefile for building the default (base + cloud) VMs
DEFAULT_GOAL ?= basevm
INIT_GOAL ?= basevm

# Fresh Ubuntu Server base VM
ubuntu-ver = 22
basevm-name = ubuntu_$(ubuntu-ver)_base
basevm-packer-src = $(FRAMEWORK_DIR)/basevm
basevm-src-image = $(BASE_VM_INSTALL_ISO)
# VM destination file (automatically generated var.)
#basevm-dest-image = $(BUILD_DIR)/$(basevm-name)/$(basevm-name).qcow2

# Cloud-init image
cloudvm-name = ubuntu_$(ubuntu-ver)_cloud
cloudvm-packer-src = $(FRAMEWORK_DIR)/cloudvm
cloudvm-src-image = $(basevm-dest-image)

# list with all VMs to generate rules for
build-vms += basevm cloudvm

# include library & evaluate the rules
include framework.mk

$(call eval_common_rules)
$(call eval_all_vm_rules)

