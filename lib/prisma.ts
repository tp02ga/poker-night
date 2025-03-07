import { PrismaClient } from "@prisma/client";

// PrismaClient is attached to the `global` object in development to prevent
// exhausting your database connection limit.
// Learn more: https://pris.ly/d/help/next-js-best-practices

const globalForPrisma = global as unknown as { prisma: PrismaClient };

// Create a singleton Prisma client with logging
export const prisma =
  globalForPrisma.prisma ||
  new PrismaClient({
    log: [
      { level: "error", emit: "stdout" },
      { level: "warn", emit: "stdout" },
    ],
  });

// Add connection management for development
if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = prisma;
}

// Handle graceful shutdown
const handleShutdown = async () => {
  console.log("Shutting down Prisma client...");
  await prisma.$disconnect();
  console.log("Prisma client disconnected.");
  process.exit(0);
};

// Register shutdown handlers if not in a browser environment
if (typeof window === "undefined") {
  process.on("SIGINT", handleShutdown);
  process.on("SIGTERM", handleShutdown);
}

export default prisma;
