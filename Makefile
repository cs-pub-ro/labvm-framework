##
## Top-level makefile for building the default framework VMs
##

# First, define VM framework's directory & include it!
FRAMEWORK_DIR ?= .
include $(FRAMEWORK_DIR)/framework.mk
include $(FRAMEWORK_DIR)/base/ubuntu/build.mk
include $(FRAMEWORK_DIR)/layers/cloud/build.mk

# set default goal
DEFAULT_GOAL = init

# Ubuntu Server base VM
$(call vm_new_base_ubuntu,base)
# VM destination file (automatically generated var.)
#base-dest-image = $(BUILD_DIR)/$(base-name)/$(base-name).qcow2

# Cloud image
$(call vm_new_layer_cloud,cloud)
cloud-name = ubuntu_$(base-ver)_cloud
cloud-src-from = base

# list with all VMs to generate rules for
build-vms += base cloud

$(call eval_common_rules)
$(call eval_all_vm_rules)

