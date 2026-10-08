## Include file for building a Arch Linux base VM
$(call mk_include_guard,vm_base_arch)

## Variables (override them inside your Makefile):
# arch linux base packer source dir
BASE_ARCH_PKR_SRC ?= $(FRAMEWORK_DIR)/base/arch
# provision base framework scripts
BASE_ARCH_SCRIPTS_DIR ?= $(abspath $(FRAMEWORK_DIR)/scripts)/
# expand arch ISO (rolling release: no version)
_ARCH_ISO_FULL ?= $(call _find_last_file,$(BASE_ISO_DIR)/$(ARCH_ISO_NAME))

define _vm_new_base_arch_tpl=
$(1)-prefix ?= arch$$(ARCH_SUFFIX)
$(1)-name ?= $$($(1)-prefix)_base
$(1)-packer-src = $$(BASE_ARCH_PKR_SRC)
$(1)-packer-args ?=
$(1)-packer-args += -var 'vm_scripts_dir=' \
	-var 'vm_scripts_list=$$(-vm-copy-scripts-list)' \
	$$(call _packer_var,vm_hostname,$$(VM_HOSTNAME)) \
	$$(call _packer_var,vm_locale,$$(VM_LOCALE)) \
	$$(call _packer_var,vm_timezone,$$(VM_TIMEZONE)) \
	$$(call _packer_var,vm_crypted_password,$$$$(VM_CRYPTED_PASSWORD))
$(1)-copy-scripts ?= $$(BASE_ARCH_SCRIPTS_DIR)
$(1)-src-image ?= $$(_ARCH_ISO_FULL)

endef
# use with $(call vm_new_base_arch,base)
vm_new_base_arch = $(eval $(_vm_new_base_arch_tpl))
