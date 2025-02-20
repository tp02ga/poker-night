import { GET } from "./route";
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
      create: jest.fn(),
      delete: jest.fn(),
      findFirst: jest.fn(),
      update: jest.fn(),
    },
  },
}));

const mockPrisma = jest.requireMock("@/lib/prisma").default;

describe("Game Detail API", () => {
  const mockParams = { id: "1" };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe("GET /api/games/[id]", () => {
    it("should return game details successfully", async () => {
      const mockGame = {
        id: 1,
        dateTime: new Date("2024-12-31T20:00:00Z"),
        maxPlayers: 8,
        address: "123 Poker St",
        attendees: [
          {
            id: 1,
            user: {
              name: "Player 1",
              email: "player1@example.com",
            },
          },
        ],
        host: {
          name: "Host Name",
        },
      };

      mockPrisma.game.findUnique.mockResolvedValue(mockGame);

      const request = new NextRequest("http://localhost/api/games/1");
      const response = await GET(request, { params: mockParams });
      const data = await response.json();

      expect(response.status).toBe(200);
      expect(data).toEqual({
        ...mockGame,
        dateTime: mockGame.dateTime.toISOString(),
      });
    });

    it("should return 404 if game not found", async () => {
      mockPrisma.game.findUnique.mockResolvedValue(null);

      const request = new NextRequest("http://localhost/api/games/999");
      const response = await GET(request, { params: { id: "999" } });
      const data = await response.json();

      expect(response.status).toBe(404);
      expect(data.error).toBe("Game not found");
    });
  });
});
