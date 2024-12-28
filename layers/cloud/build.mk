## Cloud VM layer build macros

## Variables  you can override them inside your Makefile):

# scripts relative to the current makefile
VM_CLOUD_SCRIPTS_DIR ?= $(abspath $(FRAMEWORK_DIR)/layers/cloud/scripts)/
# use generic's .pkr.hcl script
VM_CLOUD_PKR_SRC ?= $(FRAMEWORK_DIR)/layers/generic
# source (base) target to use
VM_CLOUD_SRC_FROM ?= main
# optional authorized keys (first one found, if any)
VM_AUTHORIZED_KEYS ?= $(abspath $(firstword $(wildcard dist/*authorized_keys*)))

# NOTE: evaluated twice, 1st by the vm_new_* macro, 2nd by eval_all_vm_rules
define _vm_new_layer_cloud_tpl
$(1)-name ?= $(1)
$(1)-packer-src = $(VM_CLOUD_PKR_SRC)
$(1)-packer-args ?=
$(1)-packer-args += -var "vm_scripts_dir=" -var 'vm_scripts_list=$$(call \
	_packer_json_list,$$($(1)-copy-scripts))'
$(1)-packer-args += -var 'vm_install_stage1=$$$$(dollar)VM_SCRIPTS_DIR/install-cloud.d/'
$(1)-packer-args += -var "vm_authorized_keys=$$(VM_AUTHORIZED_KEYS)"
$(1)-copy-scripts ?= $(VM_CLOUD_SCRIPTS_DIR)
$(1)-src-from ?= $(VM_CLOUD_SRC_FROM)

endef
# use with $(call vm_new_layer_cloud,vm-id)
vm_new_layer_cloud = $(eval $(_vm_new_layer_cloud_tpl))

