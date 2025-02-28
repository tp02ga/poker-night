import { NextResponse } from "next/server";

// Google OAuth configuration
const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID;
const GOOGLE_CLIENT_SECRET = process.env.GOOGLE_CLIENT_SECRET;
const REDIRECT_URI = `${
  process.env.NEXT_PUBLIC_APP_URL || "http://localhost:3000"
}/api/auth/google/callback`;

export async function GET() {
  // Generate a random state value for security
  const state = Math.random().toString(36).substring(2, 15);

  // Store state in a cookie for verification later
  const response = NextResponse.redirect(
    `https://accounts.google.com/o/oauth2/v2/auth?client_id=${GOOGLE_CLIENT_ID}&redirect_uri=${encodeURIComponent(
      REDIRECT_URI
    )}&response_type=code&scope=${encodeURIComponent(
      "openid email profile"
    )}&state=${state}`
  );

  // Set the state cookie
  response.cookies.set("google_oauth_state", state, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    maxAge: 60 * 10, // 10 minutes
    path: "/",
  });

  return response;
}
