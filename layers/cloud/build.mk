## Cloud VM layer build macros

## Config variables: you can override them inside your Makefile):

# scripts relative to the current makefile
VM_CLOUD_SCRIPTS_DIR ?= $(abspath $(FRAMEWORK_DIR)/layers/cloud/scripts)/
# source (base) target to use
VM_CLOUD_SRC_FROM ?= main

define _vm_new_layer_cloud_tpl
$(call check-var,_vm_new_layer_generic_tpl)$(_vm_new_layer_generic_tpl)
$(1)-name ?= $(1)
$(1)-script-stage1 ?= install-cloud.d
$(1)-copy-scripts ?= $(VM_CLOUD_SCRIPTS_DIR)
$(1)-src-from ?= $$(VM_CLOUD_SRC_FROM)

endef
# use with $(call vm_new_layer_cloud,vm-id)
vm_new_layer_cloud = $(eval $(_vm_new_layer_cloud_tpl))

