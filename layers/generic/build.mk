## Generic VM layer build macros

## Config variables: you can override them inside your Makefile):

# scripts relative to the current makefile
VM_GENERIC_SCRIPTS_DIR ?= $(abspath ./scripts)/
# generic layer's packer source dir
VM_GENERIC_PKR_SRC ?= $(FRAMEWORK_DIR)/layers/generic
# source (base) target to use
VM_GENERIC_SRC_FROM ?= base
# optional authorized keys (first one found, if any)
VM_AUTHORIZED_KEYS ?= $(abspath $(_find_file_in_path *authorized_keys*,\
					  ./dist $(USER_CONFIG_DIR)/dist))

-vm-copy-scripts = $(call _def_value,$(vm)-copy-scripts,)
-vm-copy-scripts-list = $(call _packer_json_list,$(-vm-copy-scripts))

# macros to check whether script/dir exists and supply provisioning defaults
-vm-generic-prepare = $(strip $(call _def_value,$(vm)-script-prepare,\
		$(notdir $(call _find_file_in_path,vm-prepare.sh,$(-vm-copy-scripts)))))
-vm-generic-stage1 = $(strip $(call _def_value,$(vm)-script-stage1,\
		$(notdir $(call _find_file_in_path,install-stage1.d,$(-vm-copy-scripts)))))
-vm-generic-stage2 = $(strip $(call _def_value,$(vm)-script-stage2,\
		$(notdir $(call _find_file_in_path,install-stage2.d,$(-vm-copy-scripts)))))

define _vm_new_layer_generic_tpl=
$(1)-name ?= $(1)
$(1)-packer-src = $$(VM_GENERIC_PKR_SRC)
$(1)-packer-args ?=
$(1)-packer-args += -var 'vm_scripts_dir=' \
	-var 'vm_scripts_list=$$(-vm-copy-scripts-list)' \
	-var 'vm_prepare_script=$$(-vm-generic-prepare)' \
	-var 'vm_install_stage1=$$(-vm-generic-stage1)' \
	-var 'vm_install_stage2=$$(-vm-generic-stage2)' \
	-var 'vm_authorized_keys=$$(VM_AUTHORIZED_KEYS)'
$(1)-copy-scripts ?= $$(VM_GENERIC_SCRIPTS_DIR)
$(1)-src-from ?= $$(VM_GENERIC_SRC_FROM)

endef
# use with $(call vm_new_layer_generic,vm-id)
vm_new_layer_generic = $(eval $(_vm_new_layer_generic_tpl))

