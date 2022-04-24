packer {
  required_plugins {
    virtualbox = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}

source "virtualbox-iso" "virtualbox" {
  guest_os_type = "Debian_64"
  iso_url       = "http://download.proxmox.com/iso/proxmox-ve_7.1-2.iso"
  iso_checksum  = "sha256:f469d2e419328c4b8715544c84f629161cc07024ce26ad63f00bc1b07de265df"

  cpus        = 2
  memory      = 4096
  nested_virt = true

  boot_command = [
    "<enter>",
    "<wait30>",
    "<enter>",
    "<wait5>",
    "<enter>",
    "<wait5>",
    "<tab>",
    "<wait1>",
    "<tab>",
    "<wait1>",
    "<tab>",
    "<wait1>",
    "<tab>",
    "<wait1>",
    "<enter>",
    "<wait5>",
    "vagrant",
    "<tab>",
    "<wait1>",
    "vagrant",
    "<tab>",
    "<wait1>",
    "pve@example.com",
    "<tab>",
    "<wait1>",
    "<tab>",
    "<wait1>",
    "<enter>",
    "<wait5>",
    "<tab>",
    "<wait1>",
    "<tab>",
    "<wait1>",
    "<tab>",
    "<wait1>",
    "<tab>",
    "<wait1>",
    "<tab>",
    "<wait1>",
    "<tab>",
    "<wait1>",
    "<enter>",
    "<wait5>",
    "<enter>",
  ]

  ssh_username = "root"
  ssh_password = "vagrant"
  ssh_timeout  = "60m"

  shutdown_command = "poweroff"
  acpi_shutdown = true
}

build {
  sources = ["sources.virtualbox-iso.virtualbox"]
  provisioner "shell" {
    scripts = [
      "provision.sh",
    ]
  }
  post-processors {
    post-processor "vagrant" {
    }
  }
}
