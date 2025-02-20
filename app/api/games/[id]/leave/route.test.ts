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
    attendee: {
      delete: jest.fn(),
      findFirst: jest.fn(),
      update: jest.fn(),
    },
  },
}));

const mockPrisma = jest.requireMock("@/lib/prisma").default;

describe("POST /api/games/[id]/leave", () => {
  const mockParams = { id: "1" };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("should successfully leave game and promote waitlisted player", async () => {
    const mockUserId = 1;
    const mockWaitlistedAttendee = {
      id: 2,
      gameId: 1,
      userId: 2,
      waitlist: true,
      signedUpAt: new Date(),
    };

    (getUserIdFromToken as jest.Mock).mockResolvedValue(mockUserId);
    mockPrisma.attendee.findFirst.mockResolvedValue(mockWaitlistedAttendee);

    const request = new NextRequest("http://localhost/api/games/1/leave");
    const response = await POST(request, { params: mockParams });
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.message).toBe("Successfully left game");
    expect(mockPrisma.attendee.delete).toHaveBeenCalledWith({
      where: {
        gameId_userId: {
          gameId: 1,
          userId: mockUserId,
        },
      },
    });
    expect(mockPrisma.attendee.update).toHaveBeenCalledWith({
      where: { id: mockWaitlistedAttendee.id },
      data: { waitlist: false },
    });
  });

  it("should successfully leave game with no waitlisted players", async () => {
    const mockUserId = 1;

    (getUserIdFromToken as jest.Mock).mockResolvedValue(mockUserId);
    mockPrisma.attendee.findFirst.mockResolvedValue(null);

    const request = new NextRequest("http://localhost/api/games/1/leave");
    const response = await POST(request, { params: mockParams });
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.message).toBe("Successfully left game");
    expect(mockPrisma.attendee.delete).toHaveBeenCalledWith({
      where: {
        gameId_userId: {
          gameId: 1,
          userId: mockUserId,
        },
      },
    });
    expect(mockPrisma.attendee.update).not.toHaveBeenCalled();
  });

  it("should return 401 if user is not authenticated", async () => {
    (getUserIdFromToken as jest.Mock).mockResolvedValue(null);

    const request = new NextRequest("http://localhost/api/games/1/leave");
    const response = await POST(request, { params: mockParams });
    const data = await response.json();

    expect(response.status).toBe(401);
    expect(data.error).toBe("Unauthorized");
    expect(mockPrisma.attendee.delete).not.toHaveBeenCalled();
  });

  it("should return 500 on database error", async () => {
    const mockUserId = 1;
    (getUserIdFromToken as jest.Mock).mockResolvedValue(mockUserId);
    mockPrisma.attendee.delete.mockRejectedValue(new Error("Database error"));

    const request = new NextRequest("http://localhost/api/games/1/leave");
    const response = await POST(request, { params: mockParams });
    const data = await response.json();

    expect(response.status).toBe(500);
    expect(data.error).toBe("Internal server error");
  });
});
