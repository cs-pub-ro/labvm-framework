// Common Packer qemu/arch-specific definitions

variables {
  // user-configurable qemu overrides
  arch = "x86_64"
  qemu_binary = ""
  qemu_machine_type = ""
  qemu_accelerator = ""
  qemu_firmware = ""
}
variable "qemu_args" {
  type    = list(list(string))
  default = []
}

locals {
  // arch-specialized aliases
  qemu_arch_binary = lookup(lookup(local.qemu_arch_defs, var.arch, {}), "qemu_binary", "")
  qemu_arch_machine_type = lookup(lookup(local.qemu_arch_defs, var.arch, {}), "machine_type", "")
  qemu_arch_firmware = lookup(lookup(local.qemu_arch_defs, var.arch, {}), "firmware", "")
  qemu_arch_accelerator  = lookup(lookup(local.qemu_arch_defs, var.arch, {}), "accelerator", "")
  qemu_arch_qemuargs = concat(var.qemu_args, lookup(lookup(local.qemu_arch_defs, var.arch, {}),
    "extra_args", []))

  // definitions
  qemu_arch_defs = {
    "x86_64" = {
      qemu_binary  = (var.qemu_binary != "" ? var.qemu_binary : "qemu-system-x86_64")
      firmware     = var.qemu_firmware
      use_pflash   = false
      machine_type = (var.qemu_machine_type != "" ? var.qemu_machine_type : "pc")
      accelerator  = (var.qemu_accelerator != "" ? var.qemu_accelerator : "kvm")
      extra_args   = []
    }

    "aarch64" = {
      qemu_binary  = (var.qemu_binary != "" ? var.qemu_binary : "qemu-system-aarch64")
      firmware     = var.qemu_firmware
      use_pflash   = false
      machine_type = (var.qemu_machine_type != "" ? var.qemu_machine_type :
        "virt,gic-version=max,accel=hvf:kvm:whpx:tcg")
      accelerator  = (var.qemu_accelerator != "" ? var.qemu_accelerator : "none")
      extra_args   = [
        ["-cpu", "cortex-a57"],
        ["-boot", "strict=off"],
        # use graphics console support (otherwise Packer send keys doesn't work)
        ["-device", "virtio-gpu-pci"], 
        ["-device", "usb-ehci"],
        ["-device", "usb-kbd"],
        ["-monitor", "none"],
      ]
    }
  }
}
