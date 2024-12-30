## Include file for building a Ubuntu base VM
$(call mk_include_guard,vm_base_ubuntu)

## Variables (override them inside your Makefile):
UBUNTU_VERSION ?= 22
UBUNTU_22_ISO ?= $(call _def_value,BASE_VM_INSTALL_ISO,\
				 $(HOME)/Downloads/ubuntu-22.04.5-live-server-amd64.iso)
# ubuntu base packer source dir
BASE_UBUNTU_PKR_SRC ?= $(FRAMEWORK_DIR)/base/ubuntu
# provision base framework scripts
BASE_UBUNTU_SCRIPTS_DIR ?= $(abspath $(FRAMEWORK_DIR)/scripts)/

-vm-copy-scripts = $(call _def_value,$(vm)-copy-scripts,)
-vm-copy-scripts-list = $(call _packer_json_list,$(-vm-copy-scripts))

define _vm_new_base_ubuntu_tpl=
$(1)-ver ?= $$(UBUNTU_VERSION)
$(1)-name ?= ubuntu_$$($(1)-ver)_base
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
$(1)-src-image ?= $$(UBUNTU_$$($(1)-ver)_ISO)

endef
# use with $(call vm_new_base_ubuntu,base)
vm_new_base_ubuntu = $(eval $(_vm_new_base_ubuntu_tpl))

