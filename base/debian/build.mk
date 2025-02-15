## Include file for building a Debian base VM
$(call mk_include_guard,vm_base_debian)

## Variables (override them inside your Makefile):
DEBIAN_VERSION ?= 12
DEBIAN_12_ISO ?= $(call _def_value,BASE_VM_INSTALL_ISO,\
				 $(HOME)/Downloads/debian-12.9.0-amd64-netinst.iso)
# debian base packer source dir
BASE_DEBIAN_PKR_SRC ?= $(FRAMEWORK_DIR)/base/debian
# provision base framework scripts
BASE_DEBIAN_SCRIPTS_DIR ?= $(abspath $(FRAMEWORK_DIR)/scripts)/

define _vm_new_base_debian_tpl=
$(1)-ver ?= $$(DEBIAN_VERSION)
$(1)-name ?= debian_$$($(1)-ver)_base
$(1)-packer-src = $$(BASE_DEBIAN_PKR_SRC)
$(1)-packer-args ?=
$(1)-packer-args += -var 'vm_scripts_dir=' \
	-var 'vm_scripts_list=$$(-vm-copy-scripts-list)' \
	$$(call _packer_var,vm_hostname,$$(VM_HOSTNAME)) \
	$$(call _packer_var,vm_locale,$$(VM_LOCALE)) \
	$$(call _packer_var,vm_timezone,$$(VM_TIMEZONE)) \
	$$(call _packer_var,vm_debian_ver,$$($(1)-ver))
$(1)-copy-scripts ?= $$(BASE_DEBIAN_SCRIPTS_DIR)
$(1)-src-image ?= $$(DEBIAN_$$($(1)-ver)_ISO)

endef
# use with $(call vm_new_base_debian,base)
vm_new_base_debian = $(eval $(_vm_new_base_debian_tpl))

