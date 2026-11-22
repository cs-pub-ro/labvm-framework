---
name: new-vm-base
description: Add a new Linux distribution base image to labvm-framework — base/<distro>/ (build.mk, <distro>.pkr.hcl, symlinks to the shared base/common*.pkr.hcl, unattended-installer payload), scripts/base-<distro>.d/, registration in VM_ALL_BASES and config.default.mk ISO vars. Use when asked to add a distro base, port an image build to a new installer (preseed/autoinstall/shell), or bootstrap an unattended install for a new distro or architecture.
---

# New VM base image

Goal: `make init && make base` produces `$(BUILD_DIR)/<distro>_<ver>_base/…qcow2`
from an official install ISO, unattended, ready to be a layer's `-src-from`.

Read `.agents/AGENTS.md` §"Provisioning pipeline" — base images use the same
shared `prepare-multistage.sh` as layers, but **one** stage over `1-99` and the
legacy single-dir variable.

## 0. Pick the closest existing base

| Installer style | Template | Payload |
|---|---|---|
| debian-installer + preseed | `base/debian/` | `preseed/debian_<NN>.pkrtpl` + `preseed/snippets/*.conf` |
| subiquity + cloud-init autoinstall | `base/ubuntu/` | `preseed/cloud-config.yaml.pkrtpl` |
| custom shell installer over Packer's HTTP server | `base/arch/` | `arch-install.sh` + `bootstrap.sh.pkrtpl` |

Copy that directory and edit; do not start from scratch.

## 1. Files

```
base/<distro>/
├── build.mk                      # vm_new_base_<distro> macro
├── Readme.md                     # what it installs, ISO requirements
├── <distro>.pkr.hcl              # variables + source "qemu" "base"
├── common.pkr.hcl       -> ../common.pkr.hcl        # SYMLINK
├── common_arch.pkr.hcl  -> ../common_arch.pkr.hcl   # SYMLINK
└── preseed/ (or installer payload)
```

`base/common.pkr.hcl` (provisioning pipeline + shared vars) and
`base/common_arch.pkr.hcl` (`qemu_arch_defs`, console args) are shared by all
bases and pulled in through **relative symlinks**. Create them with
`ln -s ../common.pkr.hcl common.pkr.hcl` — do not copy, or they drift. A
`find -type f` will not show them; that is normal.

## 2. build.mk

Mirror `base/debian/build.mk` (or `base/arch/build.mk` when the distro has no
version):

```make
## Include file for building a <Distro> base VM
$(call mk_include_guard,vm_base_<distro>)

<DISTRO>_VERSION ?= 1
BASE_<DISTRO>_PKR_SRC ?= $(FRAMEWORK_DIR)/base/<distro>
BASE_<DISTRO>_SCRIPTS_DIR ?= $(abspath $(FRAMEWORK_DIR)/scripts)/

# expand the ISO (latest match wins)
_<DISTRO>_ISO_FULL ?= $(call _find_last_file,$(BASE_ISO_DIR)/$(<DISTRO>_ISO_NAME))

define _vm_new_base_<distro>_tpl=
$(1)-ver ?= $$(<DISTRO>_VERSION)
$(1)-prefix ?= <distro>_$$($(1)-ver)$$(ARCH_SUFFIX)
$(1)-name ?= $$($(1)-prefix)_base
$(1)-packer-src = $$(BASE_<DISTRO>_PKR_SRC)
$(1)-packer-args ?=
$(1)-packer-args += -var 'vm_scripts_dir=' \
	-var 'vm_scripts_list=$$(-vm-copy-scripts-list)' \
	$$(call _packer_var,vm_hostname,$$(VM_HOSTNAME)) \
	$$(call _packer_var,vm_locale,$$(VM_LOCALE)) \
	$$(call _packer_var,vm_timezone,$$(VM_TIMEZONE)) \
	$$(call _packer_var,vm_<distro>_ver,$$($(1)-ver))
$(1)-copy-scripts ?= $$(BASE_<DISTRO>_SCRIPTS_DIR)
$(1)-src-image ?= $$(let ver,$$($(1)-ver),$$(_<DISTRO>_ISO_FULL))

endef
# use with $(call vm_new_base_<distro>,base)
vm_new_base_<distro> = $(eval $(_vm_new_base_<distro>_tpl))
```

Escaping rules that bite:
- `$$(…)` = evaluated when the macro expands; `$$$$(…)` = evaluated by the
  *caller's* makefile (needed for `VM_CRYPTED_PASSWORD`, which is a `$(shell …)`).
  Arch passes it: `$$(call _packer_var,vm_crypted_password,$$$$(VM_CRYPTED_PASSWORD))`.
- `$(let ver,…)` binds `$(ver)` used by `*_ISO_NAME`; keep `src-image` lazy
  (`?=`).
- `-var 'vm_scripts_dir='` must be **empty** — that switches the packer file
  provisioner to `vm_scripts_list`.
- `-copy-scripts` points at the framework `scripts/` dir, so
  `scripts/base-<distro>.d/` rides along with `lib/` and `common-snippets.d/`.
- `<distro>.pkr.hcl` must not redefine what build.mk already passes.

## 3. config.default.mk + base/inc_all.mk

```make
<DISTRO>_VERSION ?= 1
<DISTRO>_ISO_NAME ?= <distro>-$(ver).*-$(ARCH_ALT).iso
```

`$(ver)` is bound by `let`; use `$(ARCH_ALT)` (→ `amd64`/`arm64`), not
`$(ARCH)`. Then `VM_ALL_BASES ?= ubuntu debian arch <distro>` in
`base/inc_all.mk`.

## 4. \<distro\>.pkr.hcl

The `variables` block must declare at least:

```hcl
vm_hostname       = "<distro>"
vm_prepare_script = "prepare-multistage.sh"
vm_prepare_dir    = "base-<distro>.d"   # legacy single dir (see below)
vm_prepare_range  = "1-99"
vm_send_boot_keys = true
source_image      = "https://…"
source_checksum   = "none"
```

`base/common.pkr.hcl` declares `vm_prepare_dirs = ""` and resolves
`local.prepare_dirs = var.vm_prepare_dirs != "" ? var.vm_prepare_dirs : var.vm_prepare_dir`,
so bases use the **singular legacy** variable. Set `vm_prepare_dirs` only if you
genuinely need several dirs.

The `source "qemu" "base"` block is boilerplate — copy it and keep
`local.qemu_arch_*`, `ssh_*`, `host_port_min/max`, `disk_*`,
`shutdown_command`, `boot_wait` / `boot_key_interval` / `boot_command_wait`
exactly as in a sibling base. Only these are distro-specific:

- `http_content` — what Packer's HTTP server serves (`templatefile()` of your
  preseed/cloud-config/bootstrap, or `file()` for a shell script).
- `boot_command` — keystrokes (sent over VNC) booting the ISO with kernel args
  pointing at `http://{{ .HTTPIP }}:{{ .HTTPPort }}/<payload>`. Put
  arch-dependent keys in a `<distro>_arch_defs` map looked up by `var.arch`, as
  `deb_arch_install.pkr.hcl` does.
- `boot_command` is `null` when `use_backing_file` (the `_edit` goal unless
  `vm_send_boot_keys`); don't "fix" that.
- `ssh_timeout` — bump for slow arches (Ubuntu uses `60m`).

## 5. scripts/base-<distro>.d/

Single stage, `expect_disconnect=true` throughout (a reboot mid-snippets is
fine), `NN-name.sh`, same contract as any snippet:

```
scripts/base-<distro>.d/
├── 01-init.sh              @import '<distro>/packages.sh'; pkg_init_update
├── 10-base-packages.sh     pkg_install …
├── 15-base-tweaks.sh
├── 19-boot-kernel.sh       vm_run_script "common-snippets.d/kernel-cmdline"
└── 90-cleanup.sh           pkg_cleanup || true; df -h
```

Nothing else to wire — the dir is uploaded as part of the framework `scripts/`
and selected by `vm_prepare_dir` in `<distro>.pkr.hcl`.

If the package manager differs, add `scripts/lib/<distro>/packages.sh`
implementing `pkg_init_update`, `pkg_install`, `pkg_remove`, `pkg_upgrade_all`,
`pkg_cleanup` (see `scripts/lib/arch/packages.sh` for a non-APT one).

## 6. Test

```sh
make init
make @print-base-src-image     # must print an existing .iso path
make base_clean base           # slow: full unattended install
make base DEBUG_CONSOLE=1      # watch VNC/serial (docs/Debugging.md)
make base_edit                 # snapshot of the finished base, PAUSE=1
make ssh                       # 2nd terminal, port 20022
```

## Gotchas

- `@print-base-src-image` is the best first check: `_find_last_file` is
  `lastword $(sort $(wildcard …))`, so `*_ISO_NAME` must glob the real filename
  (version + `$(ARCH_ALT)`). Empty → packer gets `source_image=` and qemu dies
  immediately.
- `make base DEBUG=1` prints the resolved arch, accelerator and EFI firmware
  (from `lib/arch.mk`).
- Ubuntu deliberately reuses `base-debian.d` (`vm_prepare_dir = "base-debian.d"`)
  because the post-install set is shared; only its installer payload differs.
  Only add `base-<distro>.d/` when the package set actually diverges.
- Base images are the seed for `/opt/vm-scripts/`: every derived layer inherits
  `lib/` from the built base, so a base built on a stale framework checkout
  produces layers running stale helper modules.
- Aarch64 needs `ARCH_USE_EFI=1` (auto-set), OVMF/`QEMU_EFI.fd` under
  `/usr/share/OVMF/`, and an `aarch64` branch in the installer locals.
- Don't commit the ISO; `BASE_ISO_DIR` defaults to `~/Downloads/iso`
  (`/tmp/packer/iso` in the devcontainer).
