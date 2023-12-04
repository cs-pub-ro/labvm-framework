# Makefile framework for Packer VM builds

# prerequisites
include $(FRAMEWORK_DIR)/utils.mk

# load configuration file
include $(FRAMEWORK_DIR)/config.default.mk

# speed tweaks
MAKEFLAGS += --no-builtin-rules
.SUFFIXES:

## <vm>-specific (placeholder for VM's ID + goal) variables and their defaults
# <vm>-name: name of the VM (also used to generate VM's destination directory + images file)
-vm-name = $(call _def_value,$(vm)-name,$(vm))
# <vm>-src: source (root) directory of the Packer project (should contain .pkr.hcl file)
-vm-packer-src = $(call _def_value,$(vm)-packer-src,$(vm))
# <vm>-packer-def-args: default packer invocation arguments (before all other)
-vm-packer-def-args = $(call _def_value,$(vm)-packer-def-args,)
# <vm>-packer-args: extra packer invocation arguments
-vm-packer-extra-args = $(call _def_value,$(vm)-packer-args,)
# <vm>-src-from: take source image from another makefile VM (goal name)
-vm-source-from = $($(vm)-src-from)
# <vm>-src-image: take source image from another file (when ! <vm>-source-from)
-vm-source-image = $(strip $(if $(-vm-source-from),$(let vm,$(-vm-source-from),$(-vm-dest-image)),\
			$(call _def_value,$(vm)-src-image,$$(BASE_VM_INSTALL_ISO))))
# <vm>-src-deps: override the VM target dependencies (defaults to "<vm>-src/**")
-vm-source-deps = $(call _def_value,$(vm)-src-deps,$(call rwildcard,$(-vm-packer-src),*))
# <vm>-dest-file: override the destination image filename (+ extension!)
-vm-dest-file = $(call _def_value,$(vm)-dest-file,$(-vm-name).qcow2)
# <vm>-dest-dir: override the destination directory (defaults to <vm>-name)
-vm-dest-dir = $(call _def_value,$(vm)-dest-dir,$$(BUILD_DIR)/$(-vm-name))
# <vm>-deps: add extra dependencies to the VM's targets
-vm-extra-deps = $(call _def_value,$(vm)-deps,)
# <vm>-extra-rules: generates extra rules for the current VM target
#    -> use `define` to create multi-line rules;
#    -> you can use $(vm) inside (or every other macro containing $(vm))!
-vm-extra-rules = $($(vm)-extra-rules)

# internal macros:
-vm-dest-image = $(-vm-dest-dir)/$(-vm-dest-file)
-vm-dest-timestamp = $(-vm-dest-dir)/.exists
-vm-image-deps = $(strip $(if $(-vm-source-from),$(let vm,$(-vm-source-from),$(-vm-dest-timestamp)),\
			$(-vm-source-image)))
-vm-rule-deps = $(-vm-source-deps) $(-vm-extra-deps) $(-vm-image-deps) | $$(BUILD_DIR)/
-vm-packer-args = $$(PACKER_ARGS) $(-vm-packer-def-args) \
			 -var "vm_name=$(-vm-dest-file)" \
			 -var "source_image=$(-vm-source-image)" \
			 -var "output_directory=$(-vm-dest-dir)" \
			 $(-vm-packer-extra-args) $$(packer-args-extra)

# Packer build command with VM-specific vars
define vm_packer_cmd
$(if $(FORCE),rm -rf "$(-vm-dest-dir)";,) \
cd "$(-vm-packer-src)" && $(PACKER) build $(-vm-packer-args) "./"
endef

# Macro to generate VM-specific rules
define vm_gen_rules
# VM build rules for $(vm)
$(vm)-dest-image := $(-vm-dest-image)
.PHONY: $(vm) $(vm)_clean $(vm)_edit $(vm)_commit
#@ $(vm) main build goal
$(vm): $(-vm-dest-image)
$(-vm-dest-image): $(-vm-rule-deps)
	$(vm_packer_cmd)
	touch "$(-vm-dest-timestamp)"
#@ $(vm) secondary target (ignores force rebuild, for use as dependency)
$(-vm-dest-timestamp):
	$$(MAKE) FORCE= "$(-vm-dest-image)"
#@ $(vm) clean rule
$(vm)_clean:
	rm -rf "$(-vm-dest-dir)/" "$$($(vm)-edit-dir)"
#@ $(vm) vmdk conversion rule
$(vm)-vmdk-file := $(-vm-dest-dir)/$(-vm-dest-file:.qcow2=.vmdk)
$(vm)_vmdk: $(-vm-dest-image)
	qemu-img convert -O vmdk "$(-vm-dest-image)" "$$($(vm)-vmdk-file)"
	ls -lh "$$($(vm)-vmdk-file)"

#@ $(vm) edit rule: uses $(vm) as backing file for rapid VM testing / editing
$(vm)_edit: PAUSE=1
$(vm)_edit: packer-args-extra=-var "use_backing_file=true"
$(vm)_edit: $(-vm-dest-timestamp)
	$(let -vm-source-image,$(-vm-dest-image), \
		$(let -vm-name,$(-vm-name)_edit,$(vm_packer_cmd)))
$(vm)-edit-dir := $(let -vm-name,$(-vm-name)_edit,$(-vm-dest-dir))
$(vm)-edit-file := $(let -vm-name,$(-vm-name)_edit,$(-vm-dest-file))
#@ commits $(vm)_edit changes back to its backing image
$(vm)_commit:
	qemu-img commit "$$($(vm)-edit-dir)/$$($(vm)-edit-file)"
# extra rules? ::
$(-vm-extra-rules)

endef
gen_all_vm_rules = $(foreach vm,$(build-vms),$(nl)$(vm_gen_rules))
eval_all_vm_rules = $(foreach vm,$(build-vms),$(eval $(nl)$(vm_gen_rules)))

define gen_common_rules
.PHONY: _ init ssh
_: $(DEFAULT_GOAL)
init:
	$(foreach vm,$(INIT_GOAL),packer init "$(-vm-packer-src)";)

# ssh into a Packer/qemu VM
ssh:
	$$(SSH) $$(SSH_ARGS) $$(SSH_USER)@127.0.0.1 -p $$(SSH_PORT)
# creates the build directory
$$(BUILD_DIR)/:
	mkdir -p "$$@"

endef
# debugging helper rules
define gen_debug_rules
# debug helpers
.PHONY: @debug @debug-make @debug-rules
@debug: @debug-rules
@debug-rules:
	$$(info $$(gen_all_vm_rules))
	@echo
@debug-make: @debug-rules
	@$(MAKE) -r -p
@print-% : ; @echo $$* = $$($$*)

endef
eval_debug_rules = $(eval $(gen_debug_rules)$(nl))
eval_common_rules = $(eval $(gen_common_rules))$(call eval_debug_rules)

