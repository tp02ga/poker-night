import { POST } from "./route";
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
    },
  },
}));

// Mock process.env
process.env.JWT_SECRET = "test-secret";

// Get the mocked prisma instance
const mockPrisma = jest.requireMock("@/lib/prisma").default;

describe("POST /api/auth/login", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("should successfully login a user with valid credentials", async () => {
    // Mock implementations
    const mockUser = {
      id: 1,
      email: "test@example.com",
      password: "hashed_password",
      name: "Test User",
    };
    const mockToken = "mock_token";

    mockPrisma.user.findUnique.mockResolvedValue(mockUser);
    (bcrypt.compare as jest.Mock).mockResolvedValue(true);
    (jwt.sign as jest.Mock).mockReturnValue(mockToken);

    const request = new Request("http://localhost/api/auth/login", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        email: "test@example.com",
        password: "correct_password",
      }),
    });

    const response = await POST(request);
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.message).toBe("Login successful");
    expect(bcrypt.compare).toHaveBeenCalledWith(
      "correct_password",
      "hashed_password"
    );
    expect(jwt.sign).toHaveBeenCalledWith(
      { userId: mockUser.id },
      "test-secret",
      { expiresIn: "1d" }
    );
  });

  it("should return 401 if user does not exist", async () => {
    mockPrisma.user.findUnique.mockResolvedValue(null);

    const request = new Request("http://localhost/api/auth/login", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        email: "nonexistent@example.com",
        password: "password123",
      }),
    });

    const response = await POST(request);
    const data = await response.json();

    expect(response.status).toBe(401);
    expect(data.error).toBe("Invalid credentials");
    expect(bcrypt.compare).not.toHaveBeenCalled();
  });

  it("should return 401 if password is incorrect", async () => {
    const mockUser = {
      id: 1,
      email: "test@example.com",
      password: "hashed_password",
      name: "Test User",
    };

    mockPrisma.user.findUnique.mockResolvedValue(mockUser);
    (bcrypt.compare as jest.Mock).mockResolvedValue(false);

    const request = new Request("http://localhost/api/auth/login", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        email: "test@example.com",
        password: "wrong_password",
      }),
    });

    const response = await POST(request);
    const data = await response.json();

    expect(response.status).toBe(401);
    expect(data.error).toBe("Invalid credentials");
    expect(jwt.sign).not.toHaveBeenCalled();
  });

  it("should return 500 on internal server error", async () => {
    mockPrisma.user.findUnique.mockRejectedValue(new Error("Database error"));

    const request = new Request("http://localhost/api/auth/login", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        email: "test@example.com",
        password: "password123",
      }),
    });

    const response = await POST(request);
    const data = await response.json();

    expect(response.status).toBe(500);
    expect(data.error).toBe("Internal server error");
  });

  it("should return 400 if required fields are missing", async () => {
    const testCases = [
      { email: "test@example.com" }, // missing password
      { password: "password123" }, // missing email
      {}, // missing both
    ];

    for (const testCase of testCases) {
      const request = new Request("http://localhost/api/auth/login", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(testCase),
      });

      const response = await POST(request);
      const data = await response.json();

      expect(response.status).toBe(400);
      expect(data.error).toBe("Missing required fields");
      expect(mockPrisma.user.findUnique).not.toHaveBeenCalled();
    }
  });
});
