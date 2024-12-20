# Makefile utility macros

# check variable if defined & not empty
check-var = $(if $(strip $($1)),,$(error "$1" is not defined))

# blank (i.e., empty string) variable
blank :=
# variable containing a single new line
define nl
$(blank)
$(blank)
endef

normalize_id=$(subst -,_,$1)

# recursive wildcard macro
# use: $(call rwildcard,$(path),*)
rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))

# macro to check if a variable is set, otherwise return a default
_def_value = $(if $($(1)),$($(1)),$(2))

# macro which sets a packer variable, if set
_packer_var = $(if $(2),-var "$(1)=$(2)")

