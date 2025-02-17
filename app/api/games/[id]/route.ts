import { NextRequest, NextResponse } from "next/server";
import { getUserIdFromToken } from "@/lib/auth";
import prisma from "@/lib/prisma";

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
      include: { attendees: true },
    });

    if (!game) {
      return NextResponse.json({ error: "Game not found" }, { status: 404 });
    }

    if (game.attendees.length >= game.maxPlayers) {
      const attendee = await prisma.attendee.create({
        data: {
          gameId,
          userId,
          waitlist: true,
        },
      });
      return NextResponse.json({ message: "Added to waitlist", attendee });
    }

    const attendee = await prisma.attendee.create({
      data: {
        gameId,
        userId,
      },
    });

    return NextResponse.json({ message: "Successfully joined game", attendee });
  } catch (error) {
    console.error("Error joining game:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}

export async function DELETE(
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
      include: { attendees: true },
    });

    if (!game) {
      return NextResponse.json({ error: "Game not found" }, { status: 404 });
    }

    await prisma.attendee.delete({
      where: {
        gameId_userId: {
          gameId,
          userId,
        },
      },
    });

    // Check if there's someone on the waitlist to move up
    const waitlistAttendee = await prisma.attendee.findFirst({
      where: { gameId, waitlist: true },
      orderBy: { signedUpAt: "asc" },
    });

    if (waitlistAttendee) {
      await prisma.attendee.update({
        where: { id: waitlistAttendee.id },
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

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const game = await prisma.game.findUnique({
      where: {
        id: Number(params.id),
      },
      include: {
        attendees: {
          select: {
            id: true,
            user: {
              select: {
                name: true,
                email: true,
              },
            },
          },
        },
        host: {
          select: {
            name: true,
          },
        },
      },
    });

    if (!game) {
      return NextResponse.json({ error: "Game not found" }, { status: 404 });
    }

    return NextResponse.json(game);
  } catch (error) {
    console.error("Error fetching game:", error);
    return NextResponse.json(
      { error: "Error fetching game details" },
      { status: 500 }
    );
  }
}
