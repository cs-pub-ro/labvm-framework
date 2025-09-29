## Makefile utility macros

# check variable if defined & not empty
check-var = $(if $(strip $($1)),,$(error "$1" is not defined))

# Makefile include guard, shows an error if multiple inclusions were detected
# use with $(call mk_include_guard,UNIQUE_FILE_ID)
mk_include_guard = $(strip \
		$(if $(strip $(__mk_guard_$(1))),$(error "$1" was already included)) \
		$(eval __mk_guard_$(1) := 1))

# blank (i.e., empty string) variable
blank :=
# variable containing a single new line
define nl
$(blank)
$(blank)
endef
comma := ,
dollar := $$

normalize_id=$(subst -,_,$1)

# recursive wildcard macro
# use: $(call rwildcard,$(path),*)
rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))

# macro to check if a variable is set, otherwise return a default
_def_value = $(if $($(1)),$($(1)),$(2))

# macro which sets a packer variable, if set
_packer_var = $(if $(2),-var '$(1)=$(2)')

# macro for generating a JSON list of strings
_packer_json_list_tmp = $(if $(1),$(foreach val,$(1),"$(val)",)$(comma))
_packer_json_list = [$(subst $(comma)$(comma),,$(_packer_json_list_tmp))]

# macro for checking whether a base file $(1) exists in a path $(2)
# returns the full path to the file if found, empty otherwise
_find_file_in_path = $(firstword $(wildcard $(2:%=%/$(1))))

# macro for finding a file matching the pattern (latest in sorting order)
_find_last_file = $(lastword $(sort $(wildcard $(1))))

