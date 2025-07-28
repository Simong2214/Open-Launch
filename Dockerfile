FROM oven/bun:1 as builder

# add build arguments
ARG NODE_ENV

# Set minimal environment variables
ENV NODE_ENV=${NODE_ENV:-production}
ENV NEXT_PUBLIC_UPLOADTHING_URL=yxucdfr9f5.ufs.sh
ENV NEXT_PUBLIC_URL=https://open-launch.com

# Basic mock values needed for build only - not used in production
ENV BETTER_AUTH_SECRET=mock_secret_at_least_32_chars_long_for_build
ENV STRIPE_SECRET_KEY=sk_test_mockvalue
ENV RESEND_API_KEY=re_mockvalue
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
# Add this near the top of the second stage
ENV PORT=80

# Build the application
RUN NODE_OPTIONS="--max_old_space_size=4096" bun run build

# Production image
FROM oven/bun:1

WORKDIR /app

# Install Node.js 18 for ICU compatibility
RUN apt-get update && apt-get install -y nodejs npm curl && apt-get clean

# Copy built app from builder
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/bun.lockb ./bun.lockb
COPY --from=builder /app/next.config.ts ./next.config.ts
COPY --from=builder /app/mdx-components.tsx ./mdx-components.tsx
COPY --from=builder /app/middleware.ts ./middleware.ts
COPY --from=builder /app/scripts ./scripts
COPY --from=builder /app/drizzle ./drizzle

# Install production dependencies only
RUN bun install --production

# Expose port
EXPOSE 80

# Health check - using a simple path that doesn't require auth
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD curl -f http://localhost:80/ || exit 1

# Start command
CMD ["sh", "-c", "PORT=80 bun run start"]
