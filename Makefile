##
## Top-level makefile for building the default framework VMs
##

# First, define VM framework's directory & include it!
FRAMEWORK_DIR ?= .
include $(FRAMEWORK_DIR)/framework.mk

# set default goal
DEFAULT_GOAL = init

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
cloudvm-src-from = basevm

# list with all VMs to generate rules for
build-vms += basevm cloudvm

$(call eval_common_rules)
$(call eval_all_vm_rules)

