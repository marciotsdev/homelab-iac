# homelab-iac

Infrastructure-as-code for a CI/CD homelab running on a single Proxmox node. Terraform provisions the VMs; Ansible configures the delivery pipeline: **GitLab (git + CI) → GitLab Runners → AWX → Docker containers**, cataloged in **Backstage**.

> **CI migration (jul/2026):** Jenkins was retired and replaced by GitLab CE with two containerized runners. The Jenkins VM is preserved (powered off, no tags) and Gitea now acts as a legacy mirror. Day-2 operations (VM startup/shutdown pipelines) live in the in-lab `lab-ops` repo on GitLab.

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
```

## VMs

| Host | vmid | Role | Boot on host start |
|---|---|---|---|
| awx | 2001 | k3s + awx-operator — orchestrates deploys | no |
| jenkins | 2002 | *retired* (former CI, preserved) | no |
| gitea | 2003 | Git server — legacy mirror | **yes** |
| containers | 2004 | Docker host, deploy target | no |
| client | 2005 | Jump box, no services | no |
| backstage | 2006 | Developer portal / catalog (Caddy TLS) | no |
| localstack | 2007 | MiniStack (local AWS emulator) + StackPort UI | no |
| gitlab | 2008 | GitLab CE — git + CI (docker compose) | **yes** |
| gitlab-runners | 2009 | CI runners as containers (infra + docker) | **yes** |

VMs tagged `lab` participate in the startup/shutdown pipelines (dynamic inventory). Only the git + CI trio auto-starts with the host; everything else is powered on demand.

IPs are environment-specific and kept out of version control — see `ansible/group_vars/all/hosts.yml.example`, `ansible/inventory/hosts.ini.example`, and `terraform/terraform.tfvars.example`.

Most VMs are cloned from an `ubuntu-2204-template` via the [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox) Terraform provider; the GitLab VM comes from a manually built template (no cloud-init) — both cases are expressed in `terraform/vms.tf` through per-VM optional fields.

## Layout

- `terraform/` — VM provisioning (`vms.tf`, `variables.tf`, `outputs.tf`). Credentials come from `PROXMOX_VE_*` environment variables, never from files in this repo. Power state is managed by the lab's GitLab pipelines, not Terraform (`ignore_changes = [started, clone]`).
- `ansible/` — Configuration management. One role per service (`awx`, `jenkins`, `gitea`, `containers`, `backstage`, `common`). All admin passwords/tokens are generated with Ansible's `password`/`file` lookups against a local, git-ignored `secrets/` directory — nothing is hardcoded.

> **Roadmap:** Ansible roles for the GitLab stack (server, runners, Caddy TLS on Backstage, MiniStack) are not yet written — those services were configured in place. Until then, re-running `site.yml` re-applies the *legacy* pipeline config (it re-templates the sample-app Jenkinsfile); prefer targeted role runs.

## Usage

Copy the `.example` files below and fill in your own network details — the real copies are git-ignored:

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
cp ansible/inventory/hosts.ini.example ansible/inventory/hosts.ini
cp ansible/group_vars/all/hosts.yml.example ansible/group_vars/all/hosts.yml
```
