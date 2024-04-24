ARG CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX=docker.io
FROM ${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}/node:20-slim as base

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN corepack enable
RUN \
  apt-get update && \
  apt-get install python3 build-essential -y && \
  rm -rf /var/lib/apt/lists/*

COPY . /app
WORKDIR /app

RUN \
  corepack prepare pnpm@9.0.6 --activate && \
  pnpm install && \
  pnpm build && \
  npm pack

FROM ${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}/renovate/renovate:37.321.0
USER 0
COPY --from=base /app/renovate-0.0.0-semantic-release.tgz /renovate-0.0.0-semantic-release.tgz
RUN npm install --prefix /opt/containerbase/tools/renovate/37.321.0/ /renovate-0.0.0-semantic-release.tgz

RUN renovate --version

# run as the 1001 user as that is the user id we need to use so that gitlab
# caching works
# https://docs.appian-stratus.io/stratus/gitlab/gitlab-runners.html#set-the-user-to-root-or-1001-if-you-use-gitlab-caching-optional-based-on-usage
USER 1001
