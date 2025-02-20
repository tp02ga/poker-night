import { NextRequest, NextResponse } from "next/server";
import prisma from "@/lib/prisma";
import { getUserIdFromToken } from "@/lib/auth";

export async function GET(request: NextRequest) {
  const userId = await getUserIdFromToken(request);

  try {
    const currentDate = new Date();
    const [upcomingGames, pastGames] = await Promise.all([
      prisma.game.findMany({
        where: { dateTime: { gte: currentDate } },
        include: {
          host: { select: { id: true, name: true } },
          attendees: {
            include: { user: { select: { id: true, name: true } } },
          },
        },
        orderBy: { dateTime: "asc" },
      }),
      prisma.game.findMany({
        where: { dateTime: { lt: currentDate } },
        include: {
          host: { select: { id: true, name: true } },
        },
        orderBy: { dateTime: "desc" },
      }),
    ]);

    const formattedUpcomingGames = upcomingGames.map((game) => ({
      ...game,
      isHost: game.host.id === userId,
      isAttending: game.attendees.some(
        (attendee) => attendee.user.id === userId
      ),
      attendees: game.attendees.map((attendee) => ({
        id: attendee.id,
        name: attendee.user.name,
        waitlist: attendee.waitlist,
      })),
    }));

    return NextResponse.json({
      upcomingGames: formattedUpcomingGames,
      pastGames,
    });
  } catch (error) {
    console.error("Error fetching games:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  const { dateTime, maxPlayers, address } = await request.json();
  const userId = await getUserIdFromToken(request);

  if (!userId) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  try {
    const game = await prisma.game.create({
      data: {
        hostId: userId,
        dateTime: new Date(dateTime),
        maxPlayers,
        address,
      },
    });

    return NextResponse.json(game, { status: 201 });
  } catch (error) {
    console.error("Error creating game:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
