// multi-arch specializations for Debian installer 

variables {
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
  qemu_efi_firmware = lookup(lookup(local.arch_vars, var.arch, {}), "firmware", "")
  debian_boot_keys_efi = join("", [
    "<wait><wait><wait>e<wait><wait><wait>",
    "<down><down><down>",
    "<leftCtrlOn>k<leftCtrlOff><wait>linux ",
  ])
  debian_boot_keys_bios = "<wait><wait><wait><esc><wait><wait><wait>"
  arch_vars = {
    "x86_64" = {
      debian_boot_keys = (var.qemu_firmware != "" ? local.debian_boot_keys_efi : 
        local.debian_boot_keys_bios )
      kernel_cmdline = join("", ["vga=788 noprompt quiet -- ",
        (var.qemu_firmware != "" ? "<f10>" : "<enter>")]),
      debian_install = "install.amd"
      qemu_binary  = (var.qemu_binary != "" ? var.qemu_binary : "qemu-system-x86_64")
      firmware     = var.qemu_firmware
      use_pflash   = true
      machine_type = (var.qemu_machine_type != "" ? var.qemu_machine_type : "pc")
      accelerator  = (var.qemu_accelerator != "" ? var.qemu_accelerator : "kvm")
      extra_args   = []
    }

    // Kudos: https://github.com/GeoffWilliams/packer_images
    "aarch64" = {
      debian_boot_keys = local.debian_boot_keys_efi
      kernel_cmdline = " console=tty0 console=ttyS0 -- <f10>",
      debian_install = "install.a64"
      qemu_binary  = (var.qemu_binary != "" ? var.qemu_binary : "qemu-system-aarch64")
      firmware     = var.qemu_firmware
      use_pflash   = false
      machine_type = (var.qemu_machine_type != "" ? var.qemu_machine_type :
        "virt,gic-version=max,accel=hvf:kvm:whpx:tcg")
      accelerator  = (var.qemu_accelerator != "" ? var.qemu_accelerator : "none")
      extra_args   = [
        ["-cpu", "cortex-a57"],
        ["-boot", "strict=off"],
        # uncomment for graphics console support
        ["-device", "virtio-gpu-pci"], 
        ["-device", "usb-ehci"],
        ["-device", "usb-kbd"],
        ["-monitor", "none"],
        ["-device", "virtio-net-device,netdev=net0"],
        ["-netdev", "type=user,id=net0,hostfwd=tcp::20022-:22"],
      ]
    }
  }
}
