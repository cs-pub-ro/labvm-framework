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
# Dependencies (yep, all, of them ;) almost) 
include $(FRAMEWORK_DIR)/framework.mk
include $(FRAMEWORK_DIR)/base/ubuntu/build.mk
include $(FRAMEWORK_DIR)/layers/generic/build.mk
include $(FRAMEWORK_DIR)/layers/cloud/build.mk
include $(FRAMEWORK_DIR)/layers/full-featured/build.mk
include $(FRAMEWORK_DIR)/lib/gen_vm_combo.mk
include $(FRAMEWORK_DIR)/lib/zerofree.mk

# set default goals
DEFAULT_GOAL = main
INIT_GOAL = main

# Ubuntu Server 22.04 base VM
$(call vm_new_base_ubuntu,base)
base-ver = 22

# example versioning & unified prefix scheme
vm-ver = 2024.01
vm-prefix = example_$(vm-ver)

# Example generic VM with customizations
# [re]build with `make main_clean main`
$(call vm_new_layer_generic,main)
main-name = $(vm-prefix)_main
# always update scripts from framework (prevent re-building base on changes)
main-copy-scripts = $(abspath $(FRAMEWORK_DIR)/scripts)/
main-copy-scripts += $(abspath ./main/scripts)/

# Example VM starting from the full-featured layer
# [re]build with `make full_clean full`
$(call vm_new_layer_full_featured,full)
full-name = $(vm-prefix)_full
# same as above, include scripts from framework, full layer + our own overrides
full-copy-scripts = $(abspath $(FRAMEWORK_DIR)/scripts)/
full-copy-scripts += $(VM_FULL_FEATURED_SCRIPTS_DIR)
# also add our main scripts (since we can ;) )
full-copy-scripts += $(abspath ./main/scripts)/

# Export the main VM to both VirtualBox & VMware using the ComboVM rules
# [re]build with `make exported_clean exported`
exported_name = $(vm-prefix)_exported
# must change the target's type to `vm-combo` for combo export rules
exported_type = vm-combo
exported_vmname = Example ComboVM
exported_src-from = main

# Cloud image based on full VM
# [re]build with `make full_cloud_clean full_cloud`
$(call vm_new_layer_cloud,full_cloud)
full_cloud-name = $(vm-prefix)_full_cloud
full_cloud-src-from = full
full_cloud-copy-scripts = $(abspath $(FRAMEWORK_DIR)/scripts)/
full_cloud-copy-scripts += $(VM_CLOUD_SCRIPTS_DIR)
full_cloud-copy-scripts += $(abspath ./cloud/script-overrides)/
# use `make full_cloud_compact` to run zerofree on its image
full_cloud-extra-rules += $(vm_zerofree_rule)

# List of targets to generate rules for (note: must manually order them
# topologically, i.e. build dependencies before their targets)
build-vms += base main full exported full_cloud

$(call eval_common_rules)
$(call eval_all_vm_rules)

