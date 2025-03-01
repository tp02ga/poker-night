# Poker Night App

A web application for organizing and managing poker game nights.

## Google Authentication Setup

This application supports Google OAuth authentication. Here's how it's configured:

### Prerequisites

1. Google Cloud Platform account with OAuth credentials:

   - Client ID: [Your Google OAuth Client ID]
   - Client Secret: [Your Google OAuth Client Secret]

2. Environment variables:
   - `GOOGLE_CLIENT_ID`: Your Google OAuth Client ID
   - `GOOGLE_CLIENT_SECRET`: Your Google OAuth Client Secret
   - `JWT_SECRET`: Secret key for signing JWT tokens
   - `NEXT_PUBLIC_APP_URL`: Your application's URL (defaults to http://localhost:3000 in development)
   - `DATABASE_URL`: MySQL database connection string

### Setup Instructions

1. Install dependencies:

   ```bash
   npm install
   ```

2. Create a `.env.local` file in the root directory with the following variables:

   ```
   GOOGLE_CLIENT_ID=your_client_id_here
   GOOGLE_CLIENT_SECRET=your_client_secret_here
   JWT_SECRET=your_jwt_secret_here
   NEXT_PUBLIC_APP_URL=http://localhost:3000
   ```

3. Run Prisma migrations to update your database schema:

   ```bash
   npx prisma migrate dev --name add-google-auth
   ```

4. Start the development server:
   ```bash
   npm run dev
   ```

### Authentication Flow

The application supports two authentication methods:

1. **Traditional Email/Password Login**

   - Users can register and login with email and password

2. **Google OAuth Authentication**
   - Users can sign in with their Google account
   - The app will automatically create a new user account if one doesn't exist
   - If a user with the same email already exists, the Google account will be linked to that user

### Security Considerations

- JWT tokens are stored in HTTP-only cookies
- OAuth state parameter is used to prevent CSRF attacks
- Sensitive credentials are not exposed to the client-side code

## Development

To run the application in development mode:

```bash
npm run dev
```

The application will be available at http://localhost:3000.

## Docker and AWS Deployment

### Docker Setup

The application is containerized using Docker for easy deployment. Here's how to use it:

#### Local Development with Docker

1. Build and start the containers:

   ```bash
   docker-compose up -d
   ```

2. The application will be available at http://localhost:3000

3. To stop the containers:

   ```bash
   docker-compose down
   ```

#### Building the Docker Image

To build the Docker image manually:

```bash
docker build -t poker-night-app .
```

### AWS Deployment

This application can be deployed to AWS using various services. Here's a recommended approach:

#### Option 1: AWS Elastic Beanstalk

1. Install the AWS CLI and EB CLI:

   ```bash
   pip install awscli awsebcli
   ```

2. Initialize your EB application:

   ```bash
   eb init
   ```

3. Create an environment and deploy:

   ```bash
   eb create
   ```

4. For subsequent deployments:

   ```bash
   eb deploy
   ```

#### Option 2: AWS ECS (Elastic Container Service)

1. Create an ECR repository:

   ```bash
   aws ecr create-repository --repository-name poker-night-app
   ```

2. Authenticate Docker to your ECR registry:

   ```bash
   aws ecr get-login-password | docker login --username AWS --password-stdin <your-aws-account-id>.dkr.ecr.<region>.amazonaws.com
   ```

3. Tag and push your Docker image:

   ```bash
   docker tag poker-night-app:latest <your-aws-account-id>.dkr.ecr.<region>.amazonaws.com/poker-night-app:latest
   docker push <your-aws-account-id>.dkr.ecr.<region>.amazonaws.com/poker-night-app:latest
   ```

4. Create an ECS cluster, task definition, and service using the AWS Management Console or AWS CLI.

#### Database Setup on AWS

For the database, consider using:

1. **Amazon RDS for MySQL**:

   - Create a MySQL instance in RDS
   - Update the `DATABASE_URL` environment variable to point to your RDS instance
   - Ensure the security group allows connections from your application

2. **Amazon Aurora**:
   - A more scalable alternative to RDS, compatible with MySQL

#### Environment Variables on AWS

Make sure to set these environment variables in your AWS environment:

- `DATABASE_URL`: Connection string to your RDS/Aurora database
- `JWT_SECRET`: Secret key for JWT tokens (use AWS Secrets Manager for production)
- `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET`: For Google OAuth
- `NEXT_PUBLIC_APP_URL`: Your application's public URL

#### Setting Up HTTPS

For production, set up HTTPS using:

1. **AWS Certificate Manager (ACM)** to provision SSL/TLS certificates
2. **AWS Route 53** for DNS management
3. **AWS CloudFront** as a CDN and to handle HTTPS termination

#### Monitoring and Logging

Set up:

1. **AWS CloudWatch** for logs and metrics
2. **AWS X-Ray** for tracing and performance monitoring
