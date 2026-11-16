# SSO / OIDC integration

Projects that need sign-in use the shared identity provider. The specs live
with the IdP and the client library; this repo only links to them so they
never drift. Read the relevant document in full before writing any auth code.

| Document | Read it when |
|----------|--------------|
| [IdP integration guide](https://sso.ropean.org/docs/integration-guide.md) | Registering the app as an OAuth client, choosing scopes, reading token claims, setting up machine-to-machine access, handling IdP errors. |
| [Client SSO flow](https://sc.ropean.org/docs/sso-flow.md) | Implementing the app side: `/auth/*` routes, session storage, token refresh, logout, configuration variables. |

## Rules

- Node / Workers projects: use the client library described in the client SSO
  flow document instead of hand-rolling the protocol.
- Other stacks: implement the same flow and route layout as the client
  document so every project behaves the same (`ropean/file-box` is a PHP
  reference implementation).
- Add every new variable to `.env.example` with a comment; real secrets go in
  `.env` locally and in the server's `.env` (see `docs/deployment.md`).
