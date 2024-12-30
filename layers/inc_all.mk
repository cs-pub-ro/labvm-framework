## Includes all VM framework layers

# enumeration of all layers (unless overridden)
VM_ALL_LAYERS ?= generic cloud full-featured

# include them:
_INC_VM_ALL_LAYERS = $(VM_ALL_LAYERS:%=$(FRAMEWORK_DIR)/layers/%/build.mk)
include $(_INC_VM_ALL_LAYERS)

