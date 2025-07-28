FROM oven/bun:1 as builder

# add build arguments
ARG NODE_ENV

# Set minimal environment variables
ENV NODE_ENV=${NODE_ENV:-production}
ENV NEXT_PUBLIC_UPLOADTHING_URL=yxucdfr9f5.ufs.sh
ENV NEXT_PUBLIC_URL=https://open-launch.com
ENV BETTER_AUTH_SECRET=mock_secret_at_least_32_chars_long_for_build
ENV DATABASE_URL=mock_db_url

WORKDIR /app

# Install Node.js 18 for compatibility with ICU library
RUN apt-get update && apt-get install -y nodejs npm && apt-get clean

# Copy package files
COPY package.json bun.lockb ./

# Install dependencies
RUN bun install --frozen-lockfile

# Copy the rest of the app
COPY . .

# Skip tests and checks during build
ENV NEXT_TELEMETRY_DISABLED=1
ENV NEXT_SKIP_TYPE_CHECK=1
ENV NEXT_SKIP_LINT=1
ENV PORT=80

# Build the application
RUN NODE_OPTIONS="--max_old_space_size=4096" bun run build

# Production image
FROM oven/bun:1

WORKDIR /app

# Install Node.js 18 for ICU compatibility
RUN apt-get update && apt-get install -y nodejs npm curl postgresql-client && apt-get clean

# Copy everything needed
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/bun.lockb ./bun.lockb
COPY --from=builder /app/next.config.ts ./next.config.ts
COPY --from=builder /app/drizzle ./drizzle
COPY --from=builder /app/scripts ./scripts
COPY --from=builder /app/src ./src
COPY --from=builder /app/tsconfig.json ./tsconfig.json
COPY --from=builder /app/drizzle.config.ts ./drizzle.config.ts

# Install production dependencies only
RUN bun install --production

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD curl -f http://localhost:80/ || exit 1

# Start command
CMD ["sh", "-c", "PORT=80 bun run start"]
