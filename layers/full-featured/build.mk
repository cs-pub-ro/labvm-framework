## Fully featured VM layer build macros
$(call mk_include_guard,vm_layer_full_featured)

## Config variables: you can override them inside your Makefile):

# scripts relative to the current makefile
VM_FULL_FEATURED_SCRIPTS_DIR ?= $(abspath $(FRAMEWORK_DIR)/layers/full-featured/scripts)/
# source (base) target to use
VM_FULL_FEATURED_SRC_FROM ?= base

define _vm_new_layer_full_featured_tpl
$(call check-var,_vm_new_layer_generic_tpl)$(_vm_new_layer_generic_tpl)
$(1)-script-prepare = full-prepare.sh
$(1)-script-stage1 = install-stage1.d
$(1)-script-stage2 = install-stage2.d
$(1)-copy-scripts = $$(VM_FULL_FEATURED_SCRIPTS_DIR)
$(1)-src-from = $$(VM_FULL_FEATURED_SRC_FROM)

endef
# use with $(call vm_new_layer_full_featured,vm-id)
vm_new_layer_full_featured = $(eval $(_vm_new_layer_full_featured_tpl))

