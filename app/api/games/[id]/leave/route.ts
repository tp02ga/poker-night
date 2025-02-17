import { NextResponse } from "next/server";
import { PrismaClient } from "@prisma/client";
import { getUserIdFromToken } from "@/lib/auth";

const prisma = new PrismaClient();

export async function POST(
  request: Request,
  { params }: { params: { id: string } }
) {
  const gameId = Number.parseInt(params.id);
  const userId = await getUserIdFromToken(request);

  if (!userId) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  try {
    // Delete the attendee record
    await prisma.attendee.delete({
      where: {
        gameId_userId: {
          gameId,
          userId,
        },
      },
    });

    // Find the next person on the waitlist
    const nextWaitlisted = await prisma.attendee.findFirst({
      where: {
        gameId,
        waitlist: true,
      },
      orderBy: {
        signedUpAt: "asc",
      },
    });

    // If there's someone on the waitlist, promote them
    if (nextWaitlisted) {
      await prisma.attendee.update({
        where: { id: nextWaitlisted.id },
        data: { waitlist: false },
      });
    }

    return NextResponse.json({ message: "Successfully left game" });
  } catch (error) {
    console.error("Error leaving game:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
