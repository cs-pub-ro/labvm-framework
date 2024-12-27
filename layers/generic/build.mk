## Generic VM layer build macros

## Variables  you can override them inside your Makefile):

# scripts relative to the current makefile
VM_GENERIC_SCRIPTS_DIR ?= $(abspath ./scripts)/
# generic layer's packer source dir
VM_GENERIC_PKR_SRC ?= $(FRAMEWORK_DIR)/layers/generic
# source (base) target to use
VM_GENERIC_SRC_FROM ?= base
# optional authorized keys (first one found, if any)
VM_AUTHORIZED_KEYS ?= $(abspath $(firstword $(wildcard dist/*authorized_keys*)))

# use with $(eval $(call vm_new_layer_generic,vm-id))
define vm_new_layer_generic=
$(1)-name ?= $(1)
$(1)-packer-src = $$(VM_GENERIC_PKR_SRC)
$(1)-packer-args ?=
$(1)-packer-args += -var "vm_scripts_dir=" -var 'vm_scripts_list=$$(call \
	_packer_json_list,$$($(1)-copy-scripts))'
$(1)-packer-args += -var "vm_authorized_keys=$$(VM_AUTHORIZED_KEYS)"
$(1)-copy-scripts ?= $(VM_GENERIC_SCRIPTS_DIR)
$(1)-src-from ?= $$(VM_GENERIC_SRC_FROM)

endef
