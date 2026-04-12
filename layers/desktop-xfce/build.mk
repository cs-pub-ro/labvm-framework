## XFCE Desktop Environment VM layer build scripts
$(call mk_include_guard,vm_layer_desktop_xfce)

## Config variables: you can override them inside your Makefile):

# scripts relative to the current makefile
VM_DESKTOP_XFCE_SCRIPTS_DIR ?= $(abspath $(FRAMEWORK_DIR)/layers/desktop-xfce/scripts)/
# source (base) target to use
VM_DESKTOP_XFCE_SRC_FROM ?= base

define _vm_new_layer_desktop_xfce_tpl
$(call check-var,_vm_new_layer_generic_tpl)$(_vm_new_layer_generic_tpl)
# $(1)-script-prepare = desktop-prepare.sh
$(1)-script-stage1 = install-stage1.d
$(1)-script-stage2 = install-stage2.d
$(1)-copy-scripts = $$(VM_DESKTOP_XFCE_SCRIPTS_DIR)
$(1)-src-from = $$(VM_DESKTOP_XFCE_SRC_FROM)
$(1)-packer-args += \
	$$(call _packer_var,qemu_vga,virtio)

endef
# use with $(call vm_new_layer_desktop_xfce,vm-id)
vm_new_layer_desktop_xfce = $(eval $(_vm_new_layer_desktop_xfce_tpl))

