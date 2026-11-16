# Deployment

Current target: a VPS running Docker, behind a reverse proxy on the same host.
Other targets (Cloudflare Workers/Pages, Vercel, ...) go in their own
`deploy/<target>/` directory next to `deploy/docker/` when a project needs them.

## How it works

`.github/workflows/deploy-ssh-docker.yml`, on push to `release` / `release*`
(or manual dispatch):

1. Runs CI (`ci.yml`); deployment stops if any check fails.
2. Builds `deploy/docker/Dockerfile` (context: repo root) and pushes
   `ghcr.io/<owner>/<repo>:latest` and `:<commit-sha>` to GHCR.
3. Copies `deploy/docker/docker-compose.yml` to `SSH_DEPLOY_PATH` on the server.
4. Writes `.deploy.env` (pins `IMAGE` + `IMAGE_TAG` to the commit), pulls,
   runs `docker compose up -d --remove-orphans`, then waits up to 120 s for the
   container healthcheck. On failure it prints `ps` + logs and fails the job.

Deploys of the same repo are queued, never run in parallel.

## One-time setup

### GitHub

Create an environment named **`VPS`** (Settings -> Environments) with these secrets:

| Secret | Value |
|--------|-------|
| `SSH_HOST` | Server hostname or IP |
| `SSH_USERNAME` | SSH user (must be able to run `docker`) |
| `SSH_PRIVATE_KEY` | Private key for that user (use a deploy-only key) |
| `SSH_PORT` | Optional, defaults to 22 |
| `SSH_DEPLOY_PATH` | Absolute directory on the server, e.g. `/srv/<project>` |
| `GHCR_PAT` | Classic PAT with `read:packages`, used by the server to pull |

Optionally add a protection rule on `VPS` (required reviewer) to gate production.

### Server

1. Docker Engine with the Compose plugin.
2. `mkdir -p $SSH_DEPLOY_PATH` and create `$SSH_DEPLOY_PATH/.env` from
   `.env.example` with real values (the deploy fails if it is missing).
3. Choose an `APP_PORT` no other project on this host uses (`ss -ltn` to check)
   and set it in `.env`.
4. Point the reverse proxy at `127.0.0.1:$APP_PORT`, e.g. Caddy:

   ```caddyfile
   app.example.com {
       reverse_proxy 127.0.0.1:3000
   }
   ```

## Operations

All commands run in `$SSH_DEPLOY_PATH`. Always pass both env files so the
pinned image is used:

```sh
dc() { docker compose --env-file .env --env-file .deploy.env "$@"; }
dc ps
dc logs -f --tail 200
dc up -d            # apply .env changes (env_file is read at container create)
```

**Rollback** to an earlier commit (every deployed commit has its own tag):

```sh
sed -i "s/^IMAGE_TAG=.*/IMAGE_TAG=<old-sha>/" .deploy.env
dc pull && dc up -d
```

Or re-run the deploy workflow for an older commit on the `release` branch.

**Backup** the data volume (name = `<compose name>_<volume>`, see `docker volume ls`):

```sh
docker run --rm -v app_app-data:/data -v "$PWD":/backup alpine \
  tar czf /backup/data-$(date +%F).tgz -C /data .
```

Restore with the same command using `tar xzf` into an empty volume while the
app is stopped.
