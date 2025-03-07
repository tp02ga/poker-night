import { NextResponse } from "next/server";

// Extremely simple health check that always returns 200
// This is specifically for container health checks
export async function GET() {
  return new NextResponse("OK", { status: 200 });
}
