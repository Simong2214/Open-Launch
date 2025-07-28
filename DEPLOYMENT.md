# Open Launch Deployment Guide

This guide explains how to deploy Open Launch to Coolify using Docker containers and GitHub Actions.

## Prerequisites

- A Coolify server instance
- GitHub repository for Open Launch
- GitHub repository secrets for environment variables

## Step 1: Set Up GitHub Secrets

Add these secrets to your GitHub repository:

```
COOLIFY_WEBHOOK: Your Coolify webhook URL
COOLIFY_TOKEN: Your Coolify API token
```

## Step 2: Set Up Databases in Coolify

### PostgreSQL Setup

1. In Coolify dashboard, go to "Resources" > "New Resource"
2. Select "PostgreSQL"
3. Configure:
   - Name: `open-launch-db`
   - Username: Create a username
   - Password: Create a secure password
   - Database: `open_launch`
4. Click "Create"
5. Note the connection string: `postgresql://username:password@hostname:5432/open_launch`

### Redis Setup

1. In Coolify dashboard, go to "Resources" > "New Resource"
2. Select "Redis"
3. Configure:
   - Name: `open-launch-redis`
   - Password: Create a secure password (or leave blank for development)
4. Click "Create"
5. Note the connection string: `redis://hostname:6379`

## Step 3: Deploy Docker Container

1. In Coolify dashboard, go to "Resources" > "New Resource"
2. Select "Application" > "Docker Registry"
3. Configure:

   - Name: `open-launch`
   - Image: `ghcr.io/simong2214/open-launch:latest`
   - Port: `3000`
   - Environment Variables:
     ```
     NODE_ENV=production
     DATABASE_URL=postgresql://username:password@open-launch-db:5432/open_launch
     REDIS_URL=redis://open-launch-redis:6379
     BETTER_AUTH_SECRET=your_random_secret_string
     BETTER_AUTH_URL=https://your-domain.com
     NEXT_PUBLIC_URL=https://your-domain.com
     NEXT_PUBLIC_CONTACT_EMAIL=your@email.com
     ```
     (Add any other required variables)

4. Under "Advanced", configure:

   - Memory limit: 512 MB (or as needed)
   - CPU limit: 0.5 (or as needed)
   - Auto-restart: Enabled
   - Container health check: Enabled

5. Click "Create"

## Step 4: Set Up Auto-Deployment

1. In Coolify dashboard, go to your application
2. Click "Settings" > "Webhooks"
3. Copy the webhook URL
4. Add this URL as `COOLIFY_WEBHOOK` in your GitHub secrets

## Step 5: Initialize Database

After the first deployment:

1. In Coolify dashboard, go to your application
2. Open the "Terminal" tab
3. Run:
   ```bash
   bunx drizzle-kit push
   bun scripts/categories.ts
   ```

## Step 6: Configure Domain and SSL

1. In Coolify dashboard, go to your application
2. Click "Settings" > "Domains"
3. Add your domain
4. Enable SSL

## Troubleshooting

### Database Connection Issues

If your app can't connect to the database:

1. Check container network settings in Coolify
2. Verify environment variables
3. Check database logs in Coolify

### Container Startup Issues

If the container fails to start:

1. Check container logs in Coolify
2. Verify the image was built correctly
3. Check if all required environment variables are set

## Database Backup and Restore

### Create a Backup

1. In Coolify dashboard, go to your PostgreSQL resource
2. Click "Backup" > "Create Backup"
3. Download the backup file

### Restore from Backup

1. In Coolify dashboard, go to your PostgreSQL resource
2. Click "Backup" > "Restore"
3. Upload your backup file

## Monitoring

1. In Coolify dashboard, go to your application
2. Check the "Logs" and "Metrics" tabs for monitoring
3. Consider setting up alerts for critical issues

You now have a complete deployment of Open Launch on Coolify with automatic updates from GitHub!

## Security Considerations for Forked Repositories

If you're deploying from a forked repository:

1. **Never commit sensitive information** to the repository:

   - API keys
   - Database credentials
   - Authentication secrets
   - Private URLs

2. **Set up all sensitive variables in Coolify**, not in GitHub Actions:

   - Environment variables should be configured in Coolify's service settings
   - Database connection strings should use internal Docker network names

3. **Use GitHub repository secrets** only for CI/CD access:

   - GITHUB_TOKEN is automatically provided
   - No need to add other secrets for basic image building

4. **Container builds are public** in open source repositories:

   - Build logs are visible to everyone
   - Don't expose sensitive data during build process

5. **Inspect Docker images** before deployment:
   - Ensure no sensitive data is baked into the image
   - Use proper .dockerignore to exclude .env files
