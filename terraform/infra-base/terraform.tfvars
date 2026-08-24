gateway             = "192.168.15.1"
ssh_public_key_path = "~/.ssh/homelab_ed25519.pub"

vms = {
  awx = {
    vm_id       = 2001
    ip          = "192.168.15.50/24"
    cores       = 4
    memory      = 16384
    disk        = 60
    dns_servers = ["192.168.15.65", "192.168.15.1"]
  }
  jenkins = {
    # Aposentado (CI migrado para o GitLab) — VM preservada, sem tag e sem boot
    vm_id       = 2002
    ip          = "192.168.15.51/24"
    cores       = 2
    memory      = 4096
    disk        = 40
    tags        = []
    dns_servers = ["192.168.15.65", "192.168.15.1"]
  }
  gitea = {
    vm_id       = 2003
    ip          = "192.168.15.52/24"
    cores       = 2
    memory      = 2048
    disk        = 20
    on_boot     = true
    dns_servers = ["192.168.15.65", "192.168.15.1"]
  }
  containers = {
    vm_id       = 2004
    ip          = "192.168.15.53/24"
    cores       = 2
    memory      = 4096
    disk        = 40
    dns_servers = ["192.168.15.65", "192.168.15.1"]
  }
  client = {
    vm_id       = 2005
    ip          = "192.168.15.54/24"
    cores       = 2
    memory      = 4096
    disk        = 20
    dns_servers = ["192.168.15.65", "192.168.15.1"]
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
    on_boot     = true
    dns_servers = ["192.168.15.65", "192.168.15.1"]
  }
  localstack = {
    # MiniStack (emulador AWS) + StackPort
    vm_id       = 2007
    ip          = "192.168.15.56/24"
    cores       = 2
    memory      = 4096
    disk        = 21
    dns_servers = ["192.168.15.65", "192.168.15.1"]
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
    dns_servers = ["192.168.15.65", "192.168.15.1"]
    ssh_keys = [
      # Faltava esta chave (unica diferenca deste bloco pras demais VMs) — sem
      # ela o Ansible nao consegue entrar; descoberto ao recriar a VM em 07 ago 2026.
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBO3BiGOxRN29Jfas+UGS0hV+JGKZedAl+IMpzwrzLs8 homelab-terraform-ansible",
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBogEzcV72H1vVmvC849JTMTFYguxVw5QKl4JX85fRj0 thundercat@windows-claude",
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJJbotLXtaqwLd2a8vYRCOO3YbpMgIuMevYKhz9NoHJ4 root@pve",
    ]
  }
  elk = {
    # Observabilidade do lab (Elasticsearch + Logstash + Kibana, baseado em
    # github.com/deviantony/docker-elk) — VM propria de proposito, mesmo
    # padrao ja usado pra isolar componentes pesados (Crossplane). Coleta
    # logs das VMs do homelab-iac (Filebeat) e dos clusters k3s do
    # homelab-gitops (Filebeat DaemonSet), nas fases seguintes.
    vm_id       = 2014
    ip          = "192.168.15.63/24"
    cores       = 6
    memory      = 18432
    disk        = 60
    on_boot     = true
    dns_servers = ["192.168.15.65", "192.168.15.1"]
    ssh_keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBO3BiGOxRN29Jfas+UGS0hV+JGKZedAl+IMpzwrzLs8 homelab-terraform-ansible",
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBogEzcV72H1vVmvC849JTMTFYguxVw5QKl4JX85fRj0 thundercat@windows-claude",
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJJbotLXtaqwLd2a8vYRCOO3YbpMgIuMevYKhz9NoHJ4 root@pve",
    ]
  }
  defectdojo = {
    # Dashboard de compliance/auditoria pros achados do gitleaks/trivy (scan
    # de CI, ver root/lab-ops ci-templates/scan.yml) - consolida findings,
    # dedup, SLA de remediacao, relatorios exportaveis pra auditoria.
    vm_id       = 2015
    ip          = "192.168.15.64/24"
    cores       = 4
    memory      = 8192
    disk        = 60
    on_boot     = true
    dns_servers = ["192.168.15.65", "192.168.15.1"]
    ssh_keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBO3BiGOxRN29Jfas+UGS0hV+JGKZedAl+IMpzwrzLs8 homelab-terraform-ansible",
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBogEzcV72H1vVmvC849JTMTFYguxVw5QKl4JX85fRj0 thundercat@windows-claude",
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJJbotLXtaqwLd2a8vYRCOO3YbpMgIuMevYKhz9NoHJ4 root@pve",
    ]
  }
  dns = {
    # Technitium DNS Server - DNS interno do lab (zona "lab", ex.: gitlab.lab,
    # backstage.lab), pre-requisito pro FQDN que o Uyuni vai precisar (ver
    # docs/hardening.md e a nota de planejamento do Uyuni). VM leve de proposito
    # - so serve resolucao pra frota, nada pesado.
    vm_id       = 2016
    ip          = "192.168.15.65/24"
    cores       = 4
    memory      = 4096
    disk        = 20
    on_boot     = true
    dns_servers = ["192.168.15.65", "192.168.15.1"]
    ssh_keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBO3BiGOxRN29Jfas+UGS0hV+JGKZedAl+IMpzwrzLs8 homelab-terraform-ansible",
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBogEzcV72H1vVmvC849JTMTFYguxVw5QKl4JX85fRj0 thundercat@windows-claude",
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJJbotLXtaqwLd2a8vYRCOO3YbpMgIuMevYKhz9NoHJ4 root@pve",
    ]
  }
  uyuni = {
    # Uyuni — concentra hardening (baseline) + patch management + relatorio
    # nativo de issues pra frota inteira, substituindo a tentativa via Ansible
    # devsec.hardening (revertida em 14 ago 2026, ver docs/armadilhas.md).
    # Base openSUSE Tumbleweed em vez do SL Micro 6.2 originalmente cogitado:
    # SL Micro exige conta + codigos de registro no SUSE Customer Center (SCC)
    # so pra baixar a imagem; Tumbleweed e a base community validada
    # oficialmente pelo projeto Uyuni desde a 2025.10, sem essa friccao.
    # Precisa de FQDN resolvivel (por isso o DNS interno - Technitium - veio
    # primeiro) e de bastante disco pro mirror de pacotes (200GB minimo
    # oficial) - por isso vai no datastore "DATA" (LVM comum, 2.7TB livres),
    # nao no local-lvm (thin pool ja mais apertado no resto da frota).
    vm_id = 2017
    ip    = "192.168.15.66/24"
    cores = 4
    # 16GB (minimo oficial) alarmou 100% de uso logo depois do install, com
    # os syncs de pacote ainda rodando - subido pro valor "recomendado pra
    # producao" da propria documentacao do Uyuni (19 ago 2026).
    memory         = 32768
    disk           = 200
    datastore_id   = "DATA"
    template_vm_id = 10018
    dns_servers    = ["192.168.15.65", "192.168.15.1"]
    ssh_keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBO3BiGOxRN29Jfas+UGS0hV+JGKZedAl+IMpzwrzLs8 homelab-terraform-ansible",
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBogEzcV72H1vVmvC849JTMTFYguxVw5QKl4JX85fRj0 thundercat@windows-claude",
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJJbotLXtaqwLd2a8vYRCOO3YbpMgIuMevYKhz9NoHJ4 root@pve",
    ]
  }
}

# Nota: os clusters Kubernetes (ArgoCD + Crossplane) vivem no projeto separado
# homelab-gitops, com state proprio. Ver github.com/marciotsdev/homelab-gitops.

# Trocado de 1001 (ISO manual, cloud-init quebrado) para 9000 (cloud image
# oficial, ide2 cloudinit real) em 2026-08-10. So afeta VMs criadas a partir
# de agora; as ja existentes (clonadas do 1001) ficam pra uma recriacao em
# lote planejada a parte. Ver docs/armadilhas.md.
template_vm_id = 9000
