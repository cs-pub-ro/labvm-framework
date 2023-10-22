packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.10"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variables {
  vm_name = "basevm"
  vm_pause = 0
  vm_debug = 0
  qemu_unmap = false
  qemu_ssh_forward = 20022
  source_image = "https://releases.ubuntu.com/22.04/ubuntu-22.04.3-live-server-amd64.iso"
  source_checksum = "none"
  use_backing_file = false
  output_directory = "/tmp/packer-out"
  boot_wait = "5s"
  ssh_username = "student"
  ssh_password = "student"
}

source "qemu" "ubuntu-22-base" {
  // VM Info:
  vm_name       = var.vm_name
  headless      = false

  // Virtual Hardware Specs
  memory         = 2048
  cpus           = 2
  disk_size      = 8000
  disk_interface = "virtio"
  net_device     = "virtio-net"
  // disk usage optimizations (unmap zeroes as free space)
  disk_discard   = (var.qemu_unmap ? "unmap" : "")
  disk_detect_zeroes = (var.qemu_unmap ? "unmap" : "")
  // skip_compaction = true
  
  // ISO & Output details
  iso_url           = var.source_image
  iso_checksum      = var.source_checksum
  disk_image        = var.use_backing_file
  use_backing_file  = var.use_backing_file
  output_directory  = var.output_directory

  ssh_username      = var.ssh_username
  ssh_password      = var.ssh_password
  ssh_timeout       = "30m"
  host_port_min     = var.qemu_ssh_forward
  host_port_max     = var.qemu_ssh_forward

  http_directory    = "http"
  boot_wait = (var.use_backing_file ? null : var.boot_wait)
  boot_command = (var.use_backing_file ? null : [
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall ds=\"nocloud;s=http://{{.HTTPIP}}:{{.HTTPPort}}/\"",
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot",
    "<enter>"
  ])
  shutdown_command  = "sudo /sbin/shutdown -h now"
}

build {
  sources = ["sources.qemu.ubuntu-22-base"]

  provisioner "shell" {
    scripts = [
      "scripts/00-base.sh",
      "scripts/90-cleanup.sh",
    ]
    execute_command = "{{.Vars}} sudo -E -S bash -e '{{.Path}}'"
    environment_vars = [
      "VM_DEBUG=${var.vm_debug}"
    ]
  }

  provisioner "breakpoint" {
    disable = (var.vm_pause == 0)
    note    = "this is a breakpoint"
  }
}

