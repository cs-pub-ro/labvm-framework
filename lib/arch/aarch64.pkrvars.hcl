arch = "aarch64"
qemu_binary = "qemu-system-aarch64"
qemu_machine_type = "virt,gic-version=max,accel=hvf:kvm:whpx:tcg"
qemu_accelerator = "none"
qemu_extra_args = [
  ["-cpu", "cortex-a57"],
  ["-boot", "strict=on"],
  # uncomment for graphics console support
  #["-device", "virtio-gpu-pci"], 
  #["-device", "usb-ehci"],
  #["-device", "usb-kbd"],
  ["-monitor", "none"],
]
