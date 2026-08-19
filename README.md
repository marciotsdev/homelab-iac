# homelab-iac

Infrastructure-as-code for a CI/CD homelab running on a single Proxmox node. Terraform provisions the VMs; Ansible configures the delivery pipeline: **GitLab (git + CI) → GitLab Runners → AWX → Docker containers**, cataloged in **Backstage**.

> **CI migration (jul/2026):** Jenkins was retired and replaced by GitLab CE with two containerized runners. The Jenkins VM is preserved (powered off, untagged, its role gated behind a flag) and Gitea now acts as a legacy mirror. Day-2 operations (VM startup/shutdown pipelines) live in the in-lab `lab-ops` repo on GitLab.

## Architecture

```
                     ┌────────────┐
   developer ──────▶ │   GitLab   │  git server + CI (docker compose)
                     └─────┬──────┘
                           │ pipeline (.gitlab-ci.yml)
                           ▼
                     ┌────────────┐
                     │  Runners   │  runner-infra (shell) + runner-docker,
                     └─────┬──────┘  containers on a dedicated VM
                           │ triggers job template
                           ▼
                     ┌────────────┐
                     │ AWX (k3s)  │  orchestration
                     └─────┬──────┘
                           │ ansible-playbook deploy
                           ▼
                     ┌────────────┐
                     │ containers │  docker host, demo apps
                     └────────────┘

                     ┌────────────┐
                     │ Backstage  │  catalog/portal (behind Caddy TLS),
                     └────────────┘  reads catalog-info from GitLab

                     ┌────────────┐
                     │    ELK     │  observability (logs from the VMs above
                     └────────────┘  and from the k8s clusters in homelab-gitops)
```

## VMs

| Host | vmid | Role | Boot on host start |
|---|---|---|---|
| awx | 2001 | k3s + awx-operator — orchestrates deploys | no |
| gitea | 2003 | Git server — legacy mirror | **yes** |
| containers | 2004 | Docker host, deploy target | no |
| client | 2005 | Jump box, no services | no |
| backstage | 2006 | Developer portal / catalog (Caddy TLS) | no |
| localstack | 2007 | MiniStack (local AWS emulator) + StackPort UI | no |
| gitlab | 2008 | GitLab CE — git + CI (docker compose) | **yes** |
| gitlab-runners | 2009 | CI runners as containers (infra + docker) | **yes** |
| elk | 2014 | Elasticsearch + Logstash + Kibana — observability (docker compose) | no |
| ~~jenkins~~ | 2002 | retired — VM kept powered off, out of every routine | no |

VMs tagged `lab` participate in the startup/shutdown pipelines (dynamic inventory). Only the git + CI trio auto-starts with the host; everything else is powered on demand.

IPs are environment-specific and kept out of version control — see `ansible/group_vars/all/hosts.yml.example`, `ansible/inventory/hosts.ini.example`, and `terraform/terraform.tfvars.example`.

Most VMs are cloned from an `ubuntu-2204-template` via the [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox) Terraform provider; the GitLab VM comes from a manually built template (no cloud-init) — both cases are expressed in `terraform/vms.tf` through per-VM optional fields.

## Layout

- `terraform/` — VM provisioning (`vms.tf`, `variables.tf`, `outputs.tf`). Credentials come from `PROXMOX_VE_*` environment variables, never from files in this repo. Power state is managed by the lab's GitLab pipelines, not Terraform (`ignore_changes = [started, clone]`).
- `ansible/` — Configuration management. One role per service (`common`, `gitea`, `gitlab`, `gitlab_runners`, `ministack`, `containers`, `awx`, `backstage`, `caddy`, `elk`, and the retired `jenkins`). All admin passwords/tokens are generated with Ansible's `password`/`file` lookups against a local, git-ignored `secrets/` directory — nothing is hardcoded.

### Notes on the newer roles

- **`gitlab`** provisions GitLab CE from a plain Ubuntu VM (docker compose under `/opt/gitlab`), so a rebuild no longer depends on the hand-built template. The running instance predates the role and still lives under `/home/marcio/gitlab-docker-setup` — converging means re-provisioning VM 2008.
- **`gitlab_runners`** creates the runner tokens by delegating to the GitLab host and prints the infra runner's public key; that key must be authorized on the Proxmox host with `command="/usr/local/bin/lab-ops-dispatch.sh",restrict` so the startup/shutdown pipelines can run — the one deliberately manual step.
- **`caddy`** puts TLS in front of the Backstage VM (`tls internal`, since private IPs can't get a public certificate). This is not cosmetic: the Backstage frontend calls `crypto.randomUUID()`, which only exists in a secure context — served over plain HTTP the app dies on startup. Apply it alone with `ansible-playbook caddy-only.yml`.
- **`jenkins`** only runs with `-e enable_legacy_jenkins true`; otherwise a full `site.yml` would resurrect the retired pipeline (the `gitea` role still re-templates the sample-app Jenkinsfile).
- **`elk`** deploys [`docker-elk`](https://github.com/deviantony/docker-elk) (Elasticsearch + Logstash + Kibana) on its own VM. Elastic's auto-enabled 30-day trial license is disabled in favor of `basic` (non-expiring, no native OIDC SSO); Keycloak SSO for Kibana is planned via `oauth2-proxy` sitting in front of it, not yet wired up. TLS (Caddy) and the Filebeat rollout to the other VMs/k8s clusters are later phases.

## Usage

Copy the `.example` files below and fill in your own network details — the real copies are git-ignored:

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
cp ansible/inventory/hosts.ini.example ansible/inventory/hosts.ini
cp ansible/group_vars/all/hosts.yml.example ansible/group_vars/all/hosts.yml
```
