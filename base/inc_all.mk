## Includes all VM framework bases

# enumeration of all layers (unless overridden)
VM_ALL_BASES ?= ubuntu

# include them:
_INC_VM_ALL_BASES = $(VM_ALL_BASES:%=$(FRAMEWORK_DIR)/base/%/build.mk)
include $(_INC_VM_ALL_BASES)

