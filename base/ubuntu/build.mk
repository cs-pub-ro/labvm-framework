## Include file for building a Ubuntu base VM
$(call mk_include_guard,vm_base_ubuntu)

## Variables (override them inside your Makefile):
UBUNTU_VERSION ?= 24
# ubuntu base packer source dir
BASE_UBUNTU_PKR_SRC ?= $(FRAMEWORK_DIR)/base/ubuntu
# provision base framework scripts
BASE_UBUNTU_SCRIPTS_DIR ?= $(abspath $(FRAMEWORK_DIR)/scripts)/
# expand ubuntu ISO
_UBUNTU_ISO_FULL ?= $(call _find_last_file,$(BASE_ISO_DIR)/$(UBUNTU_ISO_NAME))

define _vm_new_base_ubuntu_tpl=
$(1)-ver ?= $$(UBUNTU_VERSION)
$(1)-prefix ?= ubuntu_$$($(1)-ver)$$(ARCH_SUFFIX)
$(1)-name ?= $$($(1)-prefix)_base
$(1)-packer-src = $$(BASE_UBUNTU_PKR_SRC)
$(1)-packer-args ?=
$(1)-packer-args += -var 'vm_scripts_dir=' \
	-var 'vm_scripts_list=$$(-vm-copy-scripts-list)' \
	$$(call _packer_var,vm_hostname,$$(VM_HOSTNAME)) \
	$$(call _packer_var,vm_locale,$$(VM_LOCALE)) \
	$$(call _packer_var,vm_timezone,$$(VM_TIMEZONE)) \
	$$(call _packer_var,vm_crypted_password,$$$$(VM_CRYPTED_PASSWORD)) \
	$$(call _packer_var,vm_ubuntu_ver,$$($(1)-ver))
$(1)-copy-scripts ?= $$(BASE_UBUNTU_SCRIPTS_DIR)
$(1)-src-image ?= $$(let ver,$$($(1)-ver),$$(_UBUNTU_ISO_FULL))

endef
# use with $(call vm_new_base_ubuntu,base)
vm_new_base_ubuntu = $(eval $(_vm_new_base_ubuntu_tpl))

