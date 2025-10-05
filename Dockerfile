FROM golang:1.24.5-bullseye AS build-env

WORKDIR /usr/src/social-app

ENV DEBIAN_FRONTEND=noninteractive

#
# Node
#
ENV NODE_VERSION=20
ENV NVM_DIR=/usr/share/nvm

#
# Go
#
ENV GODEBUG="netdns=go"
# ENV GOOS="linux"
# ENV GOARCH="amd64"
ENV CGO_ENABLED=1
ENV GOEXPERIMENT="loopvar"

# The latest git hash of the preview branch on render.com
# https://render.com/docs/docker-secrets#environment-variables-in-docker-builds
# ARG RENDER_GIT_COMMIT

#
# Expo
#
# ARG EXPO_PUBLIC_ENV
# ENV EXPO_PUBLIC_ENV=${EXPO_PUBLIC_ENV:-development}
# ARG EXPO_PUBLIC_RELEASE_VERSION
# ENV EXPO_PUBLIC_RELEASE_VERSION=$EXPO_PUBLIC_RELEASE_VERSION
# ARG EXPO_PUBLIC_BUNDLE_IDENTIFIER
# # If not set by GitHub workflows, we're probably in Render
# ENV EXPO_PUBLIC_BUNDLE_IDENTIFIER=${EXPO_PUBLIC_BUNDLE_IDENTIFIER:-$RENDER_GIT_COMMIT}

#
# Sentry
#
# ARG SENTRY_AUTH_TOKEN
# ENV SENTRY_AUTH_TOKEN=${SENTRY_AUTH_TOKEN:-unknown}
# ARG EXPO_PUBLIC_SENTRY_DSN
# ENV EXPO_PUBLIC_SENTRY_DSN=$EXPO_PUBLIC_SENTRY_DSN


#
# Generate the JavaScript webpack.
#
RUN --mount=type=cache,target=/tmp/nvm-cache \
  mkdir --parents $NVM_DIR && \
  wget \
    --output-document=/tmp/nvm-install.sh \
    https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh && \
  bash /tmp/nvm-install.sh

RUN --mount=type=cache,target=/root/.nvm/.cache \
  \. "$NVM_DIR/nvm.sh" && \
  nvm install $NODE_VERSION && \
  nvm use $NODE_VERSION && \
  npm install --global yarn

COPY . .

RUN echo "network-timeout 600000" >> .yarnrc && \
  echo "registry \"https://registry.yarnpkg.com\"" >> .yarnrc

RUN --mount=type=cache,target=/root/.yarn/berry/cache \
  --mount=type=cache,target=/root/.cache/yarn \
  . "$NVM_DIR/nvm.sh" && nvm use $NODE_VERSION && yarn install --network-timeout 600000 --network-concurrency 8

RUN --mount=type=cache,target=/root/.yarn/berry/cache \
  --mount=type=cache,target=/root/.cache \
  --mount=type=cache,target=/usr/src/social-app/node_modules/.cache \
  --mount=type=cache,target=/usr/src/social-app/.expo \
  . "$NVM_DIR/nvm.sh" && nvm use $NODE_VERSION && \
  yarn intl:build 2>&1 | tee i18n.log && \
  if grep -q "invalid syntax" "i18n.log"; then echo "\n\nFound compilation errors!\n\n" && exit 1; else echo "\n\nNo compile errors!\n\n"; fi && \
  yarn build-web

# DEBUG
RUN find ./bskyweb/static && find ./web-build/static

#
# Generate the bskyweb Go binary.
#
COPY bskyweb/go.mod bskyweb/go.sum ./bskyweb/

RUN --mount=type=cache,target=/go/pkg/mod \
  cd bskyweb/ && \
  go mod download && \
  go mod verify

COPY bskyweb/ ./bskyweb/

RUN --mount=type=cache,target=/go/pkg/mod \
  --mount=type=cache,target=/root/.cache/go-build \
  cd bskyweb/ && \
  go build \
    -x \
    -v  \
    -trimpath \
    -tags timetzdata \
    -o /bskyweb \
    ./cmd/bskyweb

FROM debian:bullseye-slim

ENV GODEBUG=netdns=go
ENV TZ=Etc/UTC
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install --yes \
  dumb-init \
  ca-certificates

ENTRYPOINT ["dumb-init", "--"]

WORKDIR /bskyweb
COPY --from=build-env /bskyweb /usr/bin/bskyweb

CMD ["/usr/bin/bskyweb"]

LABEL org.opencontainers.image.source=https://github.com/bluesky-social/social-app
LABEL org.opencontainers.image.description="bsky.app Web App"
LABEL org.opencontainers.image.licenses=MIT

# NOOP
