# Database Setup Guide for Open Launch

This guide explains how to properly set up and manage the database for your Open Launch application deployment.

## Understanding the Database Architecture

Open Launch uses:

- **PostgreSQL** as the primary database
- **Drizzle ORM** for database schema management and migrations
- **Redis** for sessions and rate limiting

## Local Development

For local development, follow these steps:

1. Make sure PostgreSQL is installed and running locally
2. Create a new database: `createdb open_launch`
3. Copy `.env.example` to `.env` and update the database connection:
   ```
   DATABASE_URL=postgresql://username:password@localhost:5432/open_launch
   ```
4. Run migrations: `bun run db:migrate` or `bun run db:push`
5. Start the development server: `bun run dev`

## Production Deployment (Coolify)

### 1. Create Required Services in Coolify

Before deploying your application, create:

- PostgreSQL database
- Redis instance

### 2. Configure Environment Variables

Set these environment variables in your Coolify deployment:

```
DATABASE_URL=postgresql://username:password@db-hostname:5432/database_name
REDIS_URL=redis://username:password@redis-hostname:6379
NEXT_PUBLIC_URL=https://your-production-domain.com
# ... other variables from .env.example
```

### 3. Database Migration Strategy

There are two ways to handle database migrations:

#### Option 1: Separate Migration Step (Recommended)

Run migrations separately before starting the application:

1. Run the setup script in your deployment process:

   ```
   bun run db:setup
   ```

2. Make sure the script completes successfully before starting the application

#### Option 2: Migrations at Runtime

Run migrations when your application starts (not recommended for production):

1. Add migration logic to your application's startup code
2. This approach can cause race conditions in multi-container deployments

## Troubleshooting Database Connections

If you see errors like `Error: getaddrinfo ENOTFOUND eok4888ookwsoc4wks4s488g`:

1. **Check Connection String**: Verify that your `DATABASE_URL` is correctly formatted
2. **Network Connectivity**: Ensure your application container can reach the database host
3. **PostgreSQL Configuration**: Check that PostgreSQL is configured to accept connections from your application
4. **Credentials**: Verify that username and password are correct

## Running Commands Against Production Database

To run commands against your production database:

1. Securely obtain your production database connection string
2. Export it locally:
   ```bash
   export DATABASE_URL="postgresql://username:password@hostname:5432/database"
   ```
3. Run commands locally:
   ```bash
   bun run db:generate  # Generate migration files
   bun run db:migrate   # Apply migrations
   ```

**IMPORTANT**: Be extremely careful when running commands against production data!

## Database Schema Evolution

When making changes to the database schema:

1. Update schema files in `drizzle/db/schema.ts`
2. Generate migration files: `bun run db:generate`
3. Test migrations locally: `bun run db:migrate`
4. Commit migration files to your repository
5. Apply migrations in production using the db:setup script

Never manually edit production databases directly.
