import { NextRequest, NextResponse } from "next/server";
import { PrismaClient } from "@prisma/client";
import { sign } from "jsonwebtoken";

const prisma = new PrismaClient();

// Google OAuth configuration
const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID;
const GOOGLE_CLIENT_SECRET = process.env.GOOGLE_CLIENT_SECRET;
const REDIRECT_URI = `${
  process.env.NEXT_PUBLIC_APP_URL || "http://localhost:3000"
}/api/auth/google/callback`;

// JWT secret for creating session tokens
const JWT_SECRET = process.env.JWT_SECRET || "your-jwt-secret-key";

export async function GET(request: NextRequest) {
  try {
    // Get the authorization code from the URL
    const searchParams = request.nextUrl.searchParams;
    const code = searchParams.get("code");
    const state = searchParams.get("state");

    // Verify state to prevent CSRF attacks
    const storedState = request.cookies.get("google_oauth_state")?.value;

    if (!code) {
      return NextResponse.redirect(
        `${
          process.env.NEXT_PUBLIC_APP_URL || "http://localhost:3000"
        }/login?auth_error=No authorization code provided`
      );
    }

    if (state !== storedState) {
      return NextResponse.redirect(
        `${
          process.env.NEXT_PUBLIC_APP_URL || "http://localhost:3000"
        }/login?auth_error=Invalid state parameter`
      );
    }

    // Exchange the code for an access token
    const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        code,
        client_id: GOOGLE_CLIENT_ID,
        client_secret: GOOGLE_CLIENT_SECRET,
        redirect_uri: REDIRECT_URI,
        grant_type: "authorization_code",
      }),
    });

    if (!tokenResponse.ok) {
      const errorData = await tokenResponse.json();
      console.error("Token exchange error:", errorData);
      return NextResponse.redirect(
        `${
          process.env.NEXT_PUBLIC_APP_URL || "http://localhost:3000"
        }/login?auth_error=Failed to exchange token`
      );
    }

    const tokenData = await tokenResponse.json();

    // Get user info with the access token
    const userInfoResponse = await fetch(
      "https://www.googleapis.com/oauth2/v2/userinfo",
      {
        headers: { Authorization: `Bearer ${tokenData.access_token}` },
      }
    );

    if (!userInfoResponse.ok) {
      return NextResponse.redirect(
        `${
          process.env.NEXT_PUBLIC_APP_URL || "http://localhost:3000"
        }/login?auth_error=Failed to get user info`
      );
    }

    const userData = await userInfoResponse.json();

    // Find or create user in the database
    let user = await prisma.user.findUnique({
      where: { email: userData.email },
      include: { accounts: true },
    });

    if (!user) {
      // Create new user if they don't exist
      user = await prisma.user.create({
        data: {
          email: userData.email,
          name: userData.name || userData.email.split("@")[0],
          image: userData.picture,
          accounts: {
            create: {
              provider: "google",
              providerAccountId: userData.id,
              type: "oauth",
              access_token: tokenData.access_token,
              expires_at: Math.floor(Date.now() / 1000 + tokenData.expires_in),
              refresh_token: tokenData.refresh_token,
              id_token: tokenData.id_token,
              scope: tokenData.scope,
              token_type: tokenData.token_type,
            },
          },
        },
        include: { accounts: true },
      });
    } else if (
      !user.accounts.some((account) => account.provider === "google")
    ) {
      // Link Google account if user exists but doesn't have a Google account linked
      await prisma.account.create({
        data: {
          userId: user.id,
          provider: "google",
          providerAccountId: userData.id,
          type: "oauth",
          access_token: tokenData.access_token,
          expires_at: Math.floor(Date.now() / 1000 + tokenData.expires_in),
          refresh_token: tokenData.refresh_token,
          id_token: tokenData.id_token,
          scope: tokenData.scope,
          token_type: tokenData.token_type,
        },
      });
    }

    // Create a JWT token for the user session
    const token = sign({ userId: user.id, email: user.email }, JWT_SECRET, {
      expiresIn: "7d",
    });

    // Set the token as a cookie and redirect to the games page
    const response = NextResponse.redirect(
      `${
        process.env.NEXT_PUBLIC_APP_URL || "http://localhost:3000"
      }/games?auth_success=true`
    );

    response.cookies.set("auth_token", token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      maxAge: 60 * 60 * 24 * 7, // 7 days
      path: "/",
    });

    // Clear the state cookie
    response.cookies.set("google_oauth_state", "", {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      maxAge: 0,
      path: "/",
    });

    return response;
  } catch (error) {
    console.error("Google OAuth callback error:", error);
    return NextResponse.redirect(
      `${
        process.env.NEXT_PUBLIC_APP_URL || "http://localhost:3000"
      }/login?auth_error=Server error during authentication`
    );
  }
}
