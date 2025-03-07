import { NextRequest, NextResponse } from "next/server";
import prisma from "@/lib/prisma";

// Track health check history
const healthHistory = {
  totalChecks: 0,
  successfulChecks: 0,
  failedChecks: 0,
  lastFailureReason: null as string | null,
  startTime: new Date().toISOString(),
};

// Track memory usage
const getMemoryUsage = () => {
  const memoryUsage = process.memoryUsage();
  return {
    rss: `${Math.round(memoryUsage.rss / 1024 / 1024)} MB`,
    heapTotal: `${Math.round(memoryUsage.heapTotal / 1024 / 1024)} MB`,
    heapUsed: `${Math.round(memoryUsage.heapUsed / 1024 / 1024)} MB`,
    external: `${Math.round(memoryUsage.external / 1024 / 1024)} MB`,
  };
};

// Helper function to perform the health check
async function performHealthCheck() {
  healthHistory.totalChecks++;

  console.log(`[Health Check] Running check #${healthHistory.totalChecks}`);

  try {
    // Simple database query with a short timeout
    // We use Promise.race to ensure we don't exceed the health check timeout
    const dbCheckPromise = prisma.$queryRaw`SELECT 1`;

    // Create a timeout promise
    const timeoutPromise = new Promise((_, reject) => {
      setTimeout(() => {
        reject(new Error("Database query timeout"));
      }, 2000); // 2 second timeout, adjust as needed
    });

    // Race the database query against the timeout
    const startTime = Date.now();
    await Promise.race([dbCheckPromise, timeoutPromise]);
    const queryTime = Date.now() - startTime;

    console.log(`[Health Check] Database query successful in ${queryTime}ms`);

    healthHistory.successfulChecks++;

    return {
      success: true,
      queryTime,
      error: null,
    };
  } catch (error: any) {
    healthHistory.failedChecks++;
    healthHistory.lastFailureReason = error.message;

    console.error("[Health Check] Failed:", error);

    // Log detailed diagnostics for troubleshooting
    console.error({
      totalChecks: healthHistory.totalChecks,
      successRate: `${Math.round(
        (healthHistory.successfulChecks / healthHistory.totalChecks) * 100
      )}%`,
      failureCount: healthHistory.failedChecks,
      memory: getMemoryUsage(),
    });

    return {
      success: false,
      queryTime: 0,
      error: error.message,
    };
  }
}

// GET handler for AWS health checks - now with detailed metrics
export async function GET(request: NextRequest) {
  console.log("Starting health check...");
  const result = await performHealthCheck();

  // Check if the request includes a query parameter for simple response
  const url = new URL(request.url);
  const simple = url.searchParams.get("simple");

  if (simple === "true") {
    // Return a simple response for AWS health checks
    if (result.success) {
      return new NextResponse("OK", { status: 200 });
    } else {
      return new NextResponse("Service Unavailable", { status: 503 });
    }
  }

  // Otherwise return detailed metrics (same as what POST would return)
  if (result.success) {
    return NextResponse.json(
      {
        status: "ok",
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: process.env.NODE_ENV || "development",
        database: {
          status: "connected",
          queryTimeMs: result.queryTime,
        },
        memory: getMemoryUsage(),
        healthHistory: {
          totalChecks: healthHistory.totalChecks,
          successRate: `${Math.round(
            (healthHistory.successfulChecks / healthHistory.totalChecks) * 100
          )}%`,
          lastFailureReason: healthHistory.lastFailureReason,
        },
      },
      { status: 200 }
    );
  } else {
    return NextResponse.json(
      {
        status: "error",
        timestamp: new Date().toISOString(),
        error: "Database connection failed",
        details: result.error,
        memory: getMemoryUsage(),
        healthHistory: {
          totalChecks: healthHistory.totalChecks,
          successRate: `${Math.round(
            (healthHistory.successfulChecks / healthHistory.totalChecks) * 100
          )}%`,
          failureCount: healthHistory.failedChecks,
        },
      },
      { status: 503 }
    );
  }
}

// POST handler for detailed health check information
export async function POST(request: NextRequest) {
  console.log("Starting detailed health check...");
  const result = await performHealthCheck();

  if (result.success) {
    return NextResponse.json(
      {
        status: "ok",
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: process.env.NODE_ENV || "development",
        database: {
          status: "connected",
          queryTimeMs: result.queryTime,
        },
        memory: getMemoryUsage(),
        healthHistory: {
          totalChecks: healthHistory.totalChecks,
          successRate: `${Math.round(
            (healthHistory.successfulChecks / healthHistory.totalChecks) * 100
          )}%`,
          lastFailureReason: healthHistory.lastFailureReason,
        },
      },
      { status: 200 }
    );
  } else {
    return NextResponse.json(
      {
        status: "error",
        timestamp: new Date().toISOString(),
        error: "Database connection failed",
        details: result.error,
        memory: getMemoryUsage(),
        healthHistory: {
          totalChecks: healthHistory.totalChecks,
          successRate: `${Math.round(
            (healthHistory.successfulChecks / healthHistory.totalChecks) * 100
          )}%`,
          failureCount: healthHistory.failedChecks,
        },
      },
      { status: 503 }
    );
  }
}
