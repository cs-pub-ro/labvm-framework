## Include file for building a Ubuntu base VM

## Variables (override them inside your Makefile):
UBUNTU_VERSION ?= 22
UBUNTU_22_ISO ?= $(call _def_value,BASE_VM_INSTALL_ISO,\
				 $(HOME)/Downloads/ubuntu-22.04.5-live-server-amd64.iso)
# ubuntu base packer source dir
BASE_UBUNTU_PKR_SRC ?= $(FRAMEWORK_DIR)/base/ubuntu
# provision base framework scripts
BASE_UBUNTU_SCRIPTS_DIR ?= $(abspath $(FRAMEWORK_DIR)/scripts)/

# use with $(eval $(call vm_new_base_ubuntu,base))
define vm_new_base_ubuntu=
$(1)-ver ?= $$(UBUNTU_VERSION)
$(1)-name ?= ubuntu_$$($(1)-ver)_base
$(1)-packer-src = $$(BASE_UBUNTU_PKR_SRC)
$(1)-packer-args ?=
$(1)-packer-args += -var "vm_scripts_dir=" -var 'vm_scripts_list=$$(call \
	_packer_json_list,$$($(1)-copy-scripts))'
$(1)-packer-args ?= -var "vm_ubuntu_ver=$$($(1)-ver)"
$(1)-copy-scripts ?= $(BASE_UBUNTU_SCRIPTS_DIR)
$(1)-src-image ?= $$(UBUNTU_$$($(1)-ver)_ISO)

endef

