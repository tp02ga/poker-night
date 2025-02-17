import { NextRequest, NextResponse } from "next/server";
import { PrismaClient } from "@prisma/client";
import { getUserIdFromToken } from "@/lib/auth";

const prisma = new PrismaClient();

export async function POST(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  const gameId = Number.parseInt(params.id);
  const userId = await getUserIdFromToken(request);

  if (!userId) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  try {
    const game = await prisma.game.findUnique({
      where: { id: gameId },
      include: {
        attendees: true,
      },
    });

    if (!game) {
      return NextResponse.json({ error: "Game not found" }, { status: 404 });
    }

    // Check if game is starting in less than 5 minutes
    const fiveMinutesBeforeGame = new Date(game.dateTime);
    fiveMinutesBeforeGame.setMinutes(fiveMinutesBeforeGame.getMinutes() - 5);

    if (new Date() > fiveMinutesBeforeGame) {
      return NextResponse.json(
        { error: "Cannot join game less than 5 minutes before start" },
        { status: 400 }
      );
    }

    // Check if user is already registered
    const existingAttendee = await prisma.attendee.findFirst({
      where: {
        gameId,
        userId,
      },
    });

    if (existingAttendee) {
      return NextResponse.json(
        { error: "Already registered for this game" },
        { status: 400 }
      );
    }

    // Determine if user should be waitlisted
    const isWaitlisted = game.attendees.length >= game.maxPlayers;

    const attendee = await prisma.attendee.create({
      data: {
        gameId,
        userId,
        waitlist: isWaitlisted,
      },
    });

    return NextResponse.json({
      message: isWaitlisted ? "Added to waitlist" : "Successfully joined game",
      attendee,
    });
  } catch (error) {
    console.error("Error joining game:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
