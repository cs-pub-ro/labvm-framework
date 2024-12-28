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
include $(FRAMEWORK_DIR)/base/ubuntu/build.mk
include $(FRAMEWORK_DIR)/layers/generic/build.mk
include $(FRAMEWORK_DIR)/layers/cloud/build.mk
include $(FRAMEWORK_DIR)/lib/gen_vm_combo.mk

# set default goals
DEFAULT_GOAL = examplevm
INIT_GOAL = examplevm

# Ubuntu Server 22.04 base VM
$(call vm_new_base_ubuntu,base)
base-ver = 22

# Example VM with customizations
$(call vm_new_layer_generic,examplevm)
examplevm-ver = 2024.01
examplevm-name = examplevm_$(examplevm-ver)
# always update scripts from framework (prevent re-building base on changes)
examplevm-copy-scripts = $(abspath $(FRAMEWORK_DIR)/scripts)/
examplevm-copy-scripts += $(abspath ./examplevm/scripts)/

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

# Cloud image
$(call vm_new_layer_cloud,cloud)
cloud-name = ubuntu_$(base-ver)_cloud
cloud-src-from = examplevm
cloud-copy-scripts = $(abspath $(FRAMEWORK_DIR)/scripts)/
cloud-copy-scripts += $(VM_CLOUD_SCRIPTS_DIR)/
cloud-copy-scripts += $(abspath ./cloud/script-overrides)/

# list with all VMs to generate rules for (note: use dependency ordering!)
build-vms += base examplevm vbox vmware combovm cloud

$(call eval_common_rules)
$(call eval_all_vm_rules)

