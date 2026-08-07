gateway             = "192.168.15.1"
ssh_public_key_path = "~/.ssh/homelab_ed25519.pub"

vms = {
  awx = {
    vm_id  = 2001
    ip     = "192.168.15.50/24"
    cores  = 4
    memory = 16384
    disk   = 60
  }
  jenkins = {
    # Aposentado (CI migrado para o GitLab) — VM preservada, sem tag e sem boot
    vm_id  = 2002
    ip     = "192.168.15.51/24"
    cores  = 2
    memory = 4096
    disk   = 40
    tags   = []
  }
  gitea = {
    vm_id   = 2003
    ip      = "192.168.15.52/24"
    cores   = 2
    memory  = 2048
    disk    = 20
    on_boot = true
  }
  containers = {
    vm_id  = 2004
    ip     = "192.168.15.53/24"
    cores  = 2
    memory = 4096
    disk   = 40
  }
  client = {
    vm_id  = 2005
    ip     = "192.168.15.54/24"
    cores  = 2
    memory = 4096
    disk   = 20
  }
  backstage = {
    vm_id   = 2006
    ip      = "192.168.15.55/24"
    cores   = 2
    sockets = 2
    memory  = 8192
    disk    = 45
    # Liga junto com o cluster: e o portal de entrada pras outras ferramentas
    # do lab (ligado na UI do Proxmox em 05/08, alinhado aqui pra nao haver
    # drift no proximo apply).
    on_boot = true
  }
  localstack = {
    # MiniStack (emulador AWS) + StackPort
    vm_id       = 2007
    ip          = "192.168.15.56/24"
    cores       = 2
    memory      = 4096
    disk        = 21
    dns_servers = ["192.168.15.1"]
    ssh_keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBogEzcV72H1vVmvC849JTMTFYguxVw5QKl4JX85fRj0 thundercat@windows-claude",
    ]
  }
  gitlab = {
    # GitLab CE via docker compose — clonado do template manual 10016 (sem cloud-init);
    # IP estatico configurado dentro do guest (netplan)
    vm_id          = 2008
    ip             = "192.168.15.57/24"
    cores          = 2
    sockets        = 4
    cpu_type       = "x86-64-v2-AES"
    memory         = 24576
    disk           = 120
    datastore_id   = "DATA"
    disk_interface = "sata0"
    template_vm_id = 10016
    nic_firewall   = true
    cloudinit      = false
    on_boot        = true
    scsi_hardware  = "virtio-scsi-single"
    description    = "https://dev.to/teetoflame/setting-up-a-gitlab-server-community-edition-and-a-gitlab-runner-using-docker-compose-ob6"
  }
  gitlab-runners = {
    # Runners de CI em containers (runner-infra shell + runner-docker)
    # Memoria subida de 4096 pra 8192 em 2026-08-07: VM alarmava uso de
    # memoria (3.61GB de 4GB) mesmo so com os dois runners + docker.
    vm_id       = 2009
    ip          = "192.168.15.58/24"
    cores       = 2
    memory      = 8192
    disk        = 21
    on_boot     = true
    dns_servers = ["192.168.15.1"]
    ssh_keys = [
      # Faltava esta chave (unica diferenca deste bloco pras demais VMs) — sem
      # ela o Ansible nao consegue entrar; descoberto ao recriar a VM em 07 ago 2026.
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBO3BiGOxRN29Jfas+UGS0hV+JGKZedAl+IMpzwrzLs8 homelab-terraform-ansible",
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBogEzcV72H1vVmvC849JTMTFYguxVw5QKl4JX85fRj0 thundercat@windows-claude",
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJJbotLXtaqwLd2a8vYRCOO3YbpMgIuMevYKhz9NoHJ4 root@pve",
    ]
  }
}

# Nota: os clusters Kubernetes (ArgoCD + Crossplane) vivem no projeto separado
# homelab-gitops, com state proprio. Ver github.com/marciotsdev/homelab-gitops.


template_vm_id = 1001
