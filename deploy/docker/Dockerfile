# syntax=docker/dockerfile:1
#
# TODO(new project): replace this placeholder with the real image.
# Build context is the repo root (see .dockerignore), so paths below are
# relative to the repo root, not to this directory.
#
# Conventions every image should follow:
#   - Multi-stage: build tools stay in the builder stage, not in the final image.
#   - Run the app as a non-root user.
#   - Listen on the port published in docker-compose.yml (3000 by default).
#   - Serve GET /healthz -> 200 (used by the compose healthcheck and the deploy job).
#   - Persist state only under /data (a named volume); log to stdout/stderr.
#   - Read configuration from environment variables (.env on the server).

FROM alpine:3.24
RUN echo "deploy/docker/Dockerfile is still the template placeholder." >&2 && exit 1
