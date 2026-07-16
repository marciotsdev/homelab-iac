variable "proxmox_node" {
  type    = string
  default = "pve"
}

variable "template_vm_id" {
  type    = number
  default = 9000
}

variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

variable "gateway" {
  type        = string
  description = "Network gateway for the cloned VMs, e.g. 192.168.1.1"
}

variable "datastore_id" {
  type    = string
  default = "local-lvm"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Path to the SSH public key injected into cloned VMs via cloud-init, e.g. ~/.ssh/id_ed25519.pub"
}

variable "vm_user" {
  type    = string
  default = "ubuntu"
}

variable "vms" {
  description = "Map of homelab VMs to create by cloning the base template"
  type = map(object({
    vm_id  = number
    ip     = string
    cores  = number
    memory = number
    disk   = number
  }))
}
