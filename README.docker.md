# Docker Setup for Poker Night App

This document provides instructions on how to run the Poker Night App using Docker.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Getting Started

### 1. Environment Variables

Create a `.env` file in the root directory with the following variables:

```
DATABASE_URL="mysql://root:root@db:3306/poker_game_planner"
JWT_SECRET="your-jwt-secret"
GOOGLE_CLIENT_ID="your-google-client-id"
GOOGLE_CLIENT_SECRET="your-google-client-secret"
NEXT_PUBLIC_APP_URL="http://localhost:3000"
```

Note: The `DATABASE_URL` is configured to work with the Docker Compose setup.

### 2. Build and Run with Docker Compose

```bash
# Build and start the containers
docker-compose up -d

# View logs
docker-compose logs -f
```

The application will be available at http://localhost:3000.

### 3. Database Migrations

When running the app for the first time or after schema changes, you need to run Prisma migrations:

```bash
# Access the app container
docker-compose exec app sh

# Run Prisma migrations
npx prisma migrate deploy
```

## Development with Docker

### Rebuilding the Application

If you make changes to the application code, you need to rebuild the Docker image:

```bash
docker-compose build app
docker-compose up -d
```

### Accessing the Database

You can connect to the MySQL database using a database client with these credentials:

- Host: localhost
- Port: 3306
- Username: root
- Password: root
- Database: poker_game_planner

## Stopping the Application

```bash
# Stop the containers
docker-compose down

# Stop the containers and remove volumes (will delete database data)
docker-compose down -v
```

## Troubleshooting

### Prisma Client Issues

If you encounter Prisma client issues, you may need to regenerate the Prisma client:

```bash
docker-compose exec app sh
npx prisma generate
```

### Database Connection Issues

If the app cannot connect to the database, ensure the database container is running:

```bash
docker-compose ps
```

The database might take a few seconds to initialize. You can check the logs:

```bash
docker-compose logs db
```
