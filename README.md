# homelab-iac

Infrastructure-as-code for a CI/CD homelab running on a single Proxmox node. Terraform provisions six VMs; Ansible configures a full delivery pipeline: **Gitea → Jenkins → AWX → Docker containers**, cataloged in **Backstage**.

## Architecture

```
                     ┌────────────┐
   developer ──────▶ │   Gitea    │  git server, origin of the pipeline
                     └─────┬──────┘
                           │ webhook / push
                           ▼
                     ┌────────────┐
                     │  Jenkins   │  CI build
                     └─────┬──────┘
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
                     │ Backstage  │  catalog/portal, reads Gitea + Jenkins
                     └────────────┘
```

## VMs

| Host | Role |
|---|---|
| awx | k3s + awx-operator — orchestrates deploys |
| jenkins | CI build server |
| gitea | Git server, seeds a `sample-app` demo repo |
| containers | Docker host, deploy target |
| client | Jump box, no services |
| backstage | Developer portal / catalog |

IPs are environment-specific and kept out of version control — see `ansible/group_vars/all/hosts.yml.example`, `ansible/inventory/hosts.ini.example`, and `terraform/terraform.tfvars.example`.

All VMs are cloned from an `ubuntu-2204-template` via the [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox) Terraform provider, then configured by `ansible/site.yml`.

## Layout

- `terraform/` — VM provisioning (`vms.tf`, `variables.tf`, `outputs.tf`). Credentials come from `PROXMOX_VE_*` environment variables, never from files in this repo.
- `ansible/` — Configuration management. One role per service (`awx`, `jenkins`, `gitea`, `containers`, `backstage`, `common`). All admin passwords/tokens are generated with Ansible's `password`/`file` lookups against a local, git-ignored `secrets/` directory — nothing is hardcoded.

## Usage

Copy the `.example` files below and fill in your own network details — the real copies are git-ignored:

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
cp ansible/inventory/hosts.ini.example ansible/inventory/hosts.ini
cp ansible/group_vars/all/hosts.yml.example ansible/group_vars/all/hosts.yml
```

Then provision and configure:

```bash
cd terraform
terraform init
terraform apply

cd ../ansible
ansible-playbook site.yml
```

Also requires a `secrets/` directory (git-ignored) alongside `ansible/` and `terraform/` for generated credentials, and an SSH key pair at the path set in `ssh_private_key_path` (`ansible/group_vars/all/main.yml`) and `ssh_public_key_path` (`terraform.tfvars`).
