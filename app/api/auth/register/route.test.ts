import { POST } from "./route";
import { NextResponse } from "next/server";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";

// Mock dependencies
jest.mock("bcrypt");
jest.mock("jsonwebtoken");
jest.mock("@/lib/prisma", () => ({
  __esModule: true,
  default: {
    user: {
      findUnique: jest.fn(),
      create: jest.fn(),
    },
  },
}));

// Mock process.env
process.env.JWT_SECRET = "test-secret";

// Get the mocked prisma instance
const mockPrisma = jest.requireMock("@/lib/prisma").default;

describe("POST /api/auth/register", () => {
  beforeEach(() => {
    // Clear all mocks before each test
    jest.clearAllMocks();
  });

  it("should successfully register a new user", async () => {
    // Mock implementations
    const mockHashedPassword = "hashed_password";
    const mockToken = "mock_token";
    const mockUser = {
      id: 1,
      email: "test@example.com",
      name: "Test User",
      password: mockHashedPassword,
    };

    mockPrisma.user.findUnique.mockResolvedValue(null);
    mockPrisma.user.create.mockResolvedValue(mockUser);
    (bcrypt.hash as jest.Mock).mockResolvedValue(mockHashedPassword);
    (jwt.sign as jest.Mock).mockReturnValue(mockToken);

    const request = new Request("http://localhost/api/auth/register", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        email: "test@example.com",
        password: "password123",
        name: "Test User",
      }),
    });

    const response = await POST(request);
    const data = await response.json();

    expect(response.status).toBe(201);
    expect(data.message).toBe("User created successfully");
    expect(mockPrisma.user.create).toHaveBeenCalledWith({
      data: {
        email: "test@example.com",
        password: mockHashedPassword,
        name: "Test User",
      },
    });
  });

  it("should return 400 if user already exists", async () => {
    mockPrisma.user.findUnique.mockResolvedValue({
      id: 1,
      email: "existing@example.com",
      name: "Existing User",
      password: "hashed_password",
    });

    const request = new Request("http://localhost/api/auth/register", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        email: "existing@example.com",
        password: "password123",
        name: "Test User",
      }),
    });

    const response = await POST(request);
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(data.error).toBe("User already exists");
    expect(mockPrisma.user.create).not.toHaveBeenCalled();
  });

  it("should return 500 on internal server error", async () => {
    mockPrisma.user.findUnique.mockRejectedValue(new Error("Database error"));

    const request = new Request("http://localhost/api/auth/register", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        email: "test@example.com",
        password: "password123",
        name: "Test User",
      }),
    });

    const response = await POST(request);
    const data = await response.json();

    expect(response.status).toBe(500);
    expect(data.error).toBe("Internal server error");
  });

  it("should validate required fields", async () => {
    const request = new Request("http://localhost/api/auth/register", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        // Missing required fields
      }),
    });

    const response = await POST(request);
    const data = await response.json();

    expect(response.status).toBe(400);
    expect(mockPrisma.user.create).not.toHaveBeenCalled();
  });
});
