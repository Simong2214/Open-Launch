# Open Launch Installation Guide

This document provides step-by-step instructions for setting up the Open Launch application locally, including solutions for common issues.

## Prerequisites

- macOS, Linux, or Windows with WSL
- [Homebrew](https://brew.sh/) (for macOS users)
- [Bun](https://bun.sh/) package manager
- PostgreSQL database server
- Redis server

## 1. Clone the Repository

```bash
git clone https://github.com/drdruide/open-launch.git
cd open-launch
```

## 2. Install Dependencies

```bash
# Install Bun if you don't have it
curl -fsSL https://bun.sh/install | bash

# Make Bun available in your terminal
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Install project dependencies
bun install
```

## 3. Set Up Environment Variables

```bash
# Create .env file from example
cp .env.example .env

# Edit the .env file with your specific configurations
nano .env
```

Update the following key variables in your `.env` file:

```
# Database
DATABASE_URL=postgresql://username@localhost:5432/open_launch

# Redis (for rate limiting and sessions)
REDIS_URL=redis://localhost:6379

# Authentication
BETTER_AUTH_URL=http://localhost:3000
BETTER_AUTH_SECRET="generated_secret_key"
```

Generate a secure random string for `BETTER_AUTH_SECRET`:

```bash
openssl rand -base64 32
```

## 4. Set Up PostgreSQL (macOS)

```bash
# Install PostgreSQL
brew install postgresql@16
brew services start postgresql

# Create a database
createdb open_launch
```

### Troubleshooting PostgreSQL

If `createdb` command is not found:

```bash
# Add PostgreSQL commands to your PATH
echo 'export PATH="/usr/local/opt/postgresql@16/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Then try again
createdb open_launch
```

If you encounter connection errors:

```bash
# Verify PostgreSQL is running
brew services list | grep postgres

# Restart if needed
brew services restart postgresql

# Check your PostgreSQL username (usually your system username)
whoami
```

Update your `.env` file with the correct username:

```
DATABASE_URL=postgresql://$(whoami)@localhost:5432/open_launch
```

## 5. Set Up Redis (macOS)

```bash
# Install Redis
brew install redis
brew services start redis
```

## 6. Initialize the Database

```bash
# Generate database schema
bun x --bun drizzle-kit generate

# Apply schema changes to database
bun x --bun drizzle-kit push

# Seed categories
bun scripts/categories.ts
```

### Troubleshooting Node.js/ICU Library Issues

If you encounter ICU library errors with Node.js:

```
Symbol not found: __ZNK6icu_746number23NumberFormatterSettingsINS0_24LocalizedNumberFormatterEE10toSkeletonER10UErrorCode
```

Install Node.js version 18 using nvm:

```bash
# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Configure nvm in your shell
echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.zshrc
source ~/.zshrc

# Install Node.js 18
nvm install 18
nvm use 18

# Then run the Drizzle commands directly with Bun
bun x --bun drizzle-kit generate
bun x --bun drizzle-kit push
```

## 7. Start the Development Server

```bash
# Start the Next.js development server
bun run dev
```

Your application should now be running at http://localhost:3000

## 8. Explore the Database with Drizzle Studio

```bash
# Launch Drizzle Studio
bun x --bun drizzle-kit studio
```

The Studio should open in your browser, providing a visual interface to your database.

## 9. Make Bun Available in Every Terminal

Add Bun to your shell profile for permanent access:

```bash
echo 'export BUN_INSTALL="$HOME/.bun"' >> ~/.zshrc
echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## Importing a PostgreSQL Dump

If you have an existing database dump:

```bash
# For SQL format dumps
psql -d open_launch < your_dump.sql

# For binary format dumps
pg_restore -d open_launch your_dump.dump

# After importing, run migrations to ensure schema is up to date
bun x --bun drizzle-kit push
```

## Deployment

For deployment instructions, see the [deployment guide](./DEPLOYMENT.md).

## Common Issues and Solutions

### ICU Library Compatibility

The error about ICU library compatibility happens when Node.js version 22+ is installed with an incompatible ICU library. The solution is to use Node.js 18 with nvm as shown above.

### PostgreSQL Connection Issues

1. Check that PostgreSQL is running: `brew services list`
2. Verify your database exists: `psql -l`
3. Check your connection string in `.env`
4. Try connecting manually: `psql -d open_launch`

### Bun Not Found in New Terminals

Add Bun to your shell profile as shown in step 9 above.

### Next.js Build Failures

If you encounter build failures with Next.js:

1. Try without Turbopack: modify `package.json` to remove `--turbopack` flag
2. Clear the Next.js cache: `rm -rf .next`
3. Reinstall dependencies: `bun install`

## Additional Resources

- [Next.js Documentation](https://nextjs.org/docs)
- [Drizzle ORM Documentation](https://orm.drizzle.team)
- [Bun Documentation](https://bun.sh/docs)
