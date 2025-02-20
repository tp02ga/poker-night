import { GET, POST } from "./route";
import { NextRequest } from "next/server";
import { getUserIdFromToken } from "@/lib/auth";

// Mock dependencies
jest.mock("@/lib/auth", () => ({
  getUserIdFromToken: jest.fn(),
}));

// Mock Prisma
jest.mock("@/lib/prisma", () => ({
  __esModule: true,
  default: {
    game: {
      findMany: jest.fn(),
      create: jest.fn(),
    },
  },
}));

const mockPrisma = jest.requireMock("@/lib/prisma").default;

describe("Games API", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe("GET /api/games", () => {
    it("should return formatted upcoming and past games", async () => {
      const currentDate = new Date();
      const mockUserId = 1;
      const mockUpcomingGames = [
        {
          id: 1,
          dateTime: new Date(currentDate.getTime() + 86400000),
          maxPlayers: 8,
          address: "123 Poker St",
          host: { id: 1, name: "Host 1" },
          attendees: [
            { id: 1, user: { id: 1, name: "Player 1" }, waitlist: false },
          ],
        },
      ];

      const mockPastGames = [
        {
          id: 2,
          dateTime: new Date(currentDate.getTime() - 86400000),
          maxPlayers: 8,
          address: "456 Poker Ave",
          host: { id: 1, name: "Host 1" },
        },
      ];

      (getUserIdFromToken as jest.Mock).mockResolvedValue(mockUserId);
      mockPrisma.game.findMany
        .mockResolvedValueOnce(mockUpcomingGames)
        .mockResolvedValueOnce(mockPastGames);

      const request = new NextRequest("http://localhost/api/games");
      const response = await GET(request);
      const data = await response.json();

      expect(response.status).toBe(200);
      expect(data.upcomingGames[0]).toEqual({
        ...mockUpcomingGames[0],
        dateTime: mockUpcomingGames[0].dateTime.toISOString(),
        isHost: true,
        isAttending: true,
        attendees: [
          {
            id: 1,
            name: "Player 1",
            waitlist: false,
          },
        ],
      });
      expect(data.pastGames[0]).toEqual({
        ...mockPastGames[0],
        dateTime: mockPastGames[0].dateTime.toISOString(),
      });
    });

    it("should return 500 on internal server error", async () => {
      (getUserIdFromToken as jest.Mock).mockResolvedValue(1);
      mockPrisma.game.findMany.mockRejectedValue(new Error("Database error"));

      const request = new NextRequest("http://localhost/api/games");
      const response = await GET(request);
      const data = await response.json();

      expect(response.status).toBe(500);
      expect(data.error).toBe("Internal server error");
    });
  });

  describe("POST /api/games", () => {
    it("should create a new game successfully", async () => {
      const mockUserId = 1;
      const mockDate = new Date("2024-12-31T20:00:00Z");
      const mockGame = {
        id: 1,
        hostId: mockUserId,
        dateTime: mockDate,
        maxPlayers: 8,
        address: "123 Poker St",
      };

      (getUserIdFromToken as jest.Mock).mockResolvedValue(mockUserId);
      mockPrisma.game.create.mockResolvedValue(mockGame);

      const request = new NextRequest("http://localhost/api/games", {
        method: "POST",
        body: JSON.stringify({
          dateTime: "2024-12-31T20:00:00Z",
          maxPlayers: 8,
          address: "123 Poker St",
        }),
      });

      const response = await POST(request);
      const data = await response.json();

      expect(response.status).toBe(201);
      expect(data).toEqual({
        ...mockGame,
        dateTime: mockGame.dateTime.toISOString(),
      });
      expect(mockPrisma.game.create).toHaveBeenCalledWith({
        data: {
          hostId: mockUserId,
          dateTime: mockDate,
          maxPlayers: 8,
          address: "123 Poker St",
        },
      });
    });

    it("should return 401 if user is not authenticated", async () => {
      (getUserIdFromToken as jest.Mock).mockResolvedValue(null);

      const request = new NextRequest("http://localhost/api/games", {
        method: "POST",
        body: JSON.stringify({
          dateTime: "2024-12-31T20:00:00Z",
          maxPlayers: 8,
          address: "123 Poker St",
        }),
      });

      const response = await POST(request);
      const data = await response.json();

      expect(response.status).toBe(401);
      expect(data.error).toBe("Unauthorized");
      expect(mockPrisma.game.create).not.toHaveBeenCalled();
    });

    it("should return 500 on internal server error", async () => {
      (getUserIdFromToken as jest.Mock).mockResolvedValue(1);
      mockPrisma.game.create.mockRejectedValue(new Error("Database error"));

      const request = new NextRequest("http://localhost/api/games", {
        method: "POST",
        body: JSON.stringify({
          dateTime: "2024-12-31T20:00:00Z",
          maxPlayers: 8,
          address: "123 Poker St",
        }),
      });

      const response = await POST(request);
      const data = await response.json();

      expect(response.status).toBe(500);
      expect(data.error).toBe("Internal server error");
    });
  });
});
