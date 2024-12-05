# Makefile templates to generate combo VBox and VMware VM projects

include $(FRAMEWORK_DIR)/lib/gen_vbox.mk
include $(FRAMEWORK_DIR)/lib/gen_vmware.mk


# use vm-type = vm-combo to generate them
define vm_gen_vm-combo_rules=
.PHONY: $(vm) $(vm)_clean
#@ $(vm) Combo (VBox + VMX) project build goal
$(vm)-combo-dest-vmdk := $(-vm-dest-dir)/$(-vm-name)_disk.vmdk
$(vm)-vbox-dest-vmdk := $(-vm-dest-dir)/$(-vm-name)_disk.vmdk
$(vm)-vmware-dest-vmdk := $(-vm-dest-dir)/$(-vm-name)_disk.vmdk
$$($(vm)-combo-dest-vmdk): $(-vbox-src-vmdk)
	mkdir -p "$(-vm-dest-dir)"
	cp -f "$$<" "$$@"

$(vm_gen_vbox_prj_rule)
$(vm_gen_vmware_prj_rule)
$(vm): $$($(vm)-combo-dest-vmdk) $$($(vm)-vbox-prj) $$($(vm)-vmx-prj)

$(vm)_clean:
	rm -rf "$(-vm-dest-dir)"

endef

