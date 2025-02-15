## Generic VM layer build macros
$(call mk_include_guard,vm_layer_generic)

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

# macros to check whether script/dir exists and supply provisioning defaults
-vm-generic-prepare = $(strip $(call _def_value,$(vm)-script-prepare,\
		$(notdir $(call _find_file_in_path,vm-prepare.sh,$(-vm-copy-scripts)))))
-vm-generic-stage1 = $(strip $(call _def_value,$(vm)-script-stage1,\
		$(notdir $(call _find_file_in_path,install-stage1.d,$(-vm-copy-scripts)))))
-vm-generic-stage2 = $(strip $(call _def_value,$(vm)-script-stage2,\
		$(notdir $(call _find_file_in_path,install-stage2.d,$(-vm-copy-scripts)))))

-vm-generic-pre-copy-cmd = $(call _def_value,$(vm)-pre-copy-cmd,)
-vm-generic-extra-envs = $(call _def_value,$(vm)-extra-envs,)
-vm-generic-extra-envs-var = [$(subst $(comma)$(comma),,$(strip $(-vm-generic-extra-envs)))]


define _vm_new_layer_generic_tpl=
$(1)-name ?= $(1)
$(1)-packer-src = $$(VM_GENERIC_PKR_SRC)
$(1)-packer-args ?=
$(1)-packer-args += -var 'vm_scripts_dir=' \
	-var 'vm_scripts_list=$$(-vm-copy-scripts-list)' \
	-var 'vm_pre_copy_cmd=$$(-vm-generic-pre-copy-cmd)' \
	-var 'vm_prepare_script=$$(-vm-generic-prepare)' \
	-var 'vm_install_stage1=$$(-vm-generic-stage1)' \
	-var 'vm_install_stage2=$$(-vm-generic-stage2)' \
	-var 'vm_authorized_keys=$$(VM_AUTHORIZED_KEYS)' \
	-var 'vm_extra_envs=$$(-vm-generic-extra-envs-var)'
$(1)-copy-scripts ?= $$(VM_GENERIC_SCRIPTS_DIR)
$(1)-src-from ?= $$(VM_GENERIC_SRC_FROM)
$(1)-extra-envs ?=

endef
# use with $(call vm_new_layer_generic,vm-id)
vm_new_layer_generic = $(eval $(_vm_new_layer_generic_tpl))

