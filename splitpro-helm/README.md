# SplitPro Helm chart

Deploys [SplitPro](https://github.com/oss-apps/split-pro), an open source
Splitwise alternative, against an **external PostgreSQL database**. This chart
does not deploy or manage a database.

## Prerequisites

- Kubernetes 1.19+ (Ingress uses `networking.k8s.io/v1`).
- An external PostgreSQL reachable from the cluster.
- **pg_cron** installed on that database if you want recurring transactions.
- A pre-created Secret holding the sensitive environment variables.

## Secret

The chart never creates a Secret. Create one and point `existingSecret` at it.
Secret keys must match the environment variable names:

```bash
kubectl create secret generic splitpro-secrets \
  --from-literal=POSTGRES_PASSWORD='...' \
  --from-literal=NEXTAUTH_SECRET="$(openssl rand -base64 32)"
```

Optional secret keys, only needed for the providers you enable:
`EMAIL_SERVER_PASSWORD`, `GOCARDLESS_SECRET_ID`, `GOCARDLESS_SECRET_KEY`,
`PLAID_SECRET`, `GOOGLE_CLIENT_SECRET`, `AUTHENTIK_SECRET`, `KEYCLOAK_SECRET`,
`OIDC_CLIENT_SECRET`, `WEB_PUSH_PRIVATE_KEY`, `OPEN_EXCHANGE_RATES_APP_ID`,
`DISCORD_WEBHOOK_URL`.

## Install

```bash
helm install splitpro ./splitpro-helm \
  --namespace splitpro --create-namespace \
  --set existingSecret=splitpro-secrets \
  --set externalDatabase.host=postgres.example.com \
  --set config.NEXTAUTH_URL=https://splitpro.example.com
```

## Configuration

### `externalDatabase`

| Key | Description | Default |
| --- | --- | --- |
| `host` | Database host (required) | `""` |
| `port` | Database port | `5432` |
| `database` | Database name | `splitpro` |
| `user` | Database user | `postgres` |
| `parameters` | Query params appended to `DATABASE_URL`, e.g. `{sslmode: require}` | `{}` |

`DATABASE_URL` is composed at container runtime from `POSTGRES_HOST`,
`POSTGRES_PORT`, `POSTGRES_DB`, `POSTGRES_USER` and the `POSTGRES_PASSWORD`
secret key. The password is never rendered into the manifests.

### `config`

Non-secret variables rendered into a ConfigMap and injected with `envFrom`. Any
non-secret variable from SplitPro's `.env.example` can be added here. Only the
keys you set are rendered, so unconfigured optional providers stay disabled.

### Storage

`persistence.uploads` backs `/app/uploads` (receipt attachments). Use
`existingClaim` to reuse a PVC, or set `enabled: false` to use an `emptyDir`
(data is lost on restart).

### Ingress

Disabled by default. Enable and adapt for your controller:

```yaml
ingress:
  enabled: true
  className: traefik
  annotations: {}
  hosts:
    - host: splitpro.example.com
      paths:
        - path: /
          pathType: Prefix
  tls: []
```

### Placement

Use `nodeName` to pin the pod to a specific node, or the standard `nodeSelector`,
`affinity` and `tolerations` fields.

## Notes

- The image tag is pinned in `values.yaml` (`image.tag`).
- The chart renders a ConfigMap, and the Deployment has no per-replica state, so
  keep `replicaCount` at 1 while using the default `ReadWriteOnce` uploads volume.
