---
name: vm-build-debug
description: Diagnose a failing or hanging labvm-framework VM build — distinguish make/rule errors from packer/qemu setup, missing ISOs, KVM vs TCG, boot_command timing, prepare-multistage range/shadowing problems, and provisioning script errors; then iterate fast with the backing-file _edit/_commit loop and console/VNC/serial/monitor tooling. Use when `make <vm>` errors out, hangs at boot, times out on SSH, silently skips snippets, or you need to watch provisioning run inside the guest.
---

# Debugging a VM build

Builds fail in five distinguishable places. Identify the layer first — the fix is
almost always in that layer, and guessing costs a 20-minute rebuild.

| # | Layer | Symptom | First command |
|---|---|---|---|
| 1 | make/rules | fails in <1 s, `No rule to make target`, empty `$(VAR)` | `make @debug-rules`, `make -n <vm>` |
| 2 | packer/qemu setup | `packer` errors before any boot output | `make @print-<vm>-src-image`, `ls -l /dev/kvm` |
| 3 | guest boot/installer | hangs at `<wait>` / VNC, SSH timeout (30 m) | `make <vm> DEBUG_CONSOLE=1` |
| 4 | provisioning | boot OK, but snippets skipped or a step fails | grep the output for `SKIP` / `DISABLED` / `Ignoring` |
| 5 | post-install | image built but export/compact fails | `make <vm>_vmdk`, `<vm>_compact` |

`packer` runs with `-on-error=abort` (see `config.default.mk`), so on failure the
qemu VM is **left running** — `make ssh` usually still gets you in. That is the
single most useful fact here.

## 1. Rules and variables

```sh
make @debug-rules          # generated rules for every VM in build-vms
make @debug-make           # full `make -r -p` variable dump
make @print-<vm>-dest-image
make @print-<var>          # any global var, e.g. @print-base-src-image
make -n <vm>               # print the exact packer command line
```

`@print-%` echoes `$* = $($*)` for a global variable only — per-VM values are
`<vm>-<prop>` (`@print-labvm-script-dirs`).

Layer-1 causes: `<vm>` missing from `build-vms` (no rule at all); `src-from`
pointing at a VM declared *after* it in `build-vms`; missing `lib/inc_all.mk`
(the `check-var,_vm_new_layer_generic_tpl` guard fires).

## 2. Host / qemu

```sh
make @print-<vm>-src-image     # must be an existing path; empty = ISO glob missed
ls -l /dev/kvm                 # in a container: --device /dev/kvm
qemu-system-x86_64 --version
```

- **No KVM** (containers, Mac): `PACKER_ARGS_EXTRA ?= -var qemu_accelerator=tcg`
  in `config.local.mk`. Everything still works but 10–50× slower; the base
  images' 30 m (Ubuntu: 60 m) `ssh_timeout` can be tight.
- **Empty `src-image`** → `-var "source_image="` → qemu cannot start. Fix
  `BASE_ISO_DIR` / the `*_ISO_NAME` glob, or set `BASE_VM_INSTALL_ISO`.
- **Aarch64**: firmware comes from `/usr/share/OVMF/` (`lib/arch.mk`);
  `make base DEBUG=1` prints the chosen arch, accelerator and firmware.
- **Port 20022** is fixed (`qemu_ssh_forward`). Two builds at once collide —
  don't `make -j base labvm`.
- **"Output directory already exists"** → `make <vm>_clean <vm>`, or `FORCE=1`
  (note `FORCE ?= $(DELETE)`, and it wipes the dest dir of *every* VM built in
  that invocation, dependencies included — prefer `_clean`).

## 3. Watching the guest

Default: qemu GUI + a VNC server Packer itself uses. Packer prints
`vnc://127.0.0.1:<port>` — any VNC client works, including headless. To inspect
without a GUI:

```sh
make <vm> DEBUG_CONSOLE=1        # = HEADLESS=1 + monitor socket + serial log
```

(individual switches `HEADLESS=1`, `QEMU_MONITOR=<sock>`, `QEMU_SERIAL=<log>`,
from `lib/qemu_debug.mk`; all three are also packer vars read by
`base/common_arch.pkr.hcl`.)

```sh
printf 'screendump /tmp/vm.png -f png\n' | socat - UNIX-CONNECT:$BUILD_DIR/qemu-monitor.sock
tail -f $BUILD_DIR/qemu-serial.log
```

Caveats: Debian/Ubuntu installers do **not** log to serial (their ISO cmdline
lacks `console=ttyS0`); the Arch ISO does. Installed systems get it via
`scripts/common-snippets.d/kernel-cmdline.sh`. Packer also writes `packer.log`
into the VM's output directory.

Hanging at boot almost always means `boot_command` lost the VNC keystroke race:
raise `boot_command_wait` / `boot_key_interval` / `boot_wait` (packer vars with
defaults in `base/common.pkr.hcl`).

Keeping the VM open after provisioning:

```sh
make <vm>_edit      # PAUSE=1 + backing file; replays provisioning every run
make ssh            # port 20022, user $VM_USER (default `student`)
```

`DEBUG=1` implies `PAUSE=1`, passes `vm_debug=1` into the guest, and unlocks
`sh_log_debug` output — including `prepare-multistage.sh`'s
`SKIP prepare dir (missing): …` lines.

## 4. "My snippet didn't run"

`prepare-multistage.sh` is a range filter over a PATH-style dir list. Every
failure is logged; read the stage output for these strings:

| Log line | Cause |
|---|---|
| `SKIP stage 1!` / `SKIP stage 2!` | `vm_prepare_range1/2` is empty for that VM |
| `SKIP prepare: no range given` | same, seen inside the runner |
| `SKIP prepare: no snippets found in: <dirs>` | none of the dirs exist in `/opt/vm-scripts` |
| `SKIP prepare dir (missing): <path>` (debug only) | dir name not in `-script-dirs`, or not uploaded by `-copy-scripts` |
| `DISABLED (invalid filename): <file>` | no two-digit `NN-` prefix |
| `Ignoring <file> from <dir>/ (shadowed by an earlier dir)` | duplicate filename; first dir listed wins |
| `NOTE: legacy snippets dir` | dir named `install-stage1.d`/`install-stage2.d` |

Check the effective values first: `make @debug-rules` shows
`-var 'vm_prepare_dirs=…'` and `vm_prepare_range1/2` for that VM.
`<vm>-script-dirs` **replaces** the default (`prepare.d:install-stage1.d:install-stage2.d`),
so a consumer that sets only its own dir drops all layer snippets.

Range reminder: stage 1 = `1-19`, stage 2 = `1-4,20-99` — `NN` 01–04 runs twice
(init/config), 10–19 stage 1 only, 20+ stage 2 only. Also note byte ordering:
`01-init-full.sh` sorts *before* `01-init.sh` (`-` < `.`), so flag overrides
belong in `02-*`.

Other provisioning causes:

- Script run outside the runner: the `__INSIDE_VM_RUNNER` guard fires and
  returns 1. That is by design — use `install.sh <dir>` or let packer run it.
- A sourced snippet calls `exit` instead of `return` → the stage ends early;
  look for missing "> Running NN-x.sh" lines.
- `pkg_install` without `pkg_init_update` first (repo not updated / key
  missing).

```sh
make ssh
ls -R /opt/vm-scripts | head -40        # what was actually uploaded
sudo journalctl -b -u <service>
sudo -E bash /opt/vm-scripts/prepare-<x>.d/20-y.sh   # re-run by hand
```

## 5. Fast iteration

```sh
make <vm>_edit FORCE=1     # rebuild the snapshot VM from its parent image
make ssh                   # fix things live
make <vm>_commit           # qemu-img commit: snapshot -> parent image
```

`_edit` builds a qcow2 with the finished image as backing file
(`use_backing_file=true`), so it starts from the provisioned system — seconds,
not minutes. The target is phony: it replays **all** provisioning on every run,
and `FORCE=1` is needed when the previous `<name>_edit/` dir survived.

Beware: `_commit` writes into the *parent* image. After committing exploratory
changes, rebuild the parent (`make <vm>_clean <vm>`) for a clean state.

Script edits do not trigger rebuilds (deps default to
`rwildcard(<vm>-packer-src)` = `layers/generic`) unless `<vm>-deps` includes the
script dirs.

## 6. Post-install

```sh
make <vm>_vmdk       # qemu-img convert -O vmdk
make <vm>_compact    # zerofree via qemu-nbd (needs sudo + qemu-nbd)
make <vm>_test       # cloud layer only: boots with a generated cloud-init seed
```

`_compact` failures are environmental: `utils/zerofree.sh` needs `qemu-nbd`,
`sudo`, and the right root partition (`ZEROFREE_PART_NUM`, default `2` — wrong
when `/boot` is separate); slow machines may need a larger `ZEROFREE_DEV_WAIT`.
`<vm>_test` needs `genisoimage` + `uuidgen`, empties both prepare ranges (no
provisioning at all), and boots with `-snapshot`, so nothing persists.

## Pitfalls

- Deleting only the `.qcow2` leaves `<dest>/.exists` behind — make then believes
  the VM is built. Always `make <vm>_clean`.
- After touching `packer { required_plugins }`, run `make init` (it loops
  `INIT_GOAL`), or packer complains about a missing plugin.
- `Unknown variable` / `failed to decode` → a `<vm>-packer-args` var no
  `.pkr.hcl` in the source dir declares. Packer merges **all** `*.pkr.hcl` in the
  source dir, so check `base/<distro>/` (its `common*.pkr.hcl` are symlinks to
  `base/`) or `layers/generic/`.
- A build that "succeeds" but produces an unprovisioned image almost always hit
  an empty stage range or a `-script-dirs` that omits the layer's dir.
