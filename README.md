# projects-template

Language-agnostic starting point for new projects. Create a repo from this
template, then let your AI assistant work through the **New project checklist**
in [CLAUDE.md](CLAUDE.md).

## What's included

| Path | Purpose |
|------|---------|
| `.gitignore` | OS (macOS/Windows/Linux), editors/IDEs, AI tools, secrets, common toolchains |
| `.gitattributes` | LF line endings everywhere, binary file types, generated lockfiles |
| `.editorconfig` | Charset, indentation, final newline, trailing whitespace |
| `scripts/check.sh` | One check entry point for the git hook and CI; stack tools plug in here |
| `.githooks/pre-commit` | Runs `scripts/check.sh --staged` (`git config core.hooksPath .githooks`) |
| `.github/workflows/ci.yml` | Runs `scripts/check.sh` + gitleaks secret scan |
| `.github/workflows/deploy-ssh-docker.yml` | `release` branch -> GHCR image -> VPS via SSH + Docker Compose |
| `deploy/docker/` | Dockerfile (placeholder) and production compose file |
| `.github/dependabot.yml` | Monthly updates for Actions and the base image |
| `CLAUDE.md` / `AGENTS.md` | Rules for AI assistants: English-only repo content, checks, secrets, deploy, license |
| `docs/deployment.md` | Secrets, server setup, rollback, backups |
| `docs/integrations/sso-oidc.md` | Links to the SSO / OIDC integration docs |

## Using the template

1. On GitHub: **Use this template -> Create a new repository**
   (mark this repo as a template under Settings -> General once).
2. Clone it and run `git config core.hooksPath .githooks`.
3. Ask the AI assistant to complete the checklist in `CLAUDE.md`.
