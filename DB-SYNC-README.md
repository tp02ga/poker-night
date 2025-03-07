# Database Sync Script

This script helps you synchronize your Prisma schema with the AWS RDS database instance.

## What it does

The script performs the following operations:

1. Creates a temporary `.env` file with the RDS connection string (backing up any existing `.env` file)
2. Runs `prisma generate` to update the Prisma client
3. Runs `prisma migrate deploy` to apply any pending migrations to the database
4. Restores the original `.env` file (if it existed)

## Prerequisites

- Node.js installed
- Project dependencies installed (`npm install` or `yarn install`)

## Usage

You can run the script in two ways:

### Using npm script

```bash
npm run db:sync
```

### Running the script directly

```bash
node sync-db.js
```

## Important Notes

- The script temporarily modifies your `.env` file but restores it afterward
- The RDS connection string is hardcoded in the script for simplicity
- For security in production environments, consider using environment variables or a secrets manager
- Make sure your AWS security groups allow connections from your IP address to the RDS instance

## Troubleshooting

If you encounter any issues:

1. Ensure your RDS instance is running and accessible
2. Check that the connection string is correct
3. Verify that your IP is allowed in the RDS security group
4. Make sure you have the necessary permissions to modify the database

## Security Warning

The script contains database credentials. Do not commit it to public repositories or share it with unauthorized individuals.
