import { NextResponse } from "next/server";

export async function POST() {
  const response = NextResponse.json({ message: "Logged out successfully" });

  // Clear the token cookie
  response.cookies.set("token", "", {
    expires: new Date(0),
    path: "/",
  });

  return response;
}
