##
## Top-level makefile for building the default framework VMs
##

# First, define VM framework's directory & include it!
FRAMEWORK_DIR ?= .
include $(FRAMEWORK_DIR)/framework.mk
include $(FRAMEWORK_DIR)/lib/inc_all.mk

# set default goal
DEFAULT_GOAL = init

# Create new base VM
BASE ?= ubuntu
$(call vm_new_base_$(BASE),base)

# Cloud image
$(call vm_new_layer_cloud,cloud)
cloud-name = $(base-prefix)_cloud
cloud-src-from = base
# always update scripts from framework (prevent re-building base on changes)
cloud-copy-scripts = $(abspath $(FRAMEWORK_DIR)/scripts)/
cloud-copy-scripts += $(VM_CLOUD_SCRIPTS_DIR)

# list with all VMs to generate rules for
build-vms += base cloud

$(call vm_eval_all_rules)

