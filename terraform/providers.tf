terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.66.0"
    }
  }
}

# Credentials come from PROXMOX_VE_ENDPOINT / PROXMOX_VE_API_TOKEN / PROXMOX_VE_INSECURE
# environment variables (see ~/.bashrc) — never stored in this repo.
provider "proxmox" {}
