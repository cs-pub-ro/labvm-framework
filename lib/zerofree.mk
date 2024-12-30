## Utility make macro to add <vm>_compact/zerofree rule to VM targets
# Requires qemu-nbd to be installed (check out utils/zerofree.sh)
$(call mk_include_guard,vm_lib_zerofree)

SUDO ?= sudo
# Configurable device wait time, in seconds; increase on slow systems if NBD 
# device doesn't get mounted in time
ZEROFREE_DEV_WAIT ?= 5
export ZEROFREE_DEV_WAIT

# Usage: YOUR_VM-extra-rules += $(_vm_compact_rule)
define vm_zerofree_rule
.PHONY: $(vm)_compact $(vm)_zerofree
$(vm)_zerofree: $(vm)_compact
$(vm)_compact:
	$(SUDO) "$(FRAMEWORK_DIR)/utils/zerofree.sh" "$$($(vm)-dest-image)"

endef

