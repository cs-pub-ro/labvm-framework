## Includes all VM framework bases, layers & other utility libraries.

# load arch support definitions
include $(FRAMEWORK_DIR)/lib/arch.mk

include $(FRAMEWORK_DIR)/base/inc_all.mk
include $(FRAMEWORK_DIR)/layers/inc_all.mk

include $(FRAMEWORK_DIR)/lib/gen_vm_combo.mk
include $(FRAMEWORK_DIR)/lib/zerofree.mk

