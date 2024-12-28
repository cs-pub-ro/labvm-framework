##
## Top-level makefile for building the default framework VMs
##

# First, define VM framework's directory & include it!
FRAMEWORK_DIR ?= .
include $(FRAMEWORK_DIR)/framework.mk
include $(FRAMEWORK_DIR)/base/ubuntu/build.mk

# set default goal
DEFAULT_GOAL = init

# Ubuntu Server base VM
$(call vm_new_base_ubuntu,base)
# VM destination file (automatically generated var.)
#base-dest-image = $(BUILD_DIR)/$(base-name)/$(base-name).qcow2

# Cloud-init image
cloudvm-name = ubuntu_$(ubuntu-ver)_cloud
cloudvm-packer-src = $(FRAMEWORK_DIR)/cloudvm
cloudvm-src-from = base

# list with all VMs to generate rules for
build-vms += base cloudvm

$(call eval_common_rules)
$(call eval_all_vm_rules)

