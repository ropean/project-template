# CLAUDE.md

Guidance for AI coding assistants (Claude Code and others via `AGENTS.md`)
working in this repository.

> This repo started from `ropean/projects-template`. If the
> [New project checklist](#new-project-checklist) below still has open items,
> finish them before feature work, then delete the checklist section.

## Language

- **Everything committed to the repo is in English**: code, identifiers,
  comments, commit messages, PR titles/descriptions, docs, log and error messages.
- User-facing UI text may be localized; keep it in resource/i18n files, not
  inline in logic.
- Chat replies to the user can be in the user's language. This rule is
  about repository content only.

## Formatting and checks

- `.editorconfig` defines indentation, charset, LF line endings, final newline,
  and trailing-whitespace rules. Follow it in every file you write.
- `.gitattributes` forces LF in the repo (CRLF only for `*.bat`, `*.cmd`, `*.ps1`).
- `scripts/check.sh` is the single entry point for all checks. The pre-commit
  hook runs it on staged files, and CI runs it on the whole repo. When adding a
  stack-specific tool (linter, formatter, type checker, tests), wire it into
  section 2 of that script so local and CI stay identical.
- Enable the hook once per clone: `git config core.hooksPath .githooks`.
- Run `scripts/check.sh` before every commit. Never bypass the hook with
  `--no-verify`. Fix the cause instead.

### Stack conventions

**Node / TypeScript**
- Lint with **oxlint** and format with **oxfmt** (oxc). Do not add ESLint or Prettier.
- Package manager: pnpm (`packageManager` field pinned in `package.json`),
  with a Node version file (`.nvmrc`).
- Required `package.json` scripts:

  ```json
  "lint": "oxlint .",
  "format": "oxfmt --write .",
  "format:check": "oxfmt --check .",
  "check": "pnpm run lint && pnpm run format:check && pnpm run type:check && pnpm run test",
  "prepare": "git config core.hooksPath .githooks || true"
  ```

  Then call `run_step "check" pnpm run check` in `scripts/check.sh` and
  add the Node setup steps in `.github/workflows/ci.yml`.
- Pin exact dependency versions.

Other stacks: use the ecosystem's standard formatter and linter (e.g. ruff for
Python, gofmt + go vet for Go, rustfmt + clippy for Rust) and wire them in the same way.

## Secrets and configuration

- Never commit secrets. `.env` and `.env.*` are git-ignored; `.env.example` is
  the documented, committed list of every variable the app reads. Update it
  whenever you add or rename a variable.
- Configuration comes from environment variables. No hard-coded hosts, ports,
  or credentials.
- Never print secrets in logs, CI output, or the deploy summary.

## Authentication (SSO / OIDC)

If the project needs user sign-in or service-to-service auth, read
`docs/integrations/sso-oidc.md` and the documents it links before writing code.
Do not invent a different auth scheme.

## Deployment

VPS + Docker via GitHub Actions; push to `release` to deploy. Details:
`docs/deployment.md`. Files: `deploy/docker/` and
`.github/workflows/deploy-ssh-docker.yml`. New deployment targets go in their
own `deploy/<target>/` directory.

Runtime conventions: serve `GET /healthz` returning 200, log to stdout/stderr,
keep persistent state under `/data`, and run as a non-root user in the container.

## Git

- `main` is the default branch; `release` triggers production deploys.
- Commit messages follow Conventional Commits (`feat:`, `fix:`, `docs:`,
  `chore:`, `refactor:`, `test:`, `ci:`), in English and in the imperative mood.

## License

No `LICENSE` file is committed by default. Decide when the project's visibility is known:
- **Public repo**: add an MIT `LICENSE` with the owner's name and year.
- **Private repo**: add a proprietary notice (`Copyright (c) <year> <owner>. All rights reserved.`)
  and set `"license": "UNLICENSED"` / `"private": true` in package manifests.

## New project checklist

Work through this after creating a repo from the template, then delete this section.

- [ ] Rewrite `README.md` for this project (purpose, local setup, commands).
- [ ] Replace this file's intro with a short project overview: stack, layout, commands.
- [ ] Pick the stack; add its tooling and wire it into `scripts/check.sh` and `ci.yml`.
- [ ] Add the stack's ecosystem to `.github/dependabot.yml`.
- [ ] Write `deploy/docker/Dockerfile` (placeholder fails on purpose).
- [ ] In `deploy/docker/docker-compose.yml`: rename `name`, service, and volume;
      set the container port and healthcheck.
- [ ] Choose a unique `APP_PORT` for the server and update `.env.example`.
- [ ] Add a `LICENSE` per the rules above.
- [ ] If auth is needed, follow `docs/integrations/sso-oidc.md`.
