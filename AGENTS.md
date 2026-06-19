# AGENTS.md — Podman Stacks

## Project overview

Homelab infrastructure-as-code: declarative configs for self-hosted services running on Podman (Docker Compose) and K3s (Kubernetes). No application source code — pure YAML configuration.

## Repo structure

```
├── <service>               # Active Docker Compose stack (docker-compose.yml/yaml)
├── <service>-k8s/          # Active K3s manifests (deployment, service, ingress, pvc)
├── cf-router/              # Cloudflare Tunnel DaemonSet (K8s)
├── nextcloud/              # K8s CRDs: db/ (CNPG), cache/ (Dragonfly)
├── dragonfly-operator/     # DragonflyDB operator manifest
├── heatwave-db-exporter/   # K8s CronJob for MySQL backups
├── deprecated/             # Stacks no longer in use
└── renovate.json           # Dependency update automation
```

## Conventions

- **Directories**: lowercase, hyphen-separated (`audiobookshelf-k8s`, `heatwave-db-exporter`).
- **Compose files**: `docker-compose.yml` or `docker-compose.yaml` (both coexist).
- **K8s files**: `{service}-{resource-type}.yaml` (e.g. `memos-service.yaml`, `vikunja-deployment.yaml`).
- **Image tags**: pinned to specific versions, never `:latest`. Renovate manages bumps.
- **Environment variables**: `${VAR:-default}` for optional, `${VAR:?error}` for required. Secrets live outside the repo.
- **Cloudflare Tunnel**: sidecar `cloudflared` container with `TUNNEL_TOKEN` for services needing web ingress.
- **K8s node pinning**: `spec.template.spec.nodeName` pins pods to specific nodes (`whisperforge`, `bigman`, `oilstock`, `debianman`).
- **DNS domain**: `klingelstaender.uk` for ingress hostnames.
- **YAML style**: 2-space indentation, `---` separators in multi-doc K8s files.
- **Labels**: K8s manifests use `io.kompose.service` labels (kompose-converted).
- **Health checks**: `pg_isready`, `healthcheck.sh`, `redis-cli ping` patterns in compose.

## Automation

- **Renovate** (`renovate.json`): auto-updates container image tags for both `docker-compose` and `kubernetes` managers. Ignores `deprecated/**`. Groups updates by parent directory. Auto-merges patch updates for non-database images. Pins PostgreSQL <17, MariaDB <12, MySQL <10, MongoDB <5, Memcached <2.

## Common operations

- Add a new Compose stack: create `{name}/docker-compose.yml` with pinned images, env vars, health checks.
- Add a new K8s stack: create `{name}-k8s/` with deployment + service + (ingress + pvc if needed). Use existing stacks as templates.
- Deprecate a stack: move to `deprecated/{name}/`, no code changes needed.
- Update an image version: let Renovate do it, or manually bump the tag in the compose/k8s file.
- Validate YAML: `yamllint` or `podman compose config` / `kubectl apply --dry-run=client`.
- Deploy compose: `podman compose -f <dir>/docker-compose.yml up -d`.
- Deploy K8s: `kubectl apply -f <dir>/`.

## Reminders for AI agents

- This is a **declarative config repo** — don't write application code or scripts unless asked.
- All images are **pinned** — never introduce `:latest`.
- Keep **secrets** out of the repo — always use `${VAR:?}` or `secretKeyRef`.
- Follow existing **naming/file patterns** when adding new stacks.
- When deprecating, **move to `deprecated/`** — don't delete configs.
- `renovate.json` is the only automation — don't add CI or scripts unless requested.
- The K8s manifests were **kompose-converted** and may retain annotations from that process.
