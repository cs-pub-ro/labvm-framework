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
include $(FRAMEWORK_DIR)/lib/gen_vm_combo.mk

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
examplevm-src-from = basevm

# Export example to VirtualBox & VMware
vbox-name = example_vbox_$(examplevm-ver)
vbox-type = vbox
vbox-vmname = Example VBox VM
vbox-src-from = examplevm

vmware-name = example_vmware_$(examplevm-ver)
vmware-type = vmware
vmware-vmname = Example VMX VM
vmware-src-from = examplevm

combovm-name = example_prj_$(examplevm-ver)
combovm-type = vm-combo
combovm-vmname = Example Combo VM
combovm-src-from = examplevm

# Cloud-init image (based on examplevm!, see src-image)
cloudvm-name = ubuntu_$(ubuntu-ver)_cloud
cloudvm-packer-src = $(FRAMEWORK_DIR)/cloudvm
cloudvm-src-from = examplevm

# list with all VMs to generate rules for (note: use dependency ordering!)
build-vms += basevm examplevm vbox vmware combovm cloudvm

$(call eval_common_rules)
$(call eval_all_vm_rules)

