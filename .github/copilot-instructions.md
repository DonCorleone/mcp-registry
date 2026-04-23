# Copilot Instructions for MCP Registry

## Company-internal usage

This fork is used as a **company-internal MCP server whitelist** for GitHub Enterprise. Only servers listed in `data/seed.json` are approved for use.

### What this repo does

The registry exposes a REST API (`/v0/servers`) that GitHub Enterprise reads to show users which MCP servers are approved.

### How to update the whitelist

In OpenShift: `deploy/openshift/configmap.yaml` editieren → `oc apply` → Pod neu starten (siehe unten).

#### Remote HTTP server (e.g. Figma):
```json
{
  "$schema": "https://static.modelcontextprotocol.io/schemas/2025-12-11/server.schema.json",
  "name": "com.vendor/server-name",
  "title": "Display Name",
  "description": "Short description.",
  "version": "1.0.0",
  "remotes": [
    {
      "type": "streamable-http",
      "url": "https://mcp.example.com/mcp"
    }
  ]
}
```

#### Installable server (e.g. npm):
```json
{
  "$schema": "https://static.modelcontextprotocol.io/schemas/2025-12-11/server.schema.json",
  "name": "io.github.username/server-name",
  "title": "Display Name",
  "description": "Short description.",
  "version": "1.2.3",
  "packages": [
    {
      "registryType": "npm",
      "identifier": "package-name",
      "version": "1.2.3",
      "runtimeHint": "npx",
      "transport": { "type": "stdio" }
    }
  ]
}
```

Key rules:
- Transport type in the registry schema is `streamable-http` (not `http` as used in VS Code config)
- `version` must be exact semver — no `^`, `~`, `latest`
- Removing an entry from `seed.json` does **not** delete it from the DB — a DB reset is required

### Key files

| File | Purpose |
|---|---|
| `deploy/openshift/configmap.yaml` | Whitelist (seed.json) als Kubernetes ConfigMap — hier Server hinzufügen/entfernen |
| `deploy/openshift/secret.yaml` | DB URL + JWT key — **never commit with real values** |
| `deploy/openshift/deployment.yaml` | Kubernetes Deployment — `image:` anpassen auf interne Registry |
| `deploy/openshift/service.yaml` | Kubernetes Service |
| `deploy/openshift/route.yaml` | OpenShift Route (externe URL + TLS) |
| `deploy/openshift/apply.ps1` | PowerShell deploy script |
| `Dockerfile` | Multi-stage Go build, läuft als non-root (OpenShift-kompatibel) |

### OpenShift deployment (production)

```powershell
# 1. secret.yaml mit echten Werten befüllen (DB URL + JWT Key)
# JWT Key generieren: openssl rand -hex 32

# 2. Image bauen und pushen
docker build -t your-registry.company.com/mcp-registry:latest .
docker push your-registry.company.com/mcp-registry:latest

# 3. In deployment.yaml: image: anpassen

# 4. Deployen
cd deploy/openshift
.\apply.ps1
```

Whitelist-Update in Production:
```powershell
# configmap.yaml editieren, dann:
oc apply -f configmap.yaml
oc rollout restart deployment/mcp-registry -n mcp-registry
```

### Security rules

- **Never commit real secrets** — `secret.yaml` enthält DB-Credentials und JWT-Key
- JWT Key generieren mit: `openssl rand -hex 32`