import type { NextRequest } from "next/server"
import jwt from "jsonwebtoken"

export async function getUserIdFromToken(request: NextRequest): Promise<number | null> {
  const token = request.cookies.get("token")?.value

  if (!token) {
    return null
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as { userId: number }
    return decoded.userId
  } catch (error) {
    console.error("Error decoding token:", error)
    return null
  }
}

