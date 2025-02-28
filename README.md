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
