# syntax=docker/dockerfile:1

# ── deps: install all deps (incl. dev) + toolchain for the native addon ──
FROM node:22 AS deps
WORKDIR /app
# Build deps for better-sqlite3's native module (used if no prebuilt binary).
RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 make g++ \
    && rm -rf /var/lib/apt/lists/*
COPY package.json package-lock.json ./
RUN npm ci

# ── builder: compile Next into a standalone bundle ──
FROM node:22 AS builder
WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED=1
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

# ── runner: minimal production image ──
FROM node:22-slim AS runner
WORKDIR /app
ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    HOSTNAME=0.0.0.0 \
    PORT=3000

# Standalone server + only the node_modules it actually traced.
COPY --from=builder /app/.next/standalone ./
# Static assets and public/ are not part of standalone — copy them explicitly.
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public
# Safety net: ensure the better-sqlite3 native binary is present at runtime.
COPY --from=builder /app/node_modules/better-sqlite3 ./node_modules/better-sqlite3

EXPOSE 3000

# The DB lives in /app/data (mounted volume); cwd stays /app so paths resolve.
CMD ["node", "server.js"]
