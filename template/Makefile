##
## Top-level makefile for example (template) VM
##

# First, define VM framework's directory & include it!
# Our example is a subdirectory inside framework's dir!
FRAMEWORK_DIR ?= ..
# TODO: you might want it to point to the submodule's subdirectory:
#FRAMEWORK_DIR ?= ./framework
# you can also modify USER_CONFIG_DIR (where config.local.mk is loaded from)
USER_CONFIG_DIR = ..
include $(FRAMEWORK_DIR)/framework.mk

# set default goals
DEFAULT_GOAL = examplevm
INIT_GOAL = examplevm

# Fresh Ubuntu Server base VM
ubuntu-ver = 22
basevm-name = ubuntu_$(ubuntu-ver)_base
basevm-packer-src = $(FRAMEWORK_DIR)/basevm
basevm-src-image = $(BASE_VM_INSTALL_ISO)
# VM destination file (automatically generated var.)
#basevm-dest-image = $(BUILD_DIR)/$(basevm-name)/$(basevm-name).qcow2

# Example VM with customizations
examplevm-ver = 2023.01
examplevm-name = examplevm_$(examplevm-ver)
examplevm-packer-src = ./examplevm
examplevm-src-image = $(basevm-dest-image)

# Cloud-init image (based on examplevm!, see src-image)
cloudvm-name = ubuntu_$(ubuntu-ver)_cloud
cloudvm-packer-src = $(FRAMEWORK_DIR)/cloudvm
cloudvm-src-image = $(examplevm-dest-image)

# list with all VMs to generate rules for (note: use dependency ordering!)
build-vms += basevm examplevm cloudvm

$(call eval_common_rules)
$(call eval_all_vm_rules)

