import { POST } from "./route";
import { NextRequest } from "next/server";
import { getUserIdFromToken } from "@/lib/auth";

// Mock dependencies
jest.mock("@/lib/auth", () => ({
  getUserIdFromToken: jest.fn(),
}));

jest.mock("@/lib/prisma", () => ({
  __esModule: true,
  default: {
    game: {
      findUnique: jest.fn(),
    },
    attendee: {
      findFirst: jest.fn(),
      create: jest.fn(),
    },
  },
}));

const mockPrisma = jest.requireMock("@/lib/prisma").default;

describe("POST /api/games/[id]/join", () => {
  const mockParams = { id: "1" };

  beforeEach(() => {
    jest.clearAllMocks();
    // Reset Date.now to its original value after each test
    jest.useRealTimers();
  });

  it("should successfully join a game with available spots", async () => {
    const mockUserId = 1;
    const gameDateTime = new Date();
    gameDateTime.setHours(gameDateTime.getHours() + 1); // Game starts in 1 hour

    const mockGame = {
      id: 1,
      dateTime: gameDateTime,
      maxPlayers: 8,
      attendees: Array(5).fill({}),
    };

    const mockAttendee = {
      id: 1,
      gameId: 1,
      userId: mockUserId,
      waitlist: false,
    };

    (getUserIdFromToken as jest.Mock).mockResolvedValue(mockUserId);
    mockPrisma.game.findUnique.mockResolvedValue(mockGame);
    mockPrisma.attendee.findFirst.mockResolvedValue(null);
    mockPrisma.attendee.create.mockResolvedValue(mockAttendee);

    const request = new NextRequest("http://localhost/api/games/1/join");
    const response = await POST(request, { params: mockParams });
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.message).toBe("Successfully joined game");
    expect(data.attendee).toEqual(mockAttendee);
  });

  it("should add to waitlist when game is full", async () => {
    const mockUserId = 1;
    const gameDateTime = new Date();
    gameDateTime.setHours(gameDateTime.getHours() + 1);

    const mockGame = {
      id: 1,
      dateTime: gameDateTime,
      maxPlayers: 8,
      attendees: Array(8).fill({}),
    };

    const mockAttendee = {
      id: 1,
      gameId: 1,
      userId: mockUserId,
      waitlist: true,
    };

    (getUserIdFromToken as jest.Mock).mockResolvedValue(mockUserId);
    mockPrisma.game.findUnique.mockResolvedValue(mockGame);
    mockPrisma.attendee.findFirst.mockResolvedValue(null);
    mockPrisma.attendee.create.mockResolvedValue(mockAttendee);

    const request = new NextRequest("http://localhost/api/games/1/join");
    const response = await POST(request, { params: mockParams });
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.message).toBe("Added to waitlist");
    expect(data.attendee.waitlist).toBe(true);
  });

  it("should prevent joining if game starts in less than 5 minutes", async () => {
    const mockUserId = 1;
    const gameDateTime = new Date();
    gameDateTime.setMinutes(gameDateTime.getMinutes() + 3); // Game starts in 3 minutes

    const mockGame = {
      id: 1,
      dateTime: gameDateTime,
      maxPlayers: 8,
      attendees: [],
    };

    (getUserIdFromToken as jest.Mock).mockResolvedValue(mockUserId);
    mockPrisma.game.findUnique.mockResolvedValue(mockGame);

    const request = new NextRequest("http://localhost/api/games/1/join");
    const response = await POST(request, { params: mockParams });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toBe(
      "Cannot join game less than 5 minutes before start"
    );
    expect(mockPrisma.attendee.create).not.toHaveBeenCalled();
  });

  it("should prevent joining if already registered", async () => {
    const mockUserId = 1;
    const gameDateTime = new Date();
    gameDateTime.setHours(gameDateTime.getHours() + 1);

    const mockGame = {
      id: 1,
      dateTime: gameDateTime,
      maxPlayers: 8,
      attendees: [],
    };

    const existingAttendee = {
      id: 1,
      gameId: 1,
      userId: mockUserId,
      waitlist: false,
    };

    (getUserIdFromToken as jest.Mock).mockResolvedValue(mockUserId);
    mockPrisma.game.findUnique.mockResolvedValue(mockGame);
    mockPrisma.attendee.findFirst.mockResolvedValue(existingAttendee);

    const request = new NextRequest("http://localhost/api/games/1/join");
    const response = await POST(request, { params: mockParams });
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toBe("Already registered for this game");
    expect(mockPrisma.attendee.create).not.toHaveBeenCalled();
  });

  it("should return 401 if user is not authenticated", async () => {
    (getUserIdFromToken as jest.Mock).mockResolvedValue(null);

    const request = new NextRequest("http://localhost/api/games/1/join");
    const response = await POST(request, { params: mockParams });
    const data = await response.json();

    expect(response.status).toBe(401);
    expect(data.error).toBe("Unauthorized");
    expect(mockPrisma.game.findUnique).not.toHaveBeenCalled();
  });

  it("should return 404 if game not found", async () => {
    const mockUserId = 1;
    (getUserIdFromToken as jest.Mock).mockResolvedValue(mockUserId);
    mockPrisma.game.findUnique.mockResolvedValue(null);

    const request = new NextRequest("http://localhost/api/games/1/join");
    const response = await POST(request, { params: mockParams });
    const data = await response.json();

    expect(response.status).toBe(404);
    expect(data.error).toBe("Game not found");
    expect(mockPrisma.attendee.create).not.toHaveBeenCalled();
  });

  it("should return 500 on database error", async () => {
    const mockUserId = 1;
    (getUserIdFromToken as jest.Mock).mockResolvedValue(mockUserId);
    mockPrisma.game.findUnique.mockRejectedValue(new Error("Database error"));

    const request = new NextRequest("http://localhost/api/games/1/join");
    const response = await POST(request, { params: mockParams });
    const data = await response.json();

    expect(response.status).toBe(500);
    expect(data.error).toBe("Internal server error");
  });
});
