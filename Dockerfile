# Base image
FROM node:18-alpine AS base
WORKDIR /app

# Dependencies
FROM base AS deps
# Install build dependencies for bcrypt
RUN apk add --no-cache python3 make g++ 

COPY package.json package-lock.json ./
COPY prisma ./prisma

RUN npm ci

# Builder
FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

# Runner
FROM base AS runner
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED 1

# Install runtime dependencies for bcrypt and Prisma
RUN apk add --no-cache bash openssl openssl-dev

COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/prisma ./prisma

# Generate Prisma Client
RUN npx prisma generate

# Create start script directly in the CMD
EXPOSE 3000

# Use a direct command instead of a script file
CMD /bin/sh -c "echo 'Running database migrations...' && npx prisma migrate deploy && echo 'Starting application...' && npm start" 