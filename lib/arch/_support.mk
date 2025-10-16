# Multi-arch support definitions
$(call mk_include_guard,vm_framework_arch)

ARCH ?=

ifeq ($(ARCH),aarch64)
ARCH_USE_EFI?=1
else
ARCH_USE_EFI?=
endif

# alternate architecture names
ARCH_ALT ?= $(firstword $(call _def_value,ARCH_ALTS_$(ARCH),$(ARCH)))
ARCH_ALTS ?= $(ARCH_ALTS_$(ARCH)) $(ARCH)
ARCH_ALTS_x86_64 ?= amd64 x64
ARCH_ALTS_aarch64 ?= arm64

# EFI firmware default paths
ARCH_EFI_DIR ?= $(firstword $(wildcard $(ARCH_ALTS:%=/usr/share/OVMF/%)))
ARCH_EFI_ALTS = OVMF.4m.fd QEMU_EFI.fd
ARCH_EFI_BIOS ?= $(firstword $(wildcard $(ARCH_EFI_ALTS:%=$(ARCH_EFI_DIR)/%)))

# packer vars to inject
ARCH_PACKER_ARGS ?= \
		$(call _packer_varfile,$(FRAMEWORK_DIR)/lib/arch/$(ARCH).pkrvars.hcl) \
		$(if $(ARCH_USE_EFI), \
			$(call _packer_var,qemu_bios,$(ARCH_EFI_BIOS)) \
		)

ifneq ($(DEBUG),)
$(info Using ARCH=$(ARCH) (alt: $(ARCH_ALT)))
ifneq ($(ARCH_USE_EFI),)
$(info EFI firmware: '$(ARCH_EFI_BIOS)')
else
$(info EFI disabled)
endif
endif
