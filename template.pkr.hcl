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

  firmware                 = "efi"
  cpus                     = 2
  memory                   = 2048
  disk_size                = 20480
  hard_drive_interface     = "scsi"
  hard_drive_discard       = true
  hard_drive_nonrotational = true
  iso_interface            = "sata"
  gfx_controller           = "vmsvga"
  gfx_vram_size            = 16
  gfx_efi_resolution       = "1024x768"
  nested_virt              = true
  guest_additions_mode     = "upload"

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
  acpi_shutdown    = true
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
