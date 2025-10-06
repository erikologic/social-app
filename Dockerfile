FROM node:20-bullseye AS web-builder

WORKDIR /usr/src/social-app

# Copy only dependency files first (better cache utilization)
COPY package.json yarn.lock ./
COPY patches ./patches
COPY lingui.config.js ./

RUN echo "network-timeout 600000" >> .yarnrc && \
  echo "registry \"https://registry.yarnpkg.com\"" >> .yarnrc

# Install dependencies - skip scripts for speed, run manually after
RUN --mount=type=cache,target=/usr/local/share/.cache/yarn/v6 \
  yarn install --frozen-lockfile --ignore-scripts --prefer-offline --network-timeout 600000 --network-concurrency 16

# Copy source code (separate layer)
COPY . .

# Run only essential postinstall tasks manually
RUN yarn patch-package || true

# Build (cached unless source changes)
RUN --mount=type=cache,target=/usr/local/share/.cache/yarn/v6 \
  --mount=type=cache,target=/root/.cache \
  --mount=type=cache,target=/usr/src/social-app/node_modules/.cache \
  --mount=type=cache,target=/usr/src/social-app/.expo \
  yarn intl:build && yarn build-web

FROM golang:1.24.5-bullseye AS go-builder

WORKDIR /usr/src/social-app

ENV GODEBUG="netdns=go"
ENV CGO_ENABLED=1
ENV GOEXPERIMENT="loopvar"

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
    -trimpath \
    -tags timetzdata \
    -ldflags="-s -w" \
    -o /bskyweb \
    ./cmd/bskyweb

FROM debian:bullseye-slim

ENV GODEBUG=netdns=go \
    TZ=Etc/UTC

RUN apt-get update && apt-get install --yes --no-install-recommends \
  dumb-init \
  ca-certificates \
  && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["dumb-init", "--"]

WORKDIR /bskyweb
COPY --from=go-builder /bskyweb /usr/bin/bskyweb
COPY --from=web-builder /usr/src/social-app/bskyweb/static ./static
COPY --from=web-builder /usr/src/social-app/bskyweb/templates ./templates
COPY --from=web-builder /usr/src/social-app/bskyweb/embedr-static ./embedr-static
COPY --from=web-builder /usr/src/social-app/bskyweb/embedr-templates ./embedr-templates
COPY --from=web-builder /usr/src/social-app/web-build ./web-build

CMD ["/usr/bin/bskyweb"]

LABEL org.opencontainers.image.source=https://github.com/bluesky-social/social-app
LABEL org.opencontainers.image.description="bsky.app Web App"
LABEL org.opencontainers.image.licenses=MIT
