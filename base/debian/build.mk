## Include file for building a Debian base VM
$(call mk_include_guard,vm_base_debian)

## Variables (override them inside your Makefile):
DEBIAN_VERSION ?= 13
# debian base packer source dir
BASE_DEBIAN_PKR_SRC ?= $(FRAMEWORK_DIR)/base/debian
# provision base framework scripts
BASE_DEBIAN_SCRIPTS_DIR ?= $(abspath $(FRAMEWORK_DIR)/scripts)/
# expand debian ISO
_DEBIAN_ISO_FULL ?= $(call _find_last_file,$(BASE_ISO_DIR)/$(DEBIAN_ISO_NAME))

define _vm_new_base_debian_tpl=
$(1)-ver ?= $$(DEBIAN_VERSION)
$(1)-prefix ?= debian_$$($(1)-ver)
$(1)-name ?= $$($(1)-prefix)_base
$(1)-packer-src = $$(BASE_DEBIAN_PKR_SRC)
$(1)-packer-args ?=
$(1)-packer-args += -var 'vm_scripts_dir=' \
	-var 'vm_scripts_list=$$(-vm-copy-scripts-list)' \
	$$(call _packer_var,vm_hostname,$$(VM_HOSTNAME)) \
	$$(call _packer_var,vm_locale,$$(VM_LOCALE)) \
	$$(call _packer_var,vm_timezone,$$(VM_TIMEZONE)) \
	$$(call _packer_var,vm_debian_ver,$$($(1)-ver))
$(1)-copy-scripts ?= $$(BASE_DEBIAN_SCRIPTS_DIR)
$(1)-src-image ?= $$(let ver,$$($(1)-ver),$$(_DEBIAN_ISO_FULL))

endef
# use with $(call vm_new_base_debian,base)
vm_new_base_debian = $(eval $(_vm_new_base_debian_tpl))

