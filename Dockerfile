FROM oven/bun:1 as builder

# add build arguments
ARG NODE_ENV
ARG NEXT_PUBLIC_UPLOADTHING_URL

# Set environment variables
ENV NODE_ENV=${NODE_ENV:-production}
ENV NEXT_PUBLIC_UPLOADTHING_URL=${NEXT_PUBLIC_UPLOADTHING_URL:-yxucdfr9f5.ufs.sh}

# Mock environment variables for build time only
# These are placeholder values for build process - not real credentials
ENV STRIPE_SECRET_KEY=sk_test_mockbuildvalue
ENV RESEND_API_KEY=re_mockbuildvalue
ENV STRIPE_WEBHOOK_SECRET=whsec_mockbuildvalue
ENV GOOGLE_CLIENT_SECRET=mock_secret
ENV GITHUB_CLIENT_SECRET=mock_secret
ENV TURNSTILE_SECRET_KEY=mock_secret
ENV DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/mock
ENV DISCORD_LAUNCH_WEBHOOK_URL=https://discord.com/api/webhooks/mock
ENV UPLOADTHING_TOKEN=mock_token
ENV PLAUSIBLE_API_KEY=mock_key
ENV PLAUSIBLE_URL=https://plausible.io
ENV PLAUSIBLE_SITE_ID=mock_site
ENV CRON_API_KEY=mock_key
ENV BETTER_AUTH_SECRET=mock_secret_at_least_32_chars_long_for_build
ENV BETTER_AUTH_URL=https://example.com

WORKDIR /app

# Install Node.js 18 for compatibility with ICU library
RUN apt-get update && apt-get install -y nodejs npm && apt-get clean

# Copy package files
COPY package.json bun.lockb ./

# Install dependencies
RUN bun install --frozen-lockfile

# Copy the rest of the app
COPY . .

# Build the application
RUN bun run build

# Production image
FROM oven/bun:1

WORKDIR /app

# Install Node.js 18 for ICU compatibility
RUN apt-get update && apt-get install -y nodejs npm && apt-get clean

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
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD [ "curl", "-f", "http://localhost:3000/health" ]

# Start command
CMD ["bun", "run", "start"]
