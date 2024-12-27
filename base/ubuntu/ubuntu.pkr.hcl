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
  vm_scripts_dir = "scripts/"
  vm_prepare_script = "$VM_SCRIPTS_DIR/base-prepare.sh"
  vm_install_base = "$VM_SCRIPTS_DIR/base-debian.d/"
  vm_ubuntu_ver = "22"
  qemu_unmap = false
  qemu_ssh_forward = 20022
  disk_size = 8192
  source_image = "https://releases.ubuntu.com/22.04/ubuntu-22.04.3-live-server-amd64.iso"
  source_checksum = "none"
  use_backing_file = false
  output_directory = "/tmp/packer-out"
  boot_wait = "5s"
  ssh_username = "student"
  ssh_password = "student"
}
variable "vm_scripts_list" {
  type    = list(string)
  default = []
}

locals {
  scripts_dir = "/opt/vm-scripts"
  envs = [
    "VM_DEBUG=${var.vm_debug}",
    "VM_SCRIPTS_DIR=${local.scripts_dir}",
  ]
  sudo = "{{.Vars}} sudo -E -S bash -e '{{.Path}}'"
  provision_init = "set -e; source ${local.scripts_dir}/lib/base.sh; @import 'vmrunner';"
}

source "qemu" "base-ubuntu" {
  // VM Info:
  vm_name       = var.vm_name
  headless      = false

  // Virtual Hardware Specs
  memory         = 2048
  cpus           = 2
  disk_size      = var.disk_size
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
    "linux /casper/vmlinuz autoinstall ds=\"nocloud;s=http://{{.HTTPIP}}:{{.HTTPPort}}/\" ---",
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot",
    "<enter>"
  ])
  shutdown_command  = "sudo /sbin/shutdown -h now"
}

build {
  sources = ["sources.qemu.base-ubuntu"]

  provisioner "shell" {
    inline = [
      "mkdir -p $VM_SCRIPTS_DIR",
      "chown ${var.ssh_username}:${var.ssh_username} $VM_SCRIPTS_DIR -R"
    ]
    execute_command = local.sudo
    environment_vars = local.envs
  }
  provisioner "file" {
    sources = concat(
      (var.vm_scripts_dir != "" ? [var.vm_scripts_dir] : var.vm_scripts_list),
    )
    destination = "${local.scripts_dir}/"
  }

  provisioner "shell" {
    # run the base preparation script (if any)
    inline = [
      "${local.provision_init}",
      "vm_run_script --optional \"${var.vm_prepare_script}\""
    ]
    expect_disconnect = true
    execute_command = local.sudo
    environment_vars = local.envs
  }
  provisioner "shell" {
    # run the base provisioning scripts
    inline = [
      "${local.provision_init}",
      "vm_run_scripts --optional \"${var.vm_install_base}\""
    ]
    expect_disconnect = true
    execute_command = local.sudo
    environment_vars = local.envs
  }

  provisioner "breakpoint" {
    disable = (var.vm_pause == 0)
    note    = "this is a breakpoint"
  }
}

