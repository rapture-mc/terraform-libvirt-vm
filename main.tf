terraform {
  required_version = ">= 1.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = ">= 0.7.0"
    }
  }
}

resource "libvirt_domain" "virt-machine" {
  count  = var.vm_count
  name   = format("${var.vm_hostname_prefix}%02d", count.index + var.index_start)
  memory = var.memory
  cpu {
    mode = var.cpu_mode
  }
  vcpu       = var.vcpu
  autostart  = var.autostart
  firmware   = var.uefi_enabled ? var.firmware : null
  qemu_agent = true

  network_interface {
    bridge         = var.bridge
    wait_for_lease = true
    hostname       = format("${var.vm_hostname_prefix}%02d", count.index + var.index_start)
  }

  xml {
    xslt = templatefile("${path.module}/xslt/template.tftpl", var.xml_override)
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = element(libvirt_volume.volume-qcow2[*].id, count.index)
  }

  dynamic "disk" {
    for_each = var.additional_disk_ids
    content {
      volume_id = disk.value
    }
  }

  dynamic "filesystem" {
    for_each = var.share_filesystem.source != null ? [var.share_filesystem.source] : []
    content {
      source     = var.share_filesystem.source
      target     = var.share_filesystem.target
      readonly   = var.share_filesystem.readonly
      accessmode = var.share_filesystem.mode
    }
  }

  graphics {
    type        = var.graphics
    listen_type = "address"
    autoport    = true
  }
}
