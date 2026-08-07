terraform {
  # Backend HTTP nativo do GitLab (Terraform state management) - compartilhado
  # entre a maquina de controle e o runner do GitLab CI. Sem isso, um runner
  # efemero nao teria visibilidade das VMs que ja existem, arriscando recriar
  # tudo num apply automatizado.
  #
  # address/lock/unlock ficam aqui porque nao sao segredo (so a URL do
  # projeto). username/password (PAT local ou CI_JOB_TOKEN no pipeline) sao
  # passados via -backend-config na hora do "terraform init" - nunca
  # versionados.
  backend "http" {
    address        = "http://192.168.15.57:8088/api/v4/projects/4/terraform/state/infra-base"
    lock_address   = "http://192.168.15.57:8088/api/v4/projects/4/terraform/state/infra-base/lock"
    unlock_address = "http://192.168.15.57:8088/api/v4/projects/4/terraform/state/infra-base/lock"
    lock_method    = "POST"
    unlock_method  = "DELETE"
    retry_wait_min = 5
  }
}
