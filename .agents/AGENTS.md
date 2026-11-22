# Agent instructions — labvm-framework (packer/qemu VM layers)

Repository that generates Linux VM images (Ubuntu/Debian/Arch bases + derived
layers) using **Makefiles + Packer + qemu**. Development task = adding/modifying
bases, layers, or their bash provisioning snippets.

This file is exposed at the repo / submodule's root as `AGENTS.md` (symlink to
`.agents/AGENTS.md`) so pi loads it as a context file. Edit this one, not the
symlink. Skills live in `.agents/skills/`.

## Dev environment

`.devcontainer/` (Debian trixie: packer + qemu-system, host KVM via
`--device /dev/kvm`). Container env: `BUILD_DIR=/tmp/packer/cache` (host
`~/.cache/packer`), `BASE_ISO_DIR=/tmp/packer/iso` (host `~/Downloads/iso`),
both bind-mounted. No `/dev/kvm` (e.g. Mac) → set
`PACKER_ARGS_EXTRA ?= -var qemu_accelerator=tcg` in `config.local.mk`.
See `.devcontainer/README.md` and `docs/Debugging.md`.

The agent (you) will most likely run inside an ephemeral container derived from
this devcontainer's Dockerfile + environment.

## Repo map

```
Makefile              top-level framework VM builds (base + cloud)
framework.mk          the Makefile VM framework (rule generators) — read-only knowledge
config.default.mk     defaults: ARCH, VM_USER/PASSWORD, BUILD_DIR, BASE_ISO_DIR,
                      *_VERSION, *_ISO_NAME, PACKER_ARGS, SSH_* (port 20022)
config.local.mk       local overrides (untracked, don't commit credentials)
lib/                  make helpers
  utils.mk            check-var, mk_include_guard, _def_value, _packer_var,
                      _packer_json_list, _find_file_in_path, _find_last_file, rwildcard
  arch.mk             ARCH / ARCH_SUFFIX / ARCH_ALT + EFI firmware detection
  qemu_debug.mk       HEADLESS, QEMU_MONITOR, QEMU_SERIAL, DEBUG_CONSOLE
  gen_vbox.mk gen_vmware.mk gen_vm_combo.mk   export rules (for `<vm>-type = vm-combo`)
  zerofree.mk         vm_zerofree_rule macro → <vm>_compact / <vm>_zerofree
  inc_all.mk          includes arch + all bases + all layers + combo + zerofree
base/                 base (ISO install) images
  common.pkr.hcl      shared: vars + the single-stage provisioning pipeline
  common_arch.pkr.hcl shared: qemu_arch_defs (bins/firmware/accel), console args
  inc_all.mk          VM_ALL_BASES
  ubuntu/ debian/ arch/
                      each: build.mk, <distro>.pkr.hcl, installer payload
                      (preseed/ or arch-install.sh + bootstrap.sh.pkrtpl), and
                      common.pkr.hcl / common_arch.pkr.hcl **symlinks to ../**
layers/
  generic/            Packer source (build.pkr.hcl) + build.mk used by ALL derived
                      VMs; no scripts of its own — the template everything extends
  cloud/              cloud-init layer (prepare-cloud.d, adds <vm>_test rule)
  full-featured/      many dev packages (prepare-full.d)
  desktop-xfce/       XFCE DE (prepare-desktop-xfce.d)
scripts/              bash provisioning framework, rsynced into /opt/vm-scripts
  install.sh          entrypoint: sources lib/base.sh, `@import vmrunner`, vm_run_scripts "$@"
  prepare-multistage.sh   shared stage runner (range + dirs selection) — see below
  lib/base.sh         sh_log_*, @import module system (sh-lib, vendored from GitHub)
  lib/vmrunner.sh     vm_run_scripts DIR / vm_run_script FILE (+ --optional)
  lib/linux.sh lib/systemd.sh lib/arch/packages.sh lib/debian/packages.sh
  lib/Makefile        `make dev-upgrade` re-fetches the sh-lib modules
  base-debian.d/      base snippets for the Debian AND Ubuntu bases
  base-arch.d/        base snippets for the Arch base
  common-snippets.d/  optional snippets, invoked explicitly by path (reboot.sh,
                      kernel-cmdline.sh, ssh-authorized-keys.sh)
docs/Debugging.md     console/VNC/serial/monitor debugging recipes
utils/zerofree.sh     image compaction helper used by lib/zerofree.mk
example/              working template project (see its Makefile)
```

## How the build system works (core mental model)

1. A Makefile includes `framework.mk` + `lib/inc_all.mk` (which pulls in
   `base/inc_all.mk` and `layers/inc_all.mk`, i.e. all `vm_new_*` macros).
2. Each VM is one macro call: `$(call vm_new_base_<distro>,base)` or
   `$(call vm_new_layer_<name>,<vm>)`. This `eval`s a template that sets
   `<vm>-*` variables, which the Makefile then overrides:
   - `<vm>-name`           image name (dest dir + file)
   - `<vm>-src-from`       source VM goal (build dependency)
   - `<vm>-src-image`      (bases) the ISO path
   - `<vm>-copy-scripts`   **list** of dirs rsynced into `/opt/vm-scripts/`
   - `<vm>-script-prepare` prepare script (default `prepare-multistage.sh`)
   - `<vm>-script-dirs`    colon-separated snippet dirs (**replaces** the default)
   - `<vm>-script-range1/2` NN ranges for stage 1 / stage 2
   - `<vm>-packer-args`, `<vm>-extra-rules`, `<vm>-extra-envs`, `<vm>-deps`,
     `<vm>-pre-copy-cmd`, `<vm>-type` (`packer` default, `vm-combo` for export),
     `<vm>-dest-dir/-file`
3. At the bottom: `build-vms = base main full ...` (topological order) then
   `$(call vm_eval_all_rules)` — the actual rule generation.

Per-VM generated goals: `<vm>`, `<vm>_clean`, `<vm>_edit` (qcow2 backing-file
snapshot, `PAUSE=1`), `<vm>_commit` (qemu-img commit), `<vm>_vmdk`, plus `ssh`,
`init` (packer init), `@debug-rules` / `@debug-make` / `@print-<var>`.
`<vm>_test` (cloud layer only) boots with a generated cloud-init seed ISO.

Packer vars injected by the framework (generic layer): `vm_name`,
`source_image`, `output_directory`, `ssh_username/password`, `vm_debug`,
`vm_pause`, `vm_scripts_dir` / `vm_scripts_list`, `vm_prepare_script`,
`vm_prepare_dirs`, `vm_prepare_range1`, `vm_prepare_range2`, `vm_pre_copy_cmd`,
`vm_authorized_keys`, `vm_extra_envs`.

## Provisioning pipeline

Everything lands in the built VM at `/opt/vm-scripts/` (`VM_SCRIPTS_DIR`).
`file` provisioner uploads `vm_scripts_dir` (if non-empty) **or** the
`vm_scripts_list` dirs (rsync semantics — **end dirs with `/` to copy
contents**; later entries overwrite earlier ones).

Generic-layer VM, two shell steps, each starting with
`set -e; source $VM_SCRIPTS_DIR/lib/base.sh; @import 'vmrunner';` and running as
`sudo -E -S bash -e '{{.Path}}'` with `DEBUG`, `VM_DEBUG`, `VM_SCRIPTS_DIR`,
`VM_AUTHORIZED_KEYS` + `<vm>-extra-envs` exported:

```sh
VM_PREPARE_RANGE='1-19' VM_PREPARE_DIRS='…' vm_run_script "prepare-multistage.sh"   # stage 1
VM_PREPARE_RANGE='1-4,20-99' VM_PREPARE_DIRS='…' vm_run_script "prepare-multistage.sh"  # stage 2
```

Stage 1 is `expect_disconnect=true` (a reboot at its end is awaited normally);
stage 2 is not. An empty range skips the whole stage with a `SKIP stage N!` log.

Base images run **one** step: the same shared script, `VM_PREPARE_RANGE=1-99`,
`VM_PREPARE_DIRS` falling back to the legacy single `vm_prepare_dir`
(`base-<distro>.d`) declared in `<distro>.pkr.hcl`; `expect_disconnect=true`.

### `prepare-multistage.sh` — the only stage logic

- `VM_PREPARE_DIRS` — colon-separated, PATH-style, relative to
  `$VM_SCRIPTS_DIR` or absolute. Missing dirs are skipped. **First dir listed
  wins on duplicate filenames.** Default `prepare.d:install-stage1.d:install-stage2.d`.
- `VM_PREPARE_RANGE` — comma-separated `N` or `A-B`, e.g. `1-19`, `1,20-99`.
- Snippets are **sourced**, non-recursive, `.sh` only, and must match
  `^NN[-_ ]` (two-digit prefix; otherwise logged as `DISABLED (invalid filename)`).
- All dirs form one virtual dir: snippets run globally sorted by filename, so
  `90-cleanup.sh` from the first dir still runs after `25-docker.sh` from the last.
- No symlinks anywhere. `install-stage1.d` / `install-stage2.d` are legacy names
  (still in the default dir list, and logged as legacy when used).
- `VM_PREPARE_DIR` (singular) is the legacy single-dir fallback, still used by
  base images.

**Dir naming rule:** every layer must use a *unique* dir name
(`prepare-full.d`, `prepare-cloud.d`, `prepare-desktop-xfce.d`,
`prepare-main.d`, base images `base-<distro>.d`). Uploads merge by path, so two
layers shipping the same dir name collapse into one copy (last uploaded wins).

**Stage ranges:** default `1-19` (stage 1) and `1-4,20-99` (stage 2). So `NN`
01–04 (init/config) run in **both** stages, 10–19 in stage 1 only (safe place to
reboot at the end), 20+ in stage 2 only.

**`<vm>-script-dirs` replaces the list, it does not append.** A consumer adding
its own dir must list the layer's dir too:

```make
full-script-dirs = prepare-main.d:prepare-full.d   # ours first = higher priority
main-script-dirs = prepare-main.d
```

Snippets in `common-snippets.d/` are **not** auto-run; call them by name, e.g.
`vm_run_script "common-snippets.d/kernel-cmdline"` then
`vm_run_script "common-snippets.d/reboot"` as the last 1x snippet of a layer.

## Making a change — recipes

**New provisioning snippet** (most common): add `NN-name.sh` to
`layers/<layer>/scripts/prepare-<layer>.d/` (or `scripts/base-<distro>.d/` for a
base). Pick `NN` so it lands in the intended stage range. No Makefile change
needed when the dir is already in `-copy-scripts`/`-script-dirs`. Test:
`make <vm>_clean <vm>`, or faster `make <vm>_edit` then `make <vm>_commit`.

**New layer** (see skill `new-vm-layer`): `layers/<name>/` with `build.mk`
modeled on `layers/full-featured/build.mk` (which extends
`_vm_new_layer_generic_tpl`), `scripts/prepare-<name>.d/`, add the name to
`VM_ALL_LAYERS` in `layers/inc_all.mk`, then wire it in a Makefile with
`$(call vm_new_layer_<name>,<vm>)` + `<vm>-script-dirs` + `<vm>-copy-scripts`,
and add `<vm>` to `build-vms` after its `src-from`.

**New base distro**: `base/<distro>/` with `build.mk` (mirror `base/arch` for a
custom shell installer, `base/debian` otherwise), `<distro>.pkr.hcl` declaring
`vm_prepare_script`, `vm_prepare_dir = "base-<distro>.d"`, `vm_prepare_range`,
`source_image`/`source_checksum`, plus **relative symlinks**
`common.pkr.hcl -> ../common.pkr.hcl` and
`common_arch.pkr.hcl -> ../common_arch.pkr.hcl` (copying them instead means they
drift). Add `scripts/base-<distro>.d/`, a `<DISTRO>_ISO_NAME` in
`config.default.mk`, and the distro to `VM_ALL_BASES`.

**Makefile debug**: `make @debug-rules` (generated rules), `make @debug-make`
(full `make -r -p` dump), `make @print-<vm>-dest-image`, `make -n <vm>` (dry
run). `FORCE=1` wipes the dest dir before build. `PAUSE=1` (implied by `DEBUG`)
keeps qemu open at the breakpoint → `make ssh` (port 20022, `SSH_PORT`).

**VM console**: `HEADLESS=1`, `QEMU_MONITOR=<sock>`, `QEMU_SERIAL=<log>`, or
`DEBUG_CONSOLE=1` for all three (paths under `BUILD_DIR`) — see
`docs/Debugging.md`.

## Gotchas

- **`<vm>-script-dirs` replaces the default list.** Forgetting the layer's dir
  (e.g. setting only `prepare-main.d` on a full-featured VM) silently drops all
  framework snippets. This is the most common wiring bug.
- **Unique prepare dir names** per layer — merged uploads collapse same-named
  dirs.
- Build dependencies default to `rwildcard(<vm>-packer-src)`, which for layers
  is `layers/generic/` — editing `layers/<name>/scripts/` does **not** retrigger
  a build. Add `<vm>-deps = $(VM_<NAME>_SCRIPTS_DIR)` if you want that.
- `<vm>-copy-scripts =` also **replaces** the layer's list. `full-featured` now
  ships `<FRAMEWORK_DIR>/scripts/` + its own dir itself; `cloud`/`desktop-xfce`
  ship only their dir, relying on the source image for `lib/` (it is baked into
  `/opt/vm-scripts/` by the base build). Always include the framework `scripts/`
  dir when writing your own list, or `lib/` may be stale.
- Never symlink a snippet into a stage dir — that mechanism is gone; use ranges.
- `<vm>-pre-copy-cmd` runs *inside* the VM before the upload; use it to clear
  dirs that git/packer cannot overwrite (e.g. `rm -rf thirdparty`).
- `<vm>_test` (cloud) disables provisioning by emptying both ranges and exports
  `VM_CLOUD_TESTING=1` — nothing reads that variable today; the empty ranges are
  what actually skips the work.
- A deleted `.qcow2` with a surviving `<dest>/.exists` makes make think the VM is
  built — always use `make <vm>_clean`.

## Conventions

- Bash: `#!/bin/bash`, no `set` (runner already runs `bash -e`); second line
  guard `[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }`;
  use `sh_log_info/debug/error` for output, not raw `echo`.
- Scripts are **sourced**: `return` skips one snippet, `exit` ends the stage.
- Modules: `@import 'vmrunner'`, `@import 'arch/packages.sh'`
  (`.sh` optional, resolved against `$VM_SCRIPTS_DIR/lib/`), cached per path;
  `@import --parent '<sibling>'` searches below the current module's dir.
  `sh_get_script_path` gives a script's own dir.
- Package managers are abstracted: `pkg_init_update`, `pkg_install`,
  `pkg_remove`, `pkg_upgrade_all`, `pkg_cleanup` (`lib/debian/packages.sh`,
  `lib/arch/packages.sh`).
- Makefiles: use `?=` for overridable defaults; `<vm>-` prefix for per-VM vars;
  always `$(abspath ...)` for copied script paths; never quote paths (make).
- Commits: `component: lowercase message` (e.g. `layers/xfce: support ubuntu Lightdm configuration`,
  `qemu: remove index=0 from cdrom drive definition`).
- Never commit `config.local.mk` contents (local ISO paths, mirrors, keys).
- `VM_USER`/`VM_PASSWORD` travel to the VM as packer args — keep them temporary
  values; don't hardcode anything stronger.
- Image outputs go to `BUILD_DIR` (default `~/.cache/packer`) — not in the repo;
  don't `rm` things there except via `_clean` rules.
- Packer changes: `packer init` after touching plugin blocks; HCL lives per
  layer (`build.pkr.hcl`) and per base — Packer merges **all** `*.pkr.hcl` files
  in the packer source dir, so shared locals (`qemu_arch_*` in
  `layers/generic/common_arch.pkr.hcl`, `base/common_arch.pkr.hcl`) are picked
  up automatically alongside the per-base file.
- Multi-arch: `ARCH=x86_64` default; `ARCH_SUFFIX` is empty for x86_64 and
  `_<arch>` otherwise, so image names differ per arch. `ARCH_USE_EFI` is
  auto-set for aarch64.
- Export layers (`<vm>-type = vm-combo`) expose `<vm>-vmname`, `<vm>-ostype`,
  `<vm>-ostype-vbox`/`-ostype-vmware`, `<vm>-ramsize`, `<vm>-vcpus`, `<vm>-vram`,
  `<vm>-vbox-gfx-controller`, `<vm>-vmware-disk-type`, `<vm>-ssh-nat` (10022).
- Helper modules under `scripts/lib/` are vendored from
  `github.com/niflostancu/sh-lib`; regenerate with `cd scripts/lib && make
  dev-upgrade` instead of editing them.
