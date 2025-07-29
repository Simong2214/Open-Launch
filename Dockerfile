FROM oven/bun:1 as builder

WORKDIR /app

# Install Node.js and essential tools
RUN apt-get update && apt-get install -y nodejs npm && apt-get clean

# Copy package files first for better caching
COPY package.json bun.lockb ./

# Install ALL dependencies (including dev dependencies for drizzle-kit)
RUN bun install

# Copy entire application
COPY . .

# Build the application
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV NEXT_SKIP_TYPE_CHECK=1
ENV NEXT_SKIP_LINT=1
ENV NEXT_PUBLIC_URL=https://open-launch.com
ENV PORT=3000
ENV BETTER_AUTH_SECRET=mock_secret_at_least_32_chars_long_for_build
ENV DATABASE_URL=mock_db_url
ENV RESEND_API_KEY=re_mockvalue
ENV STRIPE_SECRET_KEY=sk_test_mockvalue
ENV NEXT_PUBLIC_UPLOADTHING_URL=yxucdfr9f5.ufs.sh

RUN NODE_OPTIONS="--max_old_space_size=4096" bun run build

# Create a production image with everything included
FROM oven/bun:1

WORKDIR /app

# Install necessary tools
RUN apt-get update && apt-get install -y nodejs npm curl postgresql-client && apt-get clean

# Copy EVERYTHING from the builder stage
COPY --from=builder /app /app

# Set environment variables for runtime
ENV PORT=3000
ENV HOST=0.0.0.0

# Expose port
EXPOSE 3000

# Simple health check - FIX: use port 3000
HEALTHCHECK --interval=30s --timeout=30s --start-period=30s --retries=3 CMD curl -f http://localhost:3000/ || exit 1

# Create an initialization script
RUN echo '#!/bin/sh\n\
echo "Initializing database..."\n\
bunx drizzle-kit push\n\
echo "Seeding categories..."\n\
bun scripts/categories.ts\n\
echo "Starting application..."\n\
# FIX: Add HOST and use -p flag to be explicit about port\n\
HOST=0.0.0.0 bun run start -p 3000\n\
' > /app/start.sh && chmod +x /app/start.sh

# Start command runs the initialization script
CMD ["/app/start.sh"]
