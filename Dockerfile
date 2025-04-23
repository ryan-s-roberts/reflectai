# ---- Stage 1: Builder ----
# Use a specific Node.js version (adjust as needed)
FROM node:20 AS builder

# Set working directory
WORKDIR /app

# Copy package files and install dependencies first to leverage Docker cache
COPY package.json package-lock.json ./
# Use npm ci for cleaner installs if package-lock.json is reliable
# RUN npm ci
RUN npm install

# Copy the rest of the application source code needed for build
COPY . .
# Alternatively, copy specific directories:
# COPY baml_src ./baml_src
# COPY src ./src
# COPY tsconfig.json ./tsconfig.json

# Build the application (generates BAML client and compiles TS)
# Ensure BAML generation happens before tsc
RUN npm run baml:build
# The main build script already runs baml:build, so just run build
RUN npm run build

# Optional: Prune dev dependencies for smaller node_modules copy later
# RUN npm prune --production


# ---- Stage 2: Runtime ----
# Use a smaller base image for the final stage - Using slim (glibc) instead of alpine (musl)
FROM node:20-slim

# Set working directory
WORKDIR /app

# Install base dependencies and CA certificates needed for HTTPS calls
# Running as root before copying app files
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy necessary files from the builder stage
COPY --from=builder /app/package.json /app/package-lock.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
# BAML client is generated inside src/ and compiled to dist/, so no need to copy src/baml_client separately

# Best practice: Run as non-root user
USER node

# Define the entry point for the CLI tool
ENTRYPOINT ["node", "dist/cli.js"]

# Default command (optional, can be used for --help or default action)
# CMD ["--help"] 