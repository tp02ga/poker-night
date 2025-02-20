import { POST } from "./route";
import { cookies } from "next/headers";

// Mock next/headers
jest.mock("next/headers", () => ({
  cookies: jest.fn(() => ({
    delete: jest.fn(),
  })),
}));

describe("POST /api/auth/logout", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("should successfully logout user and delete token cookie", async () => {
    const mockCookieStore = {
      delete: jest.fn(),
    };
    (cookies as jest.Mock).mockReturnValue(mockCookieStore);

    const response = await POST();
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(mockCookieStore.delete).toHaveBeenCalledWith("token");
    expect(mockCookieStore.delete).toHaveBeenCalledTimes(1);
  });
});
