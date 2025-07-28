FROM oven/bun:1 as builder

# add build arguments
ARG NODE_ENV
ARG NEXT_PUBLIC_UPLOADTHING_URL

# Set environment variables
ENV NODE_ENV=${NODE_ENV:-production}
ENV NEXT_PUBLIC_UPLOADTHING_URL=${NEXT_PUBLIC_UPLOADTHING_URL:-yxucdfr9f5.ufs.sh}

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
