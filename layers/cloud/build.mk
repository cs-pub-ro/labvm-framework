## Cloud VM layer build macros
$(call mk_include_guard,vm_layer_cloud)

## Config variables: you can override them inside your Makefile):

# scripts relative to the current makefile
VM_CLOUD_SCRIPTS_DIR ?= $(abspath $(FRAMEWORK_DIR)/layers/cloud/scripts)/
# source (base) target to use
VM_CLOUD_SRC_FROM ?= main

define _vm_new_layer_cloud_tpl
$(call check-var,_vm_new_layer_generic_tpl)$(_vm_new_layer_generic_tpl)
$(1)-script-prepare = cloud-prepare.sh
$(1)-script-stage1 = install-cloud.d
$(1)-copy-scripts = $$(VM_CLOUD_SCRIPTS_DIR)
$(1)-src-from = $$(VM_CLOUD_SRC_FROM)
$(1)-extra-rules = $$(vm_cloud_test_rule)

endef

-vm-cloud-test-user-data = $(call _def_value,$(vm)-cloud-test-data,$(vm_cloud_test_def_data))
VM_CLOUD_LOCAL_QEMU_DISK = file=$(-vm-dest-dir)/cloud-localds.iso,media=cdrom,index=3

define vm_cloud_test_def_data
#cloud-config
chpasswd:
  expire: False
  users:
   - {name: "$(VM_USER)", password: "$(VM_PASSWORD)", type: text}
ssh_pwauth: True
ssh_authorized_keys:
  - "$(if $(VM_AUTHORIZED_KEYS),$(shell cat $(VM_AUTHORIZED_KEYS) | head -1))"

endef

define vm_cloud_test_rule
.PHONY: $(vm)_test
$(vm)_test: PAUSE=1
$(vm)_test: packer-args-extra=-var "use_backing_file=true"
$(vm)_test: packer-args-extra+=-var 'qemu_args=[["-snapshot"]]'
$(vm)_test: packer-args-extra+=-var 'qemu_extra_drive=$(VM_CLOUD_LOCAL_QEMU_DISK)'
$(vm)_test: $(-vm-dest-timestamp) $(-vm-dest-dir)/cloud-localds.iso
	$(let $(vm)-extra-envs,$($(vm)-extra-envs)"VM_CLOUD_TESTING=1"$(comma),
		$(let -vm-source-image,$(-vm-dest-image), \
			$(let -vm-name,$(-vm-name)_test,$(vm_packer_cmd))))
$(-vm-dest-dir)/cloud-localds.iso:
	echo "$$$$$(_VM_CLOUD_LOCALDATA_VAR)" > "$$(@D)/user-data"
	echo "instance-id: $$(shell uuidgen)" > $$(@D)/meta-data
	genisoimage -output "$$@" -volid cidata -joliet -rock \
		"$$(@D)/user-data" "$$(@D)/meta-data"
export $(_VM_CLOUD_LOCALDATA_VAR) := $$(-vm-cloud-test-user-data)

endef
_VM_CLOUD_LOCALDATA_VAR = $(call normalize_id,_VM_CLOUD_LOCALDATA__$(vm))

# use with $(call vm_new_layer_cloud,vm-id)
vm_new_layer_cloud = $(eval $(_vm_new_layer_cloud_tpl))

