"use client";

import Link from "next/link";
import { LogoutButton } from "@/components/logout-button";
import { useAppSelector } from "@/redux/hooks";
import { selectIsLoggedIn } from "@/redux/features/userSlice";

export function Navbar() {
  // Get login state from Redux
  const isLoggedIn = useAppSelector(selectIsLoggedIn);

  return (
    <nav className="bg-gray-900 p-4 shadow-md">
      <div className="container mx-auto flex justify-between items-center">
        <Link href="/" className="text-2xl font-bold text-yellow-400">
          P<span className="text-red-500">♥</span>ker Night
        </Link>
        <div className="flex items-center gap-8">
          {isLoggedIn ? (
            <>
              <Link
                href="/games"
                className="text-white hover:text-yellow-400 transition-colors"
              >
                Games
              </Link>
              <LogoutButton />
            </>
          ) : (
            <Link
              href="/login"
              className="text-white hover:text-yellow-400 transition-colors"
            >
              Login
            </Link>
          )}
        </div>
      </div>
    </nav>
  );
}
